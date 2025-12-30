;;; init-neotree.el --- Neotree file explorer -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(when (maybe-require-package 'neotree)
  ;; Basic settings
  (setq neo-window-width 35)
  (setq neo-window-fixed-size nil)
  (setq neo-theme 'icons) ; Use icons (requires all-the-icons)

  ;; Show hidden files
  (setq neo-show-hidden-files t)

  ;; Auto refresh
  (setq neo-autorefresh t)

  ;; Smart open - always find current file
  (setq neo-smart-open t)

  ;; Use popwin for better window management
  (setq neo-persist-show nil)

  ;; Keybindings
  (global-set-key (kbd "C-x t t") 'neotree-toggle)
  (global-set-key (kbd "C-x t f") 'neotree-find)
  (global-set-key (kbd "C-x t d") 'neotree-dir)

  ;; Optional: integrate with projectile
  (when (featurep 'projectile)
    (global-set-key (kbd "C-x t p") 'neotree-projectile-action)))

(provide 'init-neotree)
;;; init-neotree.el ends here
