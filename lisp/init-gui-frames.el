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

;; Default font: Sarasa Mono SC at ~16px logical pixels (Emacs uses 1/10 pt units)
(when (display-graphic-p)
  ;; Set default font to 16pt which displays as ~16px on Retina screens
  (set-face-attribute 'default nil :family "Sarasa Mono SC" :height 160)
  (set-face-attribute 'fixed-pitch nil :family "Sarasa Mono SC" :height 160)

  ;; Specify the font for 'han' (Chinese) characters
  (set-fontset-font t 'han (font-spec :family "Sarasa Mono SC" :size 16))

  ;; Configure emoji and symbol fonts for proper Unicode support
  ;; These are critical for displaying icons, emoji, and special characters in terminals
  (set-fontset-font t 'symbol (font-spec :family "Apple Symbols") nil 'prepend)
  (set-fontset-font t 'symbol (font-spec :family "Symbols Nerd Font Mono") nil 'prepend)
  (set-fontset-font t 'emoji (font-spec :family "Apple Color Emoji") nil 'prepend)

  ;; Specific Unicode ranges for box drawing and block elements
  (set-fontset-font t '(#x2500 . #x257F) (font-spec :family "Symbols Nerd Font Mono") nil 'prepend) ; Box Drawing
  (set-fontset-font t '(#x2580 . #x259F) (font-spec :family "Symbols Nerd Font Mono") nil 'prepend) ; Block Elements
  (set-fontset-font t '(#x25A0 . #x25FF) (font-spec :family "Symbols Nerd Font Mono") nil 'prepend) ; Geometric Shapes
  (set-fontset-font t '(#x2600 . #x26FF) (font-spec :family "Apple Color Emoji") nil 'prepend)       ; Miscellaneous Symbols
  (set-fontset-font t '(#x1F300 . #x1F9FF) (font-spec :family "Apple Color Emoji") nil 'prepend)    ; Emoji

  ;; Use `face-font-rescale-alist` to fine-tune CJK font scaling
  ;; Adjust to prevent line height jumps when mixing Chinese and English
  (setq face-font-rescale-alist '(("Sarasa Mono SC" . 1.0))))

;; Keep line spacing zero so the box cursor aligns with glyphs.
(setq-default line-spacing 0)
;; Make the box cursor match the glyph height instead of the full line box.
(setq-default x-stretch-cursor t)

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode 1))
(when (fboundp 'set-scroll-bar-mode)
  (set-scroll-bar-mode 'right))

;; Keep menu bar enabled for native integration
(when (fboundp 'menu-bar-mode)
  (menu-bar-mode 1))

(when (fboundp 'set-fringe-mode)
  (set-fringe-mode '(12 . 8)))

;; 禁用换行指示符（去掉两边的换行箭头符号）
(setq-default fringe-indicator-alist
              (delq (assq 'continuation fringe-indicator-alist)
                    fringe-indicator-alist))

;; 让fringe背景色与编辑区背景色一致，不显示分割线
(add-hook 'after-init-hook
          (lambda ()
            (set-face-attribute 'fringe nil :background nil)))

(let ((padding '(internal-border-width . 12)))
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
  ;; Use the standard titlebar to keep the window title centered.
  (setq ns-transparent-titlebar nil)
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . nil))
  (add-to-list 'initial-frame-alist '(ns-transparent-titlebar . nil)))


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
