;;; my-gptel.el --- Personal gptel configuration -*- lexical-binding: t; -*-

;; All gptel related configuration: gptel core, gptel-agent, MCP,
;; chat-file modes, tool-block hiding, session summarisation and the
;; commit-message helper.
;;
;; Loaded from .emacs via (require 'my-gptel).  The file lives in
;; ~/.emacs.d/lisp which is already on `load-path'.

;;; Code:

;; LLM done right
(use-package gptel
    :ensure t
    :bind (:map global-map
                ("C-c C-g" . gptel))
    ;; Always start gptel-mode for my chats
    :bind (:map gptel-mode-map
                ("C-c C-t" . ghostel-new)
                ("C-c C-o" . gptel-menu)
                ("C-c C-c" . gptel-send))
    :config
    ;; OpenAI
    (gptel-make-openai-oauth "OpenAI-sub")

    ;; Mistral offers an OpenAI compatible API
    (gptel-make-openai "MistralLeChat"  ;Any name you want
      :host "api.mistral.ai"
      :endpoint "/v1/chat/completions"
      :protocol "https"
      :key (auth-source-pick-first-password :host "api.mistral.ai" :user "apikey")
      :models '("mistral-small"))

    ;; Llama.cpp offers an OpenAI compatible API
    (gptel-make-openai "llama-cpp"  ; Any name
      :stream t                     ; Stream responses
      :protocol "http"
      :host "localhost:8080"        ; Llama.cpp server location
      :models '(current))           ; Any names, doesn't matter for Llama

    ;; Copilot - default backend
    (gptel-make-gh-copilot "Copilot" :stream t)

    (setq gptel-use-curl t)

    ;; Turn off tool confirmation by default
    (setq gptel-confirm-tool-calls nil)

    ;; Auto-scroll while streaming, and land point on the next `### '
    ;; prompt line when the response is done. Works for every window
    ;; that shows the gptel buffer, even when that buffer isn't in
    ;; focus (so I can keep working in another buffer while waiting).    
    (defun my-gptel-auto-scroll ()
      "Gently keep point visible in all windows showing the current buffer.
Replacement for `gptel-auto-scroll' that does not jump a whole
page and that works even if the gptel buffer is not focused."
      (let ((buf (current-buffer))
            (pt  (point)))
        (dolist (win (get-buffer-window-list buf nil t))
          (set-window-point win pt)
          (unless (pos-visible-in-window-p pt win)
            (with-selected-window win
              (save-excursion
                (goto-char pt)
                (recenter -1)))))))

    (defun my-gptel-goto-next-prompt (_beg _end)
      "Place point right after the trailing `### ' prompt prefix.
Updates point in the buffer and in every window showing it, so
it works even when the gptel buffer is not the selected window."
      (let* ((buf    (current-buffer))
             (prefix (gptel-prompt-prefix-string))
             (target (save-excursion
                       (goto-char (point-max))
                       (if (and prefix
                                (not (string-empty-p prefix))
                                (re-search-backward
                                 (concat "^"
                                         (regexp-quote (string-trim-right prefix))
                                         " ?")
                                 nil t))
                           (match-end 0)
                         (point-max)))))
        (goto-char target)
        (dolist (win (get-buffer-window-list buf nil t))
          (set-window-point win target)
          (with-selected-window win
            (save-excursion
              (goto-char target)
              (recenter -3))))))

    (remove-hook 'gptel-post-stream-hook       #'gptel-auto-scroll)
    (add-hook    'gptel-post-stream-hook       #'my-gptel-auto-scroll)
    (add-hook    'gptel-post-response-functions #'my-gptel-goto-next-prompt)
    )

;; As a agent gptel gets a bunch of tools to work as a code assistant
(use-package gptel-agent
    :bind (:map global-map
                ("C-c C-a" . gptel-agent))
    :bind (:map gptel-mode-map
                ("C-c C-a" . gptel-agent))
    :ensure t
    :demand t ; load directly to get access to tools
    :config
    (setf (alist-get 'programming gptel-directives)
          "You are a large language model and a careful programmer.
 Provide code and only code as output without any additional text,
 prompt or note. Read and follow the instructions in AGENTS.md in
 the project root before proceeding.")

    ;; Keep gptel's agent/skill awareness current with the working
    ;; directory.  Skills are resolved relative to `default-directory'
    ;; and the project root, so `M-x cd' can change which skills are in
    ;; scope; `gptel-agent-update' rescans both agents and skills (and
    ;; rebuilds the `Agent' tool enum and gptel-agent/gptel-plan
    ;; presets).
    (defun my-gptel-agent-refresh-on-cd (&rest _)
      "Rescan gptel agents and skills after `cd' changes the directory."
      (when (fboundp 'gptel-agent-update)
        (condition-case err
            (progn
              (gptel-agent-update)
              (when (eq this-command 'cd)
                (message "gptel-agent: %d agents, %d skills for %s"
                         (length gptel-agent--agents)
                         (length gptel-agent--skills)
                         (abbreviate-file-name default-directory))))
          (error (message "gptel-agent refresh failed: %s"
                          (error-message-string err))))))

    (advice-add 'cd :after #'my-gptel-agent-refresh-on-cd)
    )

;; mcp requirement
(require 'gptel-integrations)

;; Will popup a login window in your browser
(use-package mcp
  :ensure t
  :config
  (setq mcp-hub-servers
        '(("jira" .
           (:command "npx"
            :args ("-y" "mcp-remote@latest" "https://mcp.atlassian.com/v1/mcp"
                        "--resource" "https://sedona.atlassian.net/")
            ))))
  )

;; Make sure the chat/gptel files have gptel-mode on them
(add-to-list 'auto-mode-alist '("\\.\\(gptel\\|chat\\)\\'" . markdown-mode))
(add-hook 'markdown-mode-hook
          (lambda ()
            (when (and buffer-file-name
                       (string-match-p "\\.\\(gptel\\|chat\\)\\'"
                                       buffer-file-name))
              (gptel-mode 1))))

;; Never let a saved response token limit govern a re-opened session.
;;
;; `gptel-agent' sets `gptel-max-tokens' buffer-locally (8192), and
;; `gptel--save-state' persists that as a file-local variable in the
;; .gptel file.  On re-open the cap is restored and can silently
;; truncate responses.  Clearing the buffer-local value on `gptel-mode'
;; entry makes the cap a runtime setting again (global default or the
;; per-session menu), and because the value becomes nil the next save
;; will `delete-file-local-variable' it -- so existing files self-heal.
;;
;; NOTE: We deliberately do NOT strip the whole Local Variables block.
;; gptel updates that block in place (it does not accumulate), and it
;; carries useful restore data (gptel--bounds, model, backend, tools).
(defun my-gptel-reset-max-tokens ()
  "Drop any buffer-local `gptel-max-tokens' restored from a chat file."
  (when (and buffer-file-name
             (string-match-p "\\.\\(gptel\\|chat\\)\\'" buffer-file-name))
    (kill-local-variable 'gptel-max-tokens)))

(add-hook 'gptel-mode-hook #'my-gptel-reset-max-tokens)

;; Hides all tool blocks
(defun gptel-hide-all-tools ()
  "Hide all tool sections in current gptel buffer, only if not already hidden."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^``` tool" nil t)
      (goto-char (line-beginning-position))
      (let ((already-hidden
             (save-excursion
               (forward-line 1)
               (eq (get-char-property (point) 'invisible) t))))
        (unless already-hidden
          (gptel-markdown-cycle-block)))
      (forward-line 1))))

;; Make sure when loading old gptel session that all tool blocks are closed.
;; Use find-file-hook so we know the buffer content is fully loaded (no timer).
(defun my-gptel-hide-tools-on-find-file ()
  (when (and buffer-file-name
             (string-match-p "\\.gptel\\'" buffer-file-name)
             (bound-and-true-p gptel-mode))
    (gptel-hide-all-tools)))
(add-hook 'find-file-hook #'my-gptel-hide-tools-on-find-file)

(defun gptel-summarize-to-new-session ()
  "Summarize the current gptel session and start a new one with the summary."
  (interactive)
  (unless (bound-and-true-p gptel-mode)
    (user-error "Not a gptel buffer"))
  (let ((src-buf  (current-buffer))
        (backend  gptel-backend)
        (model    gptel-model)
        (sysmsg   gptel--system-message))
    (message "Summarizing gptel session...")
    (let* ((gptel-use-tools nil)
           (gptel-tools nil)
           (convo (with-current-buffer src-buf
                    (buffer-substring-no-properties (point-min) (point-max))))
           (question
            (concat
             "Below is a transcript of a previous chat session "
             "between a user and an assistant. Produce a concise but "
             "complete summary in English that can be used as starting "
             "context for a new session. Include: (1) the user's goal "
             "and task, (2) key facts and decisions, (3) code/artifacts "
             "produced (brief reference, not full contents), (4) open "
             "questions and next steps. Output only the summary, no "
             "meta-text.\n\n=== TRANSCRIPT START ===\n"
             convo
             "\n=== TRANSCRIPT END ===")))
      (gptel-request
       question
       :system "You are a helpful assistant that summarizes chat sessions."
       :context (list src-buf backend model sysmsg)
       :callback
       (lambda (response info)
         (let* ((ctx (plist-get info :context))
                (orig-buf (nth 0 ctx)))
           (if (or (not (stringp response)) (string-empty-p response))
               (message "Summarization failed:
 response=%S status=%S error=%S http=%S"
                        response
                        (plist-get info :status)
                        (plist-get info :error)
                        (plist-get info :http-status))
             (let* ((gptel-backend (nth 1 ctx))
                    (gptel-model   (nth 2 ctx))
                    (orig-sysmsg   (nth 3 ctx))
                    (name (generate-new-buffer-name
                           (format "*%s-continued*" (buffer-name orig-buf))))
                    (new-buf (gptel name nil nil t)))
               (with-current-buffer new-buf
                 (setq-local gptel--system-message orig-sysmsg)
                 (goto-char (point-max))
                 (insert (or (gptel-response-prefix-string) "")
                         "Summary of previous session:\n\n"
                         response
                         "\n\n"
                         (or (gptel-prompt-prefix-string) "")))
               (pop-to-buffer new-buf)
               (message "New session: %s" name)))))))))

;; Nice feature to create commit messages
(defvar my-gptel-commit-prompt
  "You are an expert at writing Git commit messages.
Generate ONLY the commit message, plain text, no markdown, no code fences.
Subject line ≤50 chars, imperative mood, no trailing period.
If body is needed: blank line, then wrap at 72 chars."
  "System prompt for `gptel-commit'.")

(defun gptel-commit ()
  "Generate a commit message for staged changes using gptel."
  (interactive)
  (let ((diff (shell-command-to-string "git diff --cached")))
    (when (string-empty-p (string-trim diff))
      (user-error "No staged changes"))
    (gptel-request diff
      :system my-gptel-commit-prompt
      :buffer (current-buffer)
      :position (point)
      :stream t)))

(provide 'my-gptel)
;;; my-gptel.el ends here
