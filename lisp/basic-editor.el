;;; basic-editor.el --- Minimal editor-friendly defaults -*- lexical-binding: t; -*-

;; A small, stable set of defaults for basic editing on macOS.

(defun basic-editor-redo ()
  "Redo the last undone change."
  (interactive)
  (cond
   ((fboundp 'undo-redo) (undo-redo))
   ((fboundp 'redo) (redo))
   (t (message "Redo not available in this Emacs build."))))

(defun basic-editor-save-buffer ()
  "Save the current buffer, using a GUI save panel when needed."
  (interactive)
  (if buffer-file-name
      (save-buffer)
    (let ((use-file-dialog t)
          (use-dialog-box t))
      (call-interactively #'write-file))))

(defun basic-editor-find-file ()
  "Open a file using native macOS Finder dialog."
  (interactive)
  (if (and (eq system-type 'darwin)
           (fboundp 'ns-read-file-name))
      ;; Use native macOS file picker
      (let ((file (ns-read-file-name "Open file: "
                                     (or default-directory "~")
                                     nil nil nil nil)))
        (when file
          (find-file file)))
    ;; Fallback to standard find-file with dialog
    (let ((use-file-dialog t)
          (use-dialog-box t)
          (completing-read-function #'completing-read-default)
          (read-file-name-function #'read-file-name-default))
      (call-interactively #'find-file))))

(defun basic-editor-new-empty-buffer ()
  "Create and switch to a new empty buffer."
  (interactive)
  (let ((buffer (generate-new-buffer "untitled")))
    (switch-to-buffer buffer)
    (funcall initial-major-mode)
    (setq buffer-offer-save t)))

(defun basic-editor-kill-buffer-and-window ()
  "Kill the current buffer and delete its window when possible."
  (interactive)
  (if (one-window-p t)
      (kill-current-buffer)
    (kill-buffer-and-window)))

(defun basic-editor-split-right-and-focus ()
  "Split the window to the right and focus the new window."
  (interactive)
  (select-window (split-window-right)))

(defun basic-editor-comment-toggle ()
  "Toggle comment for the current line or active region."
  (interactive)
  (if (fboundp 'comment-line)
      (comment-line 1)
    (comment-dwim nil)))

(defun basic-editor-duplicate ()
  "Duplicate the current line or active region."
  (interactive)
  (let ((origin (point)))
    (if (use-region-p)
        (let ((text (buffer-substring (region-beginning) (region-end))))
          (save-excursion
            (goto-char (region-end))
            (insert text)))
      (let ((line (buffer-substring (line-beginning-position)
                                    (line-end-position))))
        (save-excursion
          (goto-char (line-end-position))
          (newline)
          (insert line))))
    (goto-char origin)))

(defun basic-editor-indent ()
  "Indent the active region or current line."
  (interactive)
  (if (use-region-p)
      (indent-region (region-beginning) (region-end))
    (indent-for-tab-command)))

(defun basic-editor-outdent ()
  "Outdent the active region or current line."
  (interactive)
  (let ((offset (- tab-width)))
    (if (use-region-p)
        (indent-rigidly (region-beginning) (region-end) offset)
      (indent-rigidly (line-beginning-position) (line-end-position) offset))))

(defun basic-editor-delete-to-bol ()
  "Delete text from point back to the beginning of the line."
  (interactive)
  (kill-line 0))

(defvar basic-editor--nav-back-stack nil)
(defvar basic-editor--nav-forward-stack nil)
(defvar basic-editor--nav-last-location nil)
(defvar basic-editor--nav-hooks-enabled nil)

(defconst basic-editor--nav-min-distance 80)
(defconst basic-editor--nav-ignored-commands
  '(basic-editor-nav-back
    basic-editor-nav-forward
    self-insert-command
    backward-char
    forward-char
    previous-line
    next-line
    left-char
    right-char
    backward-word
    forward-word
    beginning-of-line
    end-of-line
    scroll-up-command
    scroll-down-command
    mwheel-scroll
    mouse-set-point
    mouse-drag-region))

(defun basic-editor--nav--remember-location ()
  (unless (minibufferp)
    (setq basic-editor--nav-last-location
          (cons (current-buffer) (point)))))

(defun basic-editor--nav--push (buffer position)
  (let ((marker (with-current-buffer buffer (copy-marker position)))
        (top (car basic-editor--nav-back-stack)))
    (unless (and top
                 (marker-buffer top)
                 (eq (marker-buffer top) buffer)
                 (= (marker-position top) position))
      (push marker basic-editor--nav-back-stack)
      (setq basic-editor--nav-forward-stack nil))))

(defun basic-editor--nav--record-location ()
  (when (and basic-editor--nav-last-location
             (not (minibufferp))
             (not (memq this-command basic-editor--nav-ignored-commands)))
    (let* ((last-buffer (car basic-editor--nav-last-location))
           (last-point (cdr basic-editor--nav-last-location))
           (distance (abs (- (point) last-point))))
      (when (and (buffer-live-p last-buffer)
                 (or (not (eq last-buffer (current-buffer)))
                     (>= distance basic-editor--nav-min-distance)))
        (basic-editor--nav--push last-buffer last-point)))))

(defun basic-editor--nav--pop (stack-var)
  (let ((stack (symbol-value stack-var)))
    (while (and stack (not (marker-buffer (car stack))))
      (setq stack (cdr stack)))
    (let ((marker (car stack)))
      (set stack-var (cdr stack))
      marker)))

(defun basic-editor--nav--push-current (stack-var)
  (let ((marker (copy-marker (point))))
    (set stack-var (cons marker (symbol-value stack-var)))))

(defun basic-editor-nav-back ()
  "Move to the previous location in navigation history."
  (interactive)
  (let ((marker (basic-editor--nav--pop 'basic-editor--nav-back-stack)))
    (if (not marker)
        (message "No previous location.")
      (basic-editor--nav--push-current 'basic-editor--nav-forward-stack)
      (switch-to-buffer (marker-buffer marker))
      (goto-char (marker-position marker)))))

(defun basic-editor-nav-forward ()
  "Move to the next location in navigation history."
  (interactive)
  (let ((marker (basic-editor--nav--pop 'basic-editor--nav-forward-stack)))
    (if (not marker)
        (message "No next location.")
      (basic-editor--nav--push-current 'basic-editor--nav-back-stack)
      (switch-to-buffer (marker-buffer marker))
      (goto-char (marker-position marker)))))

(defun basic-editor--enable-navigation-history ()
  (unless basic-editor--nav-hooks-enabled
    (setq basic-editor--nav-hooks-enabled t)
    (add-hook 'pre-command-hook #'basic-editor--nav--remember-location)
    (add-hook 'post-command-hook #'basic-editor--nav--record-location)))

(defconst basic-editor--terminal-buffer-name "*basic-editor-terminal*")
(defconst basic-editor--terminal-buffer-base "basic-editor-terminal")

(defun basic-editor--ensure-terminal-buffer ()
  (or (get-buffer basic-editor--terminal-buffer-name)
      (save-window-excursion
        (cond
         ((fboundp 'eat)
          (let ((buf (eat)))
            (with-current-buffer buf
              (rename-buffer basic-editor--terminal-buffer-name t))))
         ((fboundp 'vterm)
          (vterm basic-editor--terminal-buffer-name))
         (t
          (ansi-term (or (getenv "SHELL") shell-file-name)
                     basic-editor--terminal-buffer-base)))
        (get-buffer basic-editor--terminal-buffer-name))))

(defun basic-editor-open-terminal ()
  "Open or focus the integrated terminal buffer."
  (interactive)
  (let* ((buffer (basic-editor--ensure-terminal-buffer))
         (window (get-buffer-window buffer)))
    (if (window-live-p window)
        (select-window window)
      (pop-to-buffer buffer))))

(defun basic-editor--bottom-side-window-p (window)
  (let ((edges (window-edges window)))
    (= (nth 3 edges) (frame-height))))

(defun basic-editor--find-bottom-terminal-window (buffer)
  (let ((found nil))
    (dolist (window (window-list))
      (when (and (eq (window-buffer window) buffer)
                 (basic-editor--bottom-side-window-p window))
        (setq found window)))
    found))

(defun basic-editor--main-window ()
  (let ((selected (selected-window)))
    (if (window-parameter selected 'window-side)
        (let ((found nil))
          (dolist (window (window-list))
            (when (and (not found)
                       (not (window-parameter window 'window-side)))
              (setq found window)))
          (or found selected))
      selected)))

(defun basic-editor-open-terminal-below ()
  "Open or focus the integrated terminal at the bottom."
  (interactive)
  (let* ((buffer (basic-editor--ensure-terminal-buffer))
         (window (basic-editor--find-bottom-terminal-window buffer)))
    (if (window-live-p window)
        (select-window window)
      (let ((target (basic-editor--main-window)))
        (select-window target)
        (let ((new-window (split-window-below)))
          (set-window-buffer new-window buffer)
          (select-window new-window))))))

(defvar basic-editor--override-keys-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "s-b") #'basic-editor-open-terminal-below)
    (define-key map (kbd "s-2") #'basic-editor-open-terminal-right)
    (define-key map (kbd "s-p") #'execute-extended-command)
    map)
  "Keymap for overriding macOS keybindings that must win everywhere.")

(define-minor-mode basic-editor--override-keys-mode
  "Global overrides for a few macOS keybindings."
  :global t
  :keymap basic-editor--override-keys-mode-map)

(defun basic-editor--right-side-window-p (window)
  (let ((edges (window-edges window)))
    (= (nth 2 edges) (frame-width))))

(defun basic-editor--rightmost-window ()
  (let ((rightmost nil)
        (right-edge -1))
    (dolist (window (window-list))
      (let ((edge (nth 2 (window-edges window))))
        (when (> edge right-edge)
          (setq right-edge edge)
          (setq rightmost window))))
    rightmost))

(defun basic-editor--find-right-terminal-window (buffer)
  (let ((found nil))
    (dolist (window (window-list))
      (when (and (eq (window-buffer window) buffer)
                 (basic-editor--right-side-window-p window))
        (setq found window)))
    found))

(defun basic-editor-open-terminal-right ()
  "Open or focus the integrated terminal on the right side."
  (interactive)
  (let* ((buffer (basic-editor--ensure-terminal-buffer))
         (window (basic-editor--find-right-terminal-window buffer)))
    (if (window-live-p window)
        (select-window window)
      (let ((target (basic-editor--rightmost-window)))
        (select-window target)
        (let ((new-window (split-window-right)))
          (set-window-buffer new-window buffer)
          (select-window new-window))))))

(defvar basic-editor--sidebar-window nil)
(defvar basic-editor--sidebar-prev-window nil)

(defun basic-editor--sidebar-root ()
  (let ((project (when (fboundp 'project-current)
                   (project-current nil))))
    (if project
        (project-root project)
      default-directory)))

(defun basic-editor--find-sidebar-window ()
  (or (and (window-live-p basic-editor--sidebar-window)
           basic-editor--sidebar-window)
      (let ((found nil))
        (dolist (window (window-list))
          (when (window-parameter window 'basic-editor-sidebar)
            (setq found window)))
        found)))

(defun basic-editor-toggle-sidebar ()
  "Toggle a left-side file browser and focus it."
  (interactive)
  (let ((window (basic-editor--find-sidebar-window)))
    (if (window-live-p window)
        (progn
          (delete-window window)
          (setq basic-editor--sidebar-window nil)
          (when (window-live-p basic-editor--sidebar-prev-window)
            (select-window basic-editor--sidebar-prev-window))
          (setq basic-editor--sidebar-prev-window nil))
      (let* ((root (basic-editor--sidebar-root))
             (buffer (dired-noselect root))
             (prev (selected-window))
             (side-window (display-buffer-in-side-window
                           buffer '((side . left)
                                    (slot . 0)
                                    (window-width . 0.25)))))
        (set-window-parameter side-window 'basic-editor-sidebar t)
        (setq basic-editor--sidebar-window side-window)
        (setq basic-editor--sidebar-prev-window prev)
        (select-window side-window)))))

(defun basic-editor--set-mac-keys ()
  (when (eq system-type 'darwin)
    ;; Use Command for mac-style shortcuts, keep Option as Meta.
    (setq mac-command-modifier 'super)
    (setq mac-option-modifier 'meta)
    (setq use-file-dialog t)
    (setq use-dialog-box t)
    (global-set-key (kbd "s-z") #'undo)
    (global-set-key (kbd "s-Z") #'basic-editor-redo)
    (global-set-key (kbd "s-x") #'kill-region)
    (global-set-key (kbd "s-c") #'kill-ring-save)
    (global-set-key (kbd "s-v") #'yank)
    (global-set-key (kbd "s-a") #'mark-whole-buffer)
    (global-set-key (kbd "s-s") #'basic-editor-save-buffer)
    (global-set-key (kbd "s-o") #'basic-editor-find-file)
    (global-set-key (kbd "s-e") #'consult-recent-file)
    (global-set-key (kbd "s-P") #'execute-extended-command)
    (global-set-key (kbd "s-n") #'basic-editor-new-empty-buffer)
    (global-set-key (kbd "s-N") #'make-frame-command)
    (global-set-key (kbd "s-w") #'basic-editor-kill-buffer-and-window)
    (global-set-key (kbd "s-q") #'save-buffers-kill-terminal)
    (global-set-key (kbd "s-f") #'isearch-forward)
    (global-set-key (kbd "s-[") #'basic-editor-nav-back)
    (global-set-key (kbd "s-]") #'basic-editor-nav-forward)
    (global-set-key (kbd "s-E") #'neotree-toggle)
    (global-set-key (kbd "s-/") #'basic-editor-comment-toggle)
    (global-set-key (kbd "s-d") #'basic-editor-duplicate)
    (global-set-key (kbd "s-\\") #'basic-editor-split-right-and-focus)
    (global-set-key (kbd "<tab>") #'basic-editor-indent)
    (global-set-key (kbd "<backtab>") #'basic-editor-outdent)
    (global-set-key (kbd "s-<delete>") #'basic-editor-delete-to-bol)
    (global-set-key (kbd "s-<backspace>") #'basic-editor-delete-to-bol)
    ;; Emacs Lisp evaluation shortcuts
    (global-set-key (kbd "s-r") #'eval-last-sexp)
    (global-set-key (kbd "s-R") #'eval-print-last-sexp)
    ;; ESC to cancel/quit (like other modern editors)
    (global-set-key (kbd "<escape>") #'keyboard-quit)
    (basic-editor--override-keys-mode 1)
    (basic-editor--enable-navigation-history)))

(menu-bar-mode 1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode 1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode 1))

(delete-selection-mode 1)
(transient-mark-mode 1)

(setq select-enable-clipboard t)

(basic-editor--set-mac-keys)

(provide 'basic-editor)
;;; basic-editor.el ends here
