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
    ;; :bind (:map global-map
    ;;             ("C-x C-g" . gptel))
    ;; Always start gptel-mode for my chats
    :bind (:map gptel-mode-map
                ("C-c C-t" . ghostel-new)
                ("C-c C-o" . gptel-menu)
                ("C-c C-c" . gptel-send))
    :config
    ;; markdown mode left a bunch of ugly meta-comments that did not collapse
    (setq gptel-default-mode 'org-mode)

    ;; OpenAI
    (setq gptel-backend
          (gptel-make-openai-oauth "Codex"
            :stream t
            ;; :request-params '(:reasoning (:effort "high"))
            ;; none, low, medium (the default), high, xhigh, and max
            :request-params '(:reasoning (:effort "xhigh"))
            :models '(gpt-5.6-sol
                      gpt-5.6-terra
                      gpt-5.6-luna
                      gpt-6-astra
                      gpt-6-sol
                      gpt-6-luna
                      ))
          )

    ;; Swedish AI provider
    (gptel-make-openai "BergetAI"
      :host "api.berget.ai"
      :endpoint "/v1/chat/completions"
      :key (auth-source-pick-first-password :host "api.berget.ai" :user "apikey")
      :stream t
      :models '(Qwen3.5-2B
                GLM-5.3-Flash
                Kimi-K3
                gemma-4-31B-it
                ))


    ;; Copilot
    (gptel-make-gh-copilot "Copilot" :stream t)

    ;; Pick the correct model for this emacs session once at startup
    (defun gptel-pick-model-once (&rest _)
      "Prompt for a gptel model the first time gptel is launched."
      (let* ((models (gptel-backend-models gptel-backend))
             (choice (completing-read
                      "Model: "
                      (mapcar (lambda (m) (format "%s" m)) models)
                      nil t)))
        (setq gptel-model (intern choice)))
      (advice-remove 'gptel #'gptel-pick-model-once))

    (advice-add 'gptel :before #'gptel-pick-model-once)

    (setq gptel-use-curl t)

    ;; Create Codex buffers clean from gptel-max-tokens warning
    (defun gptel-disable-max-tokens-for-codex (&rest _)
      (when (and (boundp 'gptel-backend)
                 (equal (gptel-backend-name gptel-backend) "Codex")
                 (local-variable-p 'gptel-max-tokens))
        (kill-local-variable 'gptel-max-tokens)))

    (advice-add 'gptel-send :before #'gptel-disable-max-tokens-for-codex)
    
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

;; Fix gptel-mode:s org-mode a bit
(defun my-gptel-fold-tool-blocks ()
  "Fold every #+begin_tool ... #+end_tool block in the buffer.
Leaves #+begin_src and #+begin_example blocks untouched."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^[ \t]*#\\+begin_tool\\b" nil t)
      (org-fold-hide-block-toggle 'hide))))

(add-hook 'gptel-mode-hook
          (lambda ()
            (gptel-highlight-mode 1)
            (when (derived-mode-p 'org-mode)
              (local-set-key (kbd "M-<up>") 'backward-paragraph)
              (local-set-key (kbd "M-<down>") 'forward-paragraph)
              (local-set-key (kbd "M-<left>") #'left-word)
              (local-set-key (kbd "M-<right>") #'right-word)
              (visual-line-mode 1)
              ;; `org-startup-folded' is `showeverything', which forces
              ;; drawers and blocks open. Re-hide the PROPERTIES drawer and
              ;; only the #+begin_tool ... #+end_tool blocks so that
              ;; #+begin_src/#+begin_example blocks stay visible.
              (org-fold-hide-drawer-all)
              (my-gptel-fold-tool-blocks))))

;; As a agent gptel gets a bunch of tools to work as a code assistant
(use-package gptel-agent
    :bind (:map global-map
                ("C-x C-a" . gptel-agent))
    :bind (:map gptel-mode-map
                ("C-x C-a" . gptel-agent))
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

  ;; Installed mcp-remote with `npm install -g mcp-remote`
  ;; Update with `npm update -g mcp-remote` when necessary
  ;; Re-auth can be done with:
  ;;
  ;; mcp-remote https://mcp.atlassian.com/v1/mcp --resource
  ;; https://sedona.atlassian.net/
  (setq mcp-hub-servers
      '(("jira" .
         (:command "mcp-remote"
          :args ("https://mcp.atlassian.com/v1/mcp"
                 "--resource" "https://sedona.atlassian.net/")))))
  )

;; Make sure the chat/gptel files have gptel-mode on them
(add-to-list 'auto-mode-alist '("\\.\\(gptel\\|chat\\)\\'" . org-mode))
(add-hook 'org-mode-hook
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

(advice-add 'gptel-get-tool :around
            (lambda (orig path) (ignore-errors (funcall orig path))))

(defcustom my-gptel-compaction-reasoning-effort "low"
  "Reasoning effort for Codex summary requests (does not affect chats)."
  :type '(choice (const "low") (const "medium") (const "high"))
  :group 'gptel)

(defun my-gptel--summary-request (text prompt backend model callback)
  "Ask gptel to summarize TEXT according to PROMPT, then call CALLBACK.
Use BACKEND and MODEL.  CALLBACK receives the complete (RESPONSE INFO)."
  (let ((gptel-backend (if (and (fboundp 'gptel-openai-oauth-p)
                                (gptel-openai-oauth-p backend))
                           (let* ((copy (copy-sequence backend))
                                  (params (copy-sequence
                                           (gptel-backend-request-params backend)))
                                  (reasoning (copy-sequence
                                              (plist-get params :reasoning))))
                             (setf (gptel-backend-request-params copy)
                                   (plist-put params :reasoning
                                              (plist-put reasoning :effort
                                                         my-gptel-compaction-reasoning-effort)))
                             copy)
                         backend))
        (gptel-model model)
        (gptel-use-tools nil)
        (gptel-tools nil)
        (gptel-use-context nil)
        (gptel-stream t)
        chunks)
    (gptel-request
     (concat prompt "\n\n=== INPUT START ===\n" text "\n=== INPUT END ===")
     :system "Summarize faithfully. Preserve concrete facts, identifiers, decisions, code changes, errors, and unfinished work. Output only the summary."
     :stream t
     :callback
     (lambda (response info)
       (cond
        ((stringp response)
         (if (plist-get info :stream)
             (push response chunks)
           (funcall callback response info)))
        ((eq response t)
         (let ((summary (string-trim (apply #'concat (nreverse chunks)))))
           (cond
            ((plist-get info :error) (funcall callback nil info))
            ((string-empty-p summary)
             (funcall callback nil (plist-put info :error "Empty summary response")))
            (t (funcall callback summary info)))))
        ((eq response 'abort)
         (funcall callback nil (plist-put info :error "Summary request aborted")))
        ((null response) (funcall callback nil info)))))))

(defcustom my-gptel-compaction-max-characters 40000
  "Maximum characters of older transcript to send for focused compaction.
Older text is sampled evenly when longer than this limit; compaction
is intentionally lossy."
  :type 'integer
  :group 'gptel)

(defcustom my-gptel-compaction-recent-characters 16000
  "Maximum characters to include from the end of the transcript."
  :type 'integer
  :group 'gptel)

(defcustom my-gptel-compaction-samples 4
  "Number of evenly spaced excerpts to take from older transcript."
  :type 'integer
  :group 'gptel)

(defun my-gptel--compaction-input (text)
  "Return bounded, chronological excerpts from session TEXT.
The older portion is sampled; the recent portion is included verbatim.
Return the input and a boolean indicating whether sampling occurred."
  (let* ((total (length text))
         (recent-limit (max 1 my-gptel-compaction-recent-characters))
         (old-limit (max 0 my-gptel-compaction-max-characters))
         (recent-start (max 0 (- total recent-limit)))
         (old-length recent-start)
         (recent (substring text recent-start))
         (count (max 1 my-gptel-compaction-samples))
         (excerpt-size (/ old-limit count))
         (sampling (> old-length old-limit))
         excerpts)
    (when (> old-length 0)
      (if (not sampling)
          (push (substring text 0 old-length) excerpts)
        (when (> excerpt-size 0)
          (dotimes (i count)
            (let* ((start (/ (* i (- old-length excerpt-size))
                             (max 1 (1- count))))
                   (end (+ start excerpt-size)))
              (push (format "--- Older excerpt %d/%d (characters %d-%d) ---\n%s"
                            (1+ i) count start end (substring text start end))
                    excerpts)))))
    (cons (concat (mapconcat #'identity (nreverse excerpts) "\n\n")
                  "\n\n--- Recent session (verbatim) ---\n" recent)
          sampling))))

(defun gptel-summarize-to-new-session ()
  "Make a fast, focused handoff to a new gptel session.
Include the most recent transcript verbatim and sample the older part;
this is intentionally lossy."
  (interactive)
  (unless (bound-and-true-p gptel-mode)
    (user-error "Not a gptel buffer"))
  (let* ((src-buf (current-buffer))
         (backend gptel-backend)
         (model gptel-model)
         (sysmsg gptel-system-prompt)
         (excerpt (my-gptel--compaction-input
                   (buffer-substring-no-properties (point-min) (point-max))))
         (input (car excerpt)))
    (when (cdr excerpt)
      (message "Sampling older history; the handoff may omit unsampled details"))
    (message "Preparing focused session handoff (%d characters)..." (length input))
    (my-gptel--summary-request
     input
     (concat "Create a concise handoff for continuing this chat in a NEW session. "
             "Prioritize the current goal, constraints, decisions, exact file paths "
             "and identifiers, changes made, verified results, errors, and next steps. "
             "Discard repeated explanations and verbose tool output. "
             "Older history may be sampled: do not claim complete coverage. "
             "Keep the handoff compact (ideally under 1200 words).")
     backend model
     (lambda (response info)
       (if (and (stringp response) (not (string-empty-p response)))
           (if (buffer-live-p src-buf)
               (let* ((gptel-backend backend)
                      (gptel-model model)
                      (name (generate-new-buffer-name
                             (format "*%s-continued*" (buffer-name src-buf))))
                      (new-buf (gptel name nil nil t)))
                 (with-current-buffer new-buf
                   (setq-local gptel-system-prompt sysmsg)
                   (goto-char (point-max))
                   (insert "Continuation context from the previous session:\n\n"
                           response "\n\n"
                           (or (gptel-prompt-prefix-string) "")))
                 (pop-to-buffer new-buf)
                 (message "New summarized session: %s" name))
             (message "Source session closed before summarization finished"))
         (display-warning
          'my-gptel
          (format "Session compaction failed: status=%S error=%S http=%S"
                  (plist-get info :status)
                  (plist-get info :error)
                  (plist-get info :http-status))
          :error))))))

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
