;;; init-modeline.el --- Simplify mode line display -*- lexical-binding: t -*-
;;; Commentary:
;; Clean up the mode line by hiding less important minor mode indicators
;;; Code:

;; 隐藏 ElDoc 在 mode line 中的指示器
(with-eval-after-load 'eldoc
  (setq eldoc-minor-mode-string nil))

;; 简化列号显示格式
(column-number-mode 1)
(setq column-number-indicator-zero-based nil)  ; 列号从 1 开始而不是 0

;; 显示文件大小
(size-indication-mode 1)

(provide 'init-modeline)
;;; init-modeline.el ends here
