;;; init-centaur-tabs.el --- Centaur tabs configuration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(when (maybe-require-package 'centaur-tabs)
  ;; Enable centaur-tabs
  (centaur-tabs-mode t)

  ;; Tab style
  (setq centaur-tabs-style "bar")
  (setq centaur-tabs-height 32)
  (setq centaur-tabs-set-icons t)
  (setq centaur-tabs-set-bar 'under)
  (setq centaur-tabs-set-close-button nil)
  (setq centaur-tabs-set-modified-marker t)
  (setq centaur-tabs-modified-marker "●")

  ;; Light theme colors
  (with-eval-after-load 'centaur-tabs
    (set-face-attribute 'centaur-tabs-default nil
                        :background "#f0f0f0"
                        :foreground "#666666")
    (set-face-attribute 'centaur-tabs-selected nil
                        :background "#ffffff"
                        :foreground "#000000"
                        :box nil)
    (set-face-attribute 'centaur-tabs-unselected nil
                        :background "#e8e8e8"
                        :foreground "#666666"
                        :box nil)
    (set-face-attribute 'centaur-tabs-selected-modified nil
                        :background "#ffffff"
                        :foreground "#d75f00"
                        :box nil)
    (set-face-attribute 'centaur-tabs-unselected-modified nil
                        :background "#e8e8e8"
                        :foreground "#d75f00"
                        :box nil)
    (set-face-attribute 'centaur-tabs-active-bar-face nil
                        :background "#4078f2")
    (set-face-attribute 'centaur-tabs-modified-marker-selected nil
                        :foreground "#d75f00"
                        :background "#ffffff")
    (set-face-attribute 'centaur-tabs-modified-marker-unselected nil
                        :foreground "#d75f00"
                        :background "#e8e8e8"))

  ;; Show buffer name
  (setq centaur-tabs-label-fixed-length 0)
  (setq centaur-tabs-auto-scroll-flag t)

  ;; Group tabs by projectile project
  (centaur-tabs-group-by-projectile-project)

  ;; Enable helm integration if available
  (when (featurep 'helm)
    (centaur-tabs-enable-buffer-reordering))

  ;; Keybindings - macOS style
  (global-set-key (kbd "s-{") 'centaur-tabs-backward)
  (global-set-key (kbd "s-}") 'centaur-tabs-forward)

  ;; Alternative keybindings
  (global-set-key (kbd "C-<prior>") 'centaur-tabs-backward)
  (global-set-key (kbd "C-<next>") 'centaur-tabs-forward)

  ;; Don't show tabs in certain modes
  (defun centaur-tabs-hide-tab (x)
    "Do not show buffer X in tabs."
    (let ((name (format "%s" x)))
      (or
       ;; Current window is not dedicated window.
       (window-dedicated-p (selected-window))

       ;; Buffer name starts with *
       (string-prefix-p "*" name)

       ;; Special buffers
       (string-prefix-p " " name)

       ;; Helm, magit, etc
       (and (string-prefix-p "magit" name)
            (not (file-name-extension name)))

       ;; NeoTree
       (memq (buffer-local-value 'major-mode x)
             '(neotree-mode)))))

  (setq centaur-tabs-hide-tab-function 'centaur-tabs-hide-tab))

(provide 'init-centaur-tabs)
;;; init-centaur-tabs.el ends here
