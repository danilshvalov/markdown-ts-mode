;;; markdown-ts-mode.el --- Major mode for markdown -*- lexical-binding: t; -*-

(require 'treesit)
(require 'markdown-ts-face)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-child "treesit.c")

(defgroup markdown-ts nil
  "Markdown commands."
  :group 'extensions)

(defcustom markdown-ts-code-language-modes
  '(("ocaml" . tuareg-mode)
    ("elisp" . emacs-lisp-mode)
    ("ditaa" . artist-mode)
    ("asymptote" . asy-mode)
    ("dot" . fundamental-mode)
    ("sqlite" . sql-mode)
    ("calc" . fundamental-mode)
    ("C" . c-mode)
    ("cpp" . c++-mode)
    ("C++" . c++-mode)
    ("screen" . shell-script-mode)
    ("shell" . sh-mode)
    ("bash" . sh-mode))
  "Alist mapping languages to their major mode.
The key is the language name, the value is the major mode.  For
many languages this is simple, but for language where this is not
the case, this variable provides a way to simplify things on the
user side.  For example, there is no ocaml-mode in Emacs, but the
mode to use is `tuareg-mode'."
  :group 'markdown-ts
  :type '(repeat
          (cons
           (string "Language name")
           (symbol "Major mode"))))

(defvar markdown-ts--code-block-query
  (treesit-query-compile
   'markdown
   '((fenced_code_block
      (info_string
       (language) @language)
      (code_fence_content) @content) @code-block)))

(defvar markdown-ts--latex-block-query
  (treesit-query-compile
   'markdown-inline
   '((latex_block
      (latex_span_delimiter) @start-delimiter
      (latex_span_delimiter) @end-delimiter))))

(defvar markdown-ts--html-block-query
  (treesit-query-compile
   'markdown
   '((html_block) @capture)))

(defvar markdown-ts--list-item-query
  (treesit-query-compile
   'markdown
   '((list_item
      (_) @list-marker
      (_) @task-list-marker) @list-item)))

(defun markdown-ts--find-list-item-predicate (node &optional _ _)
  (equal (treesit-node-type node) "list_item"))

(defun markdown-ts-find-list-item (node)
  (when-let* ((pred #'markdown-ts--find-list-item-predicate)
              (node (treesit-parent-until node pred t)))
    (treesit-query-capture node markdown-ts--list-item-query)))

(defun markdown-ts-list-item-at (pos)
  (when-let ((node (treesit-node-at pos 'markdown)))
    (markdown-ts-find-list-item node)))

(defun markdown-ts-toggle-checkbox ()
  (interactive)
  (when-let* ((captures (markdown-ts-list-item-at (point)))
              (node (cdr (assoc 'task-list-marker captures)))
              (new-marker (pcase (treesit-node-type node)
                            ("task_list_marker_unchecked" "[x]")
                            ("task_list_marker_checked" "[ ]"))))
    (replace-region-contents (treesit-node-start node)
                             (treesit-node-end node)
                             (lambda () new-marker))))

(defun markdown-ts--language-mode-predicate (mode)
  (and mode
       (fboundp mode)
       (or
        ;; major-mode-remap-alist was introduced at Emacs 29.1
        (cl-loop for pair in (bound-and-true-p major-mode-remap-alist)
                 for func = (cdr pair)
                 thereis (and (atom func) (eq mode func)))
        (cl-loop for pair in auto-mode-alist
                 for func = (cdr pair)
                 thereis (and (atom func) (eq mode func))))))

(defun markdown-ts--get-language-mode (lang)
  (cl-find-if
   #'markdown-ts--language-mode-predicate
   (nconc (list (cdr (assoc lang markdown-ts-code-language-modes))
                (cdr (assoc (downcase lang) markdown-ts-code-language-modes)))
          (and (fboundp 'treesit-language-available-p)
               (list (and (treesit-language-available-p (intern lang))
                          (intern (concat lang "-ts-mode")))
                     (and (treesit-language-available-p (intern (downcase lang)))
                          (intern (concat (downcase lang) "-ts-mode")))))
          (list
           (intern (concat lang "-mode"))
           (intern (concat (downcase lang) "-mode")))
          (list 'fundamental-mode))))

(defun markdown-ts--fontify-as-mode (mode start end)
  (interactive)
  (when (fboundp mode)
    (let ((string (buffer-substring-no-properties start end))
          (modified (buffer-modified-p))
          (has-font-lock-mode font-lock-mode)
          (buffer (current-buffer)) pos next)
      (remove-text-properties start end '(face nil))
      (with-current-buffer
          (get-buffer-create
           (concat " markdown-ts-fontification:" (symbol-name mode)))
        ;; Make sure that modification hooks are not inhibited in
        ;; the org-src-fontification buffer in case we're called
        ;; from `jit-lock-function' (Bug#25132).
        (let ((inhibit-modification-hooks nil))
          (delete-region (point-min) (point-max))
          (insert string " ")) ;; so there's a final property change
        (unless (eq major-mode mode) (funcall mode))
        (font-lock-ensure)
        (setq pos (point-min))
        (while (setq next (next-single-property-change pos 'face))
          (let ((val (get-text-property pos 'face)))
            (when val
              (put-text-property
               (+ start (1- pos))
               (1- (+ start next))
               'face
               val buffer)))
          (setq pos next)))
      (set-buffer-modified-p modified))))

(defun markdown-ts--find-code-block-predicate (node &optional _ _)
  (equal (treesit-node-type node) "fenced_code_block"))

(defun markdown-ts-find-code-block (node)
  (when-let* ((pred #'markdown-ts--find-code-block-predicate)
              (node (treesit-parent-until node pred t)))
    (treesit-query-capture node markdown-ts--code-block-query)))

(defun markdown-ts-code-block-at (pos)
  (when-let ((node (treesit-node-at pos 'markdown)))
    (markdown-ts-find-code-block node)))

(defun markdown-ts--pos-to-node (pos)
  (cond ((treesit-node-p pos) pos)
        ((numberp pos) (treesit-node-at pos 'markdown))
        ((not pos) nil)
        (t (error "Invalid pos type: %s" (type-of pos)))))

(defun markdown-ts-table-at (pos)
  (when-let* ((node (markdown-ts--pos-to-node pos))
              (node (treesit-parent-until node "^pipe_table$" t)))
    node))

(defun markdown-ts-table-cell-at (pos)
  (when-let* ((node (markdown-ts--pos-to-node pos))
              (node (treesit-parent-until node "^pipe_table_cell$" t)))
    node))

(defun markdown-ts-table-row-at (pos)
  (when-let* ((node (markdown-ts--pos-to-node pos))
              (node (treesit-parent-until node "^\\(pipe_table_row\\|pipe_table_header\\)$" t)))
    node))

(defun markdown-ts-table-rows-at (pos)
  (when-let* ((node (markdown-ts-table-at pos))
              (query '([(pipe_table_row)
                        (pipe_table_header)] @capture))
              (captures (treesit-query-capture node query))
              (captures (mapcar (lambda (entry) (cdr entry))
                                captures)))
    captures))

(defun markdown-ts-table-next-row (node)
  (when-let* ((row-node (markdown-ts-table-row-at node))
              (rows (markdown-ts-table-rows-at node))
              (rows (cl-remove-if (lambda (node)
                                    (< (treesit-node-start node)
                                       (treesit-node-end row-node)))
                                  rows)))
    (car rows)))

(defun markdown-ts-table-previous-row (node)
  (when-let* ((row-node (markdown-ts-table-row-at node))
              (rows (markdown-ts-table-rows-at node))
              (rows (cl-remove-if (lambda (node)
                                    (> (treesit-node-end node)
                                       (treesit-node-start row-node)))
                                  rows)))
    (car (last rows))))

(defun markdown-ts-table-row-cells-at (pos)
  (when-let* ((node (markdown-ts-table-row-at pos))
              (query '((pipe_table_cell) @capture))
              (captures (treesit-query-capture node query))
              (captures (mapcar (lambda (entry) (cdr entry))
                                captures)))
    captures))

(defun markdown-ts--table-next-row-cell (node)
  (when-let* ((node (markdown-ts-table-next-row node))
              (cells (markdown-ts-table-row-cells-at node)))
    (car cells)))

(defun markdown-ts-table-header-cells-at (pos)
  (when-let* ((node (markdown-ts-table-at pos))
              (query '((pipe_table_header
                        (pipe_table_cell) @capture)))
              (captures (treesit-query-capture node query))
              (captures (mapcar (lambda (entry) (cdr entry))
                                captures)))
    captures))

(defun markdown-ts--table-previous-row-cell (node)
  (when-let* ((node (markdown-ts-table-previous-row node))
              (cells (markdown-ts-table-row-cells-at node)))
    (car (last cells))))

(defun markdown-ts-table-cell-count (pos)
  (when-let* ((cells (markdown-ts-table-header-cells-at pos)))
    (length cells)))

(defun markdown-ts-table-last-row (pos)
  (when-let* ((rows (markdown-ts-table-rows-at pos)))
    (car (last rows))))

(defun markdown-ts-table-insert-row (pos)
  (when-let* ((row-node (markdown-ts-table-row-at pos))
              (cells-count (markdown-ts-table-cell-count pos))
              (blank-row (replace-regexp-in-string "[^|]" " "
                                                   (treesit-node-text row-node))))
    (goto-char (1+ (treesit-node-end row-node)))
    (save-excursion
      (insert blank-row "\n"))
    (goto-char (+ 2 (treesit-node-end row-node)))))

(defun markdown-ts-table-next-cell ()
  (interactive)
  (when-let* ((node (markdown-ts-table-cell-at (point)))
              (next-cell (or (treesit-node-next-sibling node t)
                             (markdown-ts--table-next-row-cell node))))
    (goto-char (treesit-node-start next-cell))))

(defun markdown-ts-table-previous-cell ()
  (interactive)
  (when-let* ((node (markdown-ts-table-cell-at (point)))
              (previous-cell (or (treesit-node-prev-sibling node t)
                                 (markdown-ts--table-previous-row-cell node))))
    (goto-char (treesit-node-start previous-cell))))

(defun markdown-ts--fontify-code-block (node _ _ _ &rest _)
  (let ((start (treesit-node-start node))
        (end (treesit-node-end node)))
    (put-text-property start end 'face 'markdown-ts-markup-face))

  (when-let* ((captures (markdown-ts-find-code-block node))
              (language-node (cdr (assoc 'language captures)))
              (content-node (cdr (assoc 'content captures)))
              (language (treesit-node-text language-node)))
    (markdown-ts--fontify-as-mode (markdown-ts--get-language-mode language)
                                  (treesit-node-start content-node)
                                  (treesit-node-end content-node))))

(defun markdown-ts--fontify-latex-block (node _ _ _ &rest _)
  (when-let* ((query markdown-ts--latex-block-query)
              (captures (treesit-query-capture node query))
              (start-node (cdr (assoc 'start-delimiter captures)))
              (end-node (cdr (assoc 'end-delimiter captures)))
              (start (1+ (treesit-node-end start-node)))
              (end (1- (treesit-node-start end-node)))
              (mode (markdown-ts--get-language-mode "latex")))

    (when (< start end)
      (markdown-ts--fontify-as-mode mode start end))))

(defun markdown-ts--fontify-html-block (node _ _ _ &rest _)
  (when-let* ((query markdown-ts--html-block-query)
              (captures (treesit-query-capture node query))
              (node (cdr (assoc 'capture captures)))
              (start (treesit-node-start node))
              (end (treesit-node-end node))
              (mode (markdown-ts--get-language-mode "mhtml")))
    (markdown-ts--fontify-as-mode mode start end)))

(defun markdown-ts-insert-list-item ()
  (interactive)
  (when-let* ((captures (markdown-ts-list-item-at (point)))
              (list-item-node (cdr (assoc 'list-item captures)))
              (capture-node (cdr (assoc 'list-marker captures)))
              (capture-type (treesit-node-type capture-node))
              (capture-text (treesit-node-text capture-node))
              (list-item-start (treesit-node-start list-item-node))
              (list-item-end (treesit-node-end list-item-node))
              (indent-size (save-excursion
                             (goto-char list-item-start)
                             (- list-item-start (pos-bol)))))
    (goto-char list-item-end)
    (insert (make-string indent-size ? ))
    (pcase capture-type
      ((or "list_marker_minus"
           "list_marker_plus"
           "list_marker_star")
       (insert capture-text))
      ("list_marker_dot"
       (let ((item-number (string-to-number
                           (substring capture-text nil -1))))
         (insert (format "%d. " (1+ item-number))))))
    (save-excursion
      (insert "\n"))))

(defvar markdown-ts-font-lock-settings
  (treesit-font-lock-rules
   :language 'markdown
   :feature 'heading
   '((atx_heading (atx_h1_marker)) @markdown-ts-heading-1-face
     (atx_heading (atx_h2_marker)) @markdown-ts-heading-2-face
     (atx_heading (atx_h3_marker)) @markdown-ts-heading-3-face
     (atx_heading (atx_h4_marker)) @markdown-ts-heading-4-face
     (atx_heading (atx_h5_marker)) @markdown-ts-heading-5-face
     (atx_heading (atx_h6_marker)) @markdown-ts-heading-6-face)

   :language 'markdown
   :feature 'fontified-code
   :override t
   '((fenced_code_block) @markdown-ts--fontify-code-block)

   :language 'markdown-inline
   :feature 'inline-code
   '((code_span) @markdown-ts-inline-code-face)

   :language 'markdown-inline
   :feature 'emphasis
   :override t
   '((strong_emphasis) @markdown-ts-bold-face
     (emphasis) @markdown-ts-italic-face
     (strikethrough) @markdown-ts-strike-through-face)

   :language 'markdown-inline
   :feature 'link
   :override t
   '([(link_label)
      (link_text)
      (link_title)
      (image_description)] @markdown-ts-link-title-face)

   :language 'markdown
   :feature 'checkbox
   :override t
   '((task_list_marker_unchecked) @markdown-ts-checkbox-face
     (task_list_marker_checked) @markdown-ts-checkbox-face)

   :language 'markdown-inline
   :feature 'link
   :override t
   '([(link_destination)
      (uri_autolink)
      (email_autolink)] @markdown-ts-url-face)

   :language 'markdown
   :feature 'punctuation
   '((pipe_table_header "|" @markdown-ts-punctuation-delimiter-face)
     (pipe_table_row "|" @markdown-ts-punctuation-delimiter-face)
     (pipe_table_delimiter_row "|" @markdown-ts-punctuation-delimiter-face)
     ((pipe_table_delimiter_cell) @markdown-ts-punctuation-delimiter-face))

   :language 'markdown
   :feature 'delimiter
   :override t
   '((info_string) @markdown-ts-language-info-face)

   :language 'markdown
   :feature 'delimiter
   :override t
   '((fenced_code_block_delimiter) @font-lock-punctuation-face)

   :language 'markdown-inline
   :feature 'delimiter
   '((latex_block
      (latex_span_delimiter) @markdown-ts--math-delimiter-face
      (latex_span_delimiter) @markdown-ts--math-delimiter-face))

   :language 'markdown-inline
   :feature 'math
   :override t
   '((latex_block) @markdown-ts--fontify-latex-block)

   :language 'markdown
   :feature 'html
   :override t
   '((html_block) @markdown-ts--fontify-html-block)

   :language 'markdown
   :feature 'quote
   :override 'append
   '((block_quote) @markdown-ts-quote-face)

   :language 'markdown
   :feature 'punctuation
   :override t
   '([(block_continuation)
      (block_quote_marker)] @markdown-ts-punctuation-delimiter-face)

   :language 'markdown
   :feature 'punctuation
   :override t
   '([(list_marker_plus)
      (list_marker_minus)
      (list_marker_star)
      (list_marker_dot)
      (list_marker_parenthesis)
      (thematic_break)] @markdown-ts-punctuation-special-face)

   :language 'markdown-inline
   :feature 'escape
   :override t
   '((backslash_escape) @markdown-ts-escape-face
     (hard_line_break) @markdown-ts-escape-face)

   :language 'markdown-inline
   :feature 'punctuation
   :override t
   '((inline_link
      ["[" "]" "(" ")"] @markdown-ts-punctuation-delimiter-face)
     (image
      ["!" "[" "]" "(" ")"] @markdown-ts-punctuation-delimiter-face)
     (full_reference_link
      ["[" "]"] @markdown-ts-punctuation-delimiter-face)
     (collapsed_reference_link
      ["[" "]"] @markdown-ts-punctuation-delimiter-face)
     (shortcut_link
      ["[" "]"] @markdown-ts-punctuation-delimiter-face))))

(defun markdown-ts--list-indent-anchor (node parent &rest _)
  (when-let* ((captures (markdown-ts-list-item-at (point)))
              (node (cdr (assoc 'list-marker captures))))
    (treesit-node-end node)))

(defvar markdown-ts-indent-rules
  (let ((offset 2))
    `((markdown
       ((match nil "list_item" nil 0 0) ,'markdown-ts--list-indent-anchor 0)
       ((parent-is "paragraph") ,'markdown-ts--list-indent-anchor 0)))))

(defun markdown-ts--language-at-from-code-block (pos)
  (when-let ((captures (markdown-ts-code-block-at pos))
             (node (cdr (assoc 'language captures)))
             (language (treesit-node-text node)))
    (intern language)))

(defun markdown-ts-language-at (pos)
  (or
   (markdown-ts--language-at-from-code-block pos)
   'markdown))

(defvar markdown-ts-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "M-RET") #'markdown-ts-insert-list-item)
    (define-key map (kbd "C-c C-j") #'markdown-ts-insert-list-item)
    map))

;;;###autoload
(define-derived-mode markdown-ts-mode prog-mode "Markdown"
  (when (and (treesit-ready-p 'markdown)
             (treesit-ready-p 'markdown-inline))
    (treesit-parser-create 'markdown)
    (treesit-parser-create 'markdown-inline)

    (setq-local treesit-font-lock-settings markdown-ts-font-lock-settings)
    (setq-local treesit-simple-indent-rules markdown-ts-indent-rules)
    (setq-local treesit-language-at-point-function #'markdown-ts-language-at)
    (setq-local treesit-font-lock-feature-list
                '((link keyword emphasis heading)
                  (inline-code quote delimiter escape)
                  (html checkbox)
                  (fontified-code math punctuation)))
    (treesit-major-mode-setup)

    (setq-local comment-start "<!-- ")
    (setq-local comment-end " -->")
    (setq-local comment-start-skip "<!--[ \t]*")
    (setq-local comment-column 0)

    (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-ts-mode))))

(provide 'markdown-ts-mode)
