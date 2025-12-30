;;; init-terminals.el --- Terminal emulators          -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(when (maybe-require-package 'eat)
  ;; Explicitly set the shell program for eat
  (setq eat-shell (or (getenv "SHELL") "/bin/zsh"))
  (setq eat-query-before-killing-running-terminal nil)

  (defun sanityinc/on-eat-exit (process)
    (when (zerop (process-exit-status process))
      (kill-buffer)
      (unless (eq (selected-window) (next-window))
        (delete-window))))
  (add-hook 'eat-exit-hook 'sanityinc/on-eat-exit)

  (with-eval-after-load 'eat
    (custom-set-variables
     `(eat-semi-char-non-bound-keys
       (quote ,(cons [?\e ?w] (cl-remove [?\e ?w] eat-semi-char-non-bound-keys :test 'equal))))))

  (defcustom sanityinc/eat-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "t") 'eat-other-window)
      map)
    "Prefix map for commands that create and manipulate eat buffers.")
  (fset 'sanityinc/eat-map sanityinc/eat-map)

  (setq-default eat-term-scrollback-size (* 2 1024 1024))

  (defun sanityinc/eat-term-get-suitable-term-name (&optional display)
    "Version of `eat-term-get-suitable-term-name' which uses better-known TERM values."
    (let ((colors (display-color-cells display)))
      (cond ((> colors 8) "xterm-256color")
            ((> colors 1) "xterm-color")
            (t "xterm"))))
  (setq eat-term-name 'sanityinc/eat-term-get-suitable-term-name)

  ;; Ensure eat properly handles wide characters and Unicode
  (with-eval-after-load 'eat
    ;; Enable UTF-8 encoding
    (setq eat-enable-yank-to-terminal t)
    ;; Keep a valid INSIDE_EMACS value for terminal programs
    (setq eat-term-inside-emacs (format "%s,eat" emacs-version)))

  (global-set-key (kbd "C-c t") 'sanityinc/eat-map))



(provide 'init-terminals)
;;; init-terminals.el ends here
