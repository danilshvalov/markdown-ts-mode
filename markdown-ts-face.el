;;; markdown-ts-face --- Faces for markdown-ts-mode -*- lexical-binding: t; -*-

(defgroup markdown-ts-faces nil
  "Faces used by markdown."
  :group 'markdown-ts)

(defface markdown-ts-italic-face
  '((t (:inherit italic)))
  "Face for italic text. Example of italic text:

   _italic text_"
  :group 'markdown-ts-faces)

(defface markdown-ts-bold-face
  '((t (:inherit bold)))
  "Face for bold text. Example of bold text:

   **bold text**"
  :group 'markdown-ts-faces)

(defface markdown-ts-strike-through-face
  '((t (:strike-through t)))
  "Face for strike-through text. Example of strike-through text:

   ---strike-through text---"
  :group 'markdown-ts-faces)

(defface markdown-ts-heading-face
  '((t (:inherit font-lock-keyword-face)))
  "Default face for any heading level. Examples of headings:

   # Heading 1
   ## Heading 2
   ### Heading 3
   #### Heading 4
   ##### Heading 5
   ###### Heading 6"
  :group 'markdown-ts-faces)

(defface markdown-ts-heading-1-face
  '((t (:inherit markdown-ts-heading-face)))
  "Face for the first level heading. Example of heading:

  # Heading 1"
  :group 'markdown-ts-faces)

(defface markdown-ts-heading-2-face
  '((t (:inherit markdown-ts-heading-face)))
  "Face for the second level heading. Example of heading:

  ## Heading 2"
  :group 'markdown-ts-faces)

(defface markdown-ts-heading-3-face
  '((t (:inherit markdown-ts-heading-face)))
  "Face for the third level heading. Example of heading:

  ### Heading 3"
  :group 'markdown-ts-faces)

(defface markdown-ts-heading-4-face
  '((t (:inherit markdown-ts-heading-face)))
  "Face for the fourth level heading. Example of heading:

  #### Heading 4"
  :group 'markdown-ts-faces)

(defface markdown-ts-heading-5-face
  '((t (:inherit markdown-ts-heading-face)))
  "Face for the fifth level heading. Example of heading:

  ##### Heading 5"
  :group 'markdown-ts-faces)

(defface markdown-ts-heading-6-face
  '((t (:inherit markdown-ts-heading-face)))
  "Face for the sixth level heading. Example of heading:

  ###### Heading 6"
  :group 'markdown-ts-faces)

(defface markdown-ts-punctuation-delimiter-face
  '((t (:inherit font-lock-punctuation-face)))
  "Face for punctuation delimiter.")

(defface markdown-ts-punctuation-special-face
  '((t (:inherit markdown-ts-punctuation-delimiter-face)))
  "Face for special punctuations.")

(defface markdown-ts--math-delimiter-face
  '((t (:inherit markdown-ts-punctuation-delimiter-face)))
  "Face for math delimiters. Example:

   $$ <— math delimiters
   1 + 2 = 3
   $$ <— math delimiters")

(defface markdown-ts-quote-face
  '((t (:inherit font-lock-string-face)))
  "Face for quote text. Example of quote text:

   > Lorem ipsum dolor sit amet, consectetur adipiscing elit,
   > sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
  :group 'markdown-ts-faces)

(defface markdown-ts-checkbox-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for GFM checkboxes."
  :group 'markdown-ts-faces)

(defface markdown-ts-escape-face
  '((t (:inherit font-lock-escape-face)))
  "Face for escapes (e.g. backslash escape or hard linebreak)."
  :group 'markdown-ts-faces)

(defface markdown-ts-markup-face
  '((t (:inherit shadow :slant normal :weight normal)))
  "Face for markup elements."
  :group 'markdown-ts-faces)

(defface markdown-ts-header-rule-face
  '((t (:inherit markdown-markup-face)))
  "Base face for headers rules."
  :group 'markdown-ts-faces)

(defface markdown-ts-header-delimiter-face
  '((t (:inherit markdown-markup-face)))
  "Base face for headers hash delimiter."
  :group 'markdown-ts-faces)

(defface markdown-ts-list-face
  '((t (:inherit markdown-markup-face)))
  "Face for list item markers."
  :group 'markdown-ts-faces)

(defface markdown-ts-blockquote-face
  '((t (:inherit font-lock-doc-face)))
  "Face for blockquote sections."
  :group 'markdown-ts-faces)

(defface markdown-ts-code-face
  '((t (:inherit fixed-pitch)))
  "Face for inline code, pre blocks, and fenced code blocks.
This may be used, for example, to add a contrasting background to
inline code fragments and code blocks."
  :group 'markdown-ts-faces)

(defface markdown-ts-inline-code-face
  '((t (:inherit (markdown-code-face font-lock-constant-face))))
  "Face for inline code."
  :group 'markdown-ts-faces)

(defface markdown-ts-pre-face
  '((t (:inherit (markdown-code-face font-lock-constant-face))))
  "Face for preformatted text."
  :group 'markdown-ts-faces)

(defface markdown-ts-table-face
  '((t (:inherit (markdown-code-face))))
  "Face for tables."
  :group 'markdown-ts-faces)

(defface markdown-ts-language-keyword-face
  '((t (:inherit font-lock-type-face)))
  "Face for programming language identifiers."
  :group 'markdown-ts-faces)

(defface markdown-ts-language-info-face
  '((t (:inherit font-lock-string-face)))
  "Face for programming language info strings."
  :group 'markdown-ts-faces)

(defface markdown-ts-link-face
  '((t (:inherit link)))
  "Face for links."
  :group 'markdown-ts-faces)

(defface markdown-ts-missing-link-face
  '((t (:inherit font-lock-warning-face)))
  "Face for missing links."
  :group 'markdown-ts-faces)

(defface markdown-ts-reference-face
  '((t (:inherit markdown-markup-face)))
  "Face for link references."
  :group 'markdown-ts-faces)

(defface markdown-ts-footnote-marker-face
  '((t (:inherit markdown-markup-face)))
  "Face for footnote markers."
  :group 'markdown-ts-faces)

(defface markdown-ts-footnote-text-face
  '((t (:inherit font-lock-comment-face)))
  "Face for footnote text."
  :group 'markdown-ts-faces)

(defface markdown-ts-link-title-face
  '((t (:inherit font-lock-comment-face)))
  "Face for reference link titles."
  :group 'markdown-ts-faces)

(defface markdown-ts-url-face
  '((t (:inherit markdown-ts-link-face)))
  "Face for URLs that are part of markup.
For example, this applies to URLs in inline links:
[link text](http://example.com/)."
  :group 'markdown-ts-faces)

(defface markdown-ts-line-break-face
  '((t (:inherit font-lock-constant-face :underline t)))
  "Face for hard line breaks."
  :group 'markdown-ts-faces)

(defface markdown-ts-comment-face
  '((t (:inherit font-lock-comment-face)))
  "Face for HTML comments."
  :group 'markdown-ts-faces)

(defface markdown-ts-math-face
  '((t (:inherit font-lock-string-face)))
  "Face for LaTeX expressions."
  :group 'markdown-ts-faces)

(defface markdown-ts-metadata-key-face
  '((t (:inherit font-lock-variable-name-face)))
  "Face for metadata keys."
  :group 'markdown-ts-faces)

(defface markdown-ts-metadata-value-face
  '((t (:inherit font-lock-string-face)))
  "Face for metadata values."
  :group 'markdown-ts-faces)

(defface markdown-ts-highlight-face
  '((t (:inherit highlight)))
  "Face for mouse highlighting."
  :group 'markdown-ts-faces)

(defface markdown-ts-hr-face
  '((t (:inherit markdown-markup-face)))
  "Face for horizontal rules."
  :group 'markdown-ts-faces)

(defface markdown-ts-html-tag-name-face
  '((t (:inherit font-lock-type-face)))
  "Face for HTML tag names."
  :group 'markdown-ts-faces)

(defface markdown-ts-html-tag-delimiter-face
  '((t (:inherit markdown-markup-face)))
  "Face for HTML tag delimiters."
  :group 'markdown-ts-faces)

(defface markdown-ts-html-attr-name-face
  '((t (:inherit font-lock-variable-name-face)))
  "Face for HTML attribute names."
  :group 'markdown-ts-faces)

(defface markdown-ts-html-attr-value-face
  '((t (:inherit font-lock-string-face)))
  "Face for HTML attribute values."
  :group 'markdown-ts-faces)

(defface markdown-ts-html-entity-face
  '((t (:inherit font-lock-variable-name-face)))
  "Face for HTML entities."
  :group 'markdown-ts-faces)

(defface markdown-ts-highlighting-face
  '((t (:background "yellow" :foreground "black")))
  "Face for highlighting."
  :group 'markdown-ts-faces)

(provide 'markdown-ts-face)
