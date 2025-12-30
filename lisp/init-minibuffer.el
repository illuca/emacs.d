;;; init-minibuffer.el --- Config for minibuffer completion       -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


(when (maybe-require-package 'vertico)
  (add-hook 'after-init-hook 'vertico-mode)

  ;; Mini-posframe - show minibuffer in a posframe at top center
  (when (maybe-require-package 'mini-posframe)
    (setq mini-posframe-show-parameters
          '((left-fringe . 16)
            (right-fringe . 16)
            (internal-border-width . 16)
            (undecorated . nil)))
    (mini-posframe-mode 1))

  ;; Vertico posframe - show completions in center of screen
  (when (maybe-require-package 'vertico-posframe)
    (setq vertico-posframe-parameters
          '((left-fringe . 16)
            (right-fringe . 16)
            (internal-border-width . 16)
            (line-spacing . 0.3)
            (undecorated . nil)))

    ;; Custom position handler with top padding (VSCode-style)
    (defun my/vertico-posframe-poshandler (info)
      "Position vertico-posframe at top center with padding from top."
      (let ((pos (posframe-poshandler-frame-top-center info)))
        (cons (car pos) (+ (cdr pos) 10))))  ; Add 80px top padding

    (setq vertico-posframe-poshandler #'my/vertico-posframe-poshandler)
    ;; Set size
    (setq vertico-posframe-width 100)
    (setq vertico-posframe-height 15)
    ;; Border for rounded rectangle effect
    (setq vertico-posframe-border-width 1)

    ;; Custom face for better styling with rounded appearance
    (with-eval-after-load 'vertico-posframe
      (custom-set-faces
       '(vertico-posframe ((t (:background "#f5f5f5"))))
       '(vertico-posframe-border ((t (:background "#d0d0d0"))))
       '(vertico-current ((t (:background "#e3f2fd" :foreground "#000000" :weight bold))))))

    ;; Enable after configuration
    (vertico-posframe-mode 1))

  (when (maybe-require-package 'embark)
    (with-eval-after-load 'vertico
      (define-key vertico-map (kbd "C-c C-o") 'embark-export)
      (define-key vertico-map (kbd "C-c C-c") 'embark-act)))
  ;; https://github.com/purcell/whole-line-or-region/issues/30#issuecomment-3388095018
  (with-eval-after-load 'embark
    (push 'embark--mark-target
          (alist-get 'whole-line-or-region-delete-region
                     embark-around-action-hooks)))

  (when (maybe-require-package 'consult)
    (defmacro sanityinc/no-consult-preview (&rest cmds)
      `(with-eval-after-load 'consult
         (consult-customize ,@cmds :preview-key "M-P")))

    (sanityinc/no-consult-preview
     consult-ripgrep
     consult-git-grep consult-grep
     consult-bookmark consult-recent-file consult-xref
     consult--source-recent-file consult--source-project-recent-file consult--source-bookmark)

    (defun sanityinc/consult-ripgrep-at-point (&optional dir initial)
      (interactive (list current-prefix-arg
                         (if (use-region-p)
                             (buffer-substring-no-properties
                              (region-beginning) (region-end))
                           (if-let* ((s (symbol-at-point)))
                               (symbol-name s)))))
      (consult-ripgrep dir initial))
    (sanityinc/no-consult-preview sanityinc/consult-ripgrep-at-point)
    (when (executable-find "rg")
      (global-set-key (kbd "M-?") 'sanityinc/consult-ripgrep-at-point))

    (global-set-key [remap switch-to-buffer] 'consult-buffer)
    (global-set-key [remap switch-to-buffer-other-window] 'consult-buffer-other-window)
    (global-set-key [remap switch-to-buffer-other-frame] 'consult-buffer-other-frame)
    (global-set-key [remap goto-line] 'consult-goto-line)

    (when (maybe-require-package 'embark-consult)
      (require 'embark-consult))))

(when (maybe-require-package 'marginalia)
  (add-hook 'after-init-hook 'marginalia-mode))


(provide 'init-minibuffer)
;;; init-minibuffer.el ends here
