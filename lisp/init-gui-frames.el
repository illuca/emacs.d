;;; init-gui-frames.el --- Behaviour specific to non-TTY frames -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:


;; Stop C-z from minimizing windows under OS X

(defun sanityinc/maybe-suspend-frame ()
  (interactive)
  (unless (and *is-a-mac* window-system)
    (suspend-frame)))

(global-set-key (kbd "C-z") 'sanityinc/maybe-suspend-frame)



;; Suppress GUI features

(setq use-file-dialog t)
(setq use-dialog-box t)
(setq inhibit-startup-screen t)



;; Window size and features

(setq-default
 window-resize-pixelwise t
 frame-resize-pixelwise t)

;; Default font: Sarasa Mono SC at ~16px (Emacs uses 1/10 pt units)
(when (display-graphic-p)
  (set-face-attribute 'default nil :family "Sarasa Mono SC" :height 160))

;; Add a little breathing room around the text.
(setq-default line-spacing 0.15)

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode 1))
(when (fboundp 'set-scroll-bar-mode)
  (set-scroll-bar-mode 'right))

;; Keep menu bar enabled for native integration
(when (fboundp 'menu-bar-mode)
  (menu-bar-mode 1))

(let ((padding '(internal-border-width . 8)))
  (add-to-list 'default-frame-alist padding)
  (add-to-list 'initial-frame-alist padding))

(defun sanityinc/adjust-opacity (frame incr)
  "Adjust the background opacity of FRAME by increment INCR."
  (unless (display-graphic-p frame)
    (error "Cannot adjust opacity of this frame"))
  (let* ((oldalpha (or (frame-parameter frame 'alpha) 100))
         ;; The 'alpha frame param became a pair at some point in
         ;; emacs 24.x, e.g. (100 100)
         (oldalpha (if (listp oldalpha) (car oldalpha) oldalpha))
         (newalpha (+ incr oldalpha)))
    (when (and (<= frame-alpha-lower-limit newalpha) (>= 100 newalpha))
      (modify-frame-parameters frame (list (cons 'alpha newalpha))))))

(when (and *is-a-mac* (fboundp 'toggle-frame-fullscreen))
  ;; Command-Option-f to toggle fullscreen mode
  ;; Hint: Customize `ns-use-native-fullscreen'
  (global-set-key (kbd "M-ƒ") 'toggle-frame-fullscreen))

;; TODO: use seethru package instead?
(global-set-key (kbd "M-C-8") (lambda () (interactive) (sanityinc/adjust-opacity nil -2)))
(global-set-key (kbd "M-C-9") (lambda () (interactive) (sanityinc/adjust-opacity nil 2)))
(global-set-key (kbd "M-C-7") (lambda () (interactive) (modify-frame-parameters nil `((alpha . 100)))))


(when *is-a-mac*
  (when (maybe-require-package 'ns-auto-titlebar)
    (ns-auto-titlebar-mode)))


(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
                 "%b"))))

;; Non-zero values for `line-spacing' can mess up ansi-term and co,
;; so we zero it explicitly in those cases.
(add-hook 'term-mode-hook
          (lambda ()
            (setq line-spacing 0)))


;; Change global font size easily

(require-package 'default-text-scale)
(add-hook 'after-init-hook 'default-text-scale-mode)



(require-package 'disable-mouse)


(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode))


(provide 'init-gui-frames)
;;; init-gui-frames.el ends here
