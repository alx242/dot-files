;;; gptel-tools.el --- File system tools for gptel -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Claude (via gptel)
;; Keywords: tools, gptel, filesystem

;;; Commentary:

;; This file provides filesystem tools for gptel to enable AI-assisted
;; file and directory operations.
;;
;; Usage:
;;   (require 'gptel-tools)
;;
;; Available tools:
;;   - create_file       : Create a new file
;;   - create_directory  : Create a directory
;;   - delete_file       : Delete a file
;;   - delete_directory  : Delete a directory (with recursive option)
;;   - read_file         : Read file contents
;;   - edit_file         : Edit/replace file content
;;   - append_to_file    : Append content to file
;;   - list_files        : List files in directory
;;   - move_file         : Move or rename a file

;;; Code:

(require 'gptel)

;; Create file tool
(gptel-make-tool
 :name "create_file"
 :function (lambda (path filename content)
             (let ((full-path (expand-file-name (concat path "/" filename))))
               (with-temp-buffer
                 (insert content)
                 (write-file full-path))
               (format "Created file %s in %s" filename path)))
 :description "Create a new file with the specified content"
 :args (list '(:name "path"
               :type string
               :description "The directory where to create the file")
             '(:name "filename"
               :type string
               :description "The name of the file to create")
             '(:name "content"
               :type string
               :description "The content to write to the file"))
 :category "filesystem")

;; Create directory tool
(gptel-make-tool
 :name "create_directory"
 :function (lambda (path)
             (make-directory (expand-file-name path) t)
             (format "Created directory: %s" path))
 :description "Create a directory (including parent directories if needed)"
 :args (list '(:name "path"
               :type string
               :description "The directory path to create (e.g. ~/myapp/src)"))
 :category "filesystem")

;; Delete file tool
(gptel-make-tool
 :name "delete_file"
 :function (lambda (path)
             (let ((full-path (expand-file-name path)))
               (if (file-exists-p full-path)
                   (progn
                     (delete-file full-path)
                     (format "Deleted file: %s" full-path))
                 (format "File does not exist: %s" full-path))))
 :description "Delete a file"
 :args (list '(:name "path"
               :type string
               :description "Path to file to delete"))
 :category "filesystem")

;; Delete directory tool
(gptel-make-tool
 :name "delete_directory"
 :function (lambda (path recursive)
             (let ((full-path (expand-file-name path)))
               (if (file-directory-p full-path)
                   (progn
                     (delete-directory full-path recursive)
                     (format "Deleted directory: %s%s" 
                             full-path 
                             (if recursive " (recursive)" "")))
                 (format "Directory does not exist: %s" full-path))))
 :description "Delete a directory (optionally recursive)"
 :args (list '(:name "path"
               :type string
               :description "Path to directory to delete")
             '(:name "recursive"
               :type boolean
               :description "Delete recursively (true/false)"))
 :category "filesystem")

;; Read file tool
(gptel-make-tool
 :name "read_file"
 :function (lambda (path)
             (let ((full-path (expand-file-name path)))
               (if (file-exists-p full-path)
                   (with-temp-buffer
                     (insert-file-contents full-path)
                     (buffer-string))
                 (format "File does not exist: %s" full-path))))
 :description "Read contents of a file"
 :args (list '(:name "path"
               :type string
               :description "Path to file to read"))
 :category "filesystem")

;; Edit file tool
(gptel-make-tool
 :name "edit_file"
 :function (lambda (path content)
             (let ((full-path (expand-file-name path)))
               (if (file-exists-p full-path)
                   (progn
                     (with-temp-file full-path
                       (insert content))
                     (format "Updated file: %s" full-path))
                 (format "File does not exist: %s" full-path))))
 :description "Edit/replace entire file content"
 :args (list '(:name "path"
               :type string
               :description "Path to file to edit")
             '(:name "content"
               :type string
               :description "New content for the file"))
 :category "filesystem")

;; Append to file tool
(gptel-make-tool
 :name "append_to_file"
 :function (lambda (path content)
             (let ((full-path (expand-file-name path)))
               (if (file-exists-p full-path)
                   (progn
                     (append-to-file content nil full-path)
                     (format "Appended to file: %s" full-path))
                 (format "File does not exist: %s" full-path))))
 :description "Append content to end of file"
 :args (list '(:name "path"
               :type string
               :description "Path to file")
             '(:name "content"
               :type string
               :description "Content to append"))
 :category "filesystem")

;; List files tool
(gptel-make-tool
 :name "list_files"
 :function (lambda (path)
             (let ((full-path (expand-file-name path)))
               (if (file-directory-p full-path)
                   (let ((files (directory-files full-path nil "^[^.]")))
                     (if files
                         (mapconcat 'identity files "\n")
                       "(empty directory)"))
                 (format "Directory does not exist: %s" full-path))))
 :description "List files in a directory (excludes hidden files)"
 :args (list '(:name "path"
               :type string
               :description "Directory path"))
 :category "filesystem")

;; Move/rename file tool
(gptel-make-tool
 :name "move_file"
 :function (lambda (from to)
             (let ((from-path (expand-file-name from))
                   (to-path (expand-file-name to)))
               (if (file-exists-p from-path)
                   (progn
                     (rename-file from-path to-path)
                     (format "Moved %s -> %s" from-path to-path))
                 (format "File does not exist: %s" from-path))))
 :description "Move or rename a file"
 :args (list '(:name "from"
               :type string
               :description "Source file path")
             '(:name "to"
               :type string
               :description "Destination file path"))
 :category "filesystem")

(provide 'gptel-tools)
;;; gptel-tools.el ends here
