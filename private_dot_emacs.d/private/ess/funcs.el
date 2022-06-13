;;; funcs.el --- ESS Layer functions File
;;
;; Copyright (c) 2012-2021 Sylvain Benner & Contributors
;;
;; Author: Sylvain Benner <sylvain.benner@gmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.



;; R

(defun spacemacs//ess-may-setup-r-lsp ()
  "Conditionally setup LSP based on backend."
  (when (eq ess-r-backend 'lsp)
    (spacemacs//ess-setup-r-lsp)))

(defun spacemacs//ess-setup-r-lsp ()
  "Setup LSP backend."
  (if (configuration-layer/layer-used-p 'lsp)
      (lsp-deferred)
    (message "`lsp' layer is not installed, please add `lsp' layer to your dotfile.")))

;; fnmate

(defun text-around-cursor (&optional rows-around)
  (let ((rows-around (or rows-around 10))
        (current-line (line-number-at-pos))
        (initial-point (point)))
    (save-mark-and-excursion
      (goto-line (- current-line rows-around))
      (set-mark (point))
      (goto-line (+ current-line rows-around))
      (end-of-line)
      ;; Return a list of text, index
      (list (buffer-substring-no-properties (mark) (point))
            (+ (- initial-point (mark)) 1)))))

(defun strip-ess-output-junk (r-buffer)
  (with-current-buffer r-buffer
    (goto-char (point-min))
    (while (re-search-forward "\\+\s" nil t)
      (replace-match ""))))

(defun exec-r-fn-to-buffer (r_fn text)
  (let ((r-process (ess-get-process))
        (r-output-buffer (get-buffer-create "*R-output*")))
    (ess-string-command
     (format "cat(%s(%s))\n" r_fn text)
     r-output-buffer nil)
    (strip-ess-output-junk r-output-buffer)
    (save-mark-and-excursion
      (goto-char (point-max))
      (newline)
      (insert-buffer r-output-buffer))))

;; fnmate functions for keybindings
(defun fnmate ()
  (interactive)
  (let* ((input-context (text-around-cursor))
         (text (prin1-to-string (car input-context)))
         (index (cdr input-context)))
    (ess-eval-linewise (format "fnmate::fnmate_fn.R(%s, %s)" text index))))

;; Drake
(defun drake-make ()
  (interactive)
  ;; (ess-eval-linewise "drake::r_make()")
  (ess-eval-linewise "capsule::run(drake::r_make())")
  (ess-eval-linewise "beepr::beep()"))

;; Unlock Drake
(defun drake-unlock ()
  (interactive)
  (ess-eval-linewise "drake::drake_cache(here::here('.drake'))$unlock()"))

(defun readd-target-at-point ()
  "call drake::readd on object at point to load it into environment."
  (interactive)
  (let ((target (symbol-at-point)))
    (ess-eval-linewise (format "%s <- drake::readd(%s)\n" target target))))

;; Targets
(defun targets-make ()
  (interactive)
  (ess-eval-linewise "targets::tar_make()")
  (ess-eval-linewise "beepr::beep()"))

(defun targets-read-target-at-point ()
  "call targets::tar_read() on object at point to load it into environment."
  (interactive)
  (let ((target (symbol-at-point)))
    (ess-eval-linewise (format "%s <- targets::tar_read(%s)\n" target target))))

;; Source
(defun source-functions ()
  "source ./R"
  (interactive)
  (ess-eval-linewise "Jmisc::sourceAll('R')"))

(defun source-packages-file ()
  "source ./packages.R"
  (interactive)
  (ess-eval-linewise "source('./packages.R')"))

;; Tidyverse IDE
(defun tide-insert-pipe ()
  "Insert a %>% and newline"
  (interactive)
  (insert " %>%"))

(defun insert-native-pipe ()
  "Insert a |> and newline"
  (interactive)
  (insert " |>"))

;; Mark a word at a point
;; http://www.emacswiki.org/emacs/ess-edit.el
(defun ess-edit-word-at-point ()
  (save-excursion
    (buffer-substring
     (+ (point) (skip-chars-backward "a-zA-Z0-9._"))
     (+ (point) (skip-chars-forward "a-zA-Z0-9._")))))
;; eval any word where the cursor is (objects, functions, etc)
(defun ess-eval-word ()
  (interactive)
  (let ((x (ess-edit-word-at-point)))
    (ess-eval-linewise (concat x)))
  )

;; Shiny
(defun tide-shiny-run-app ()
  "Run a shiny app in the current working directory"
  (interactive)
  (ess-eval-linewise "shiny::runApp()"))

;; Rmarkdowm

;; Insert a new (empty) chunk to R markdown
(defun insert-chunk ()
  "Insert chunk environment Rmd sessions."
  (interactive)
  (insert "```{r}\n\n```")
  (forward-line -1)
  )
;; key binding
(global-set-key (kbd "C-c i") 'insert-chunk)

(defun tide-rmd-rend ()
  "Render rmarkdown files with an interactive selection prompt"
  (interactive)
  (ess-eval-linewise "mmmisc::rend()"))

(defun tide-draft-rmd ()
  "Draft a new Rmd file from a template interactively."
  (interactive)
  (setq rmd-file
        (read-from-minibuffer "Rmd Filename (draft_<date>.Rmd): "
                              nil nil t t
                              (format "draft_%s.Rmd"
                                      (string-trim
                                       (shell-command-to-string "date --iso-8601")))))
  (setq rmd-template
        (read-from-minibuffer
         (format "Draft %s from template (mmmisc/basic): " rmd-file)
         nil nil t t "mmmisc/basic"))
  (symbol-name rmd-template)
  (string-match "\\([^/]+\\)/\\([^/]+\\)"
                (symbol-name rmd-template))
  (setq template-pkg
        (substring
         (symbol-name rmd-template)
         (match-beginning 1)
         (match-end 1)))
  (setq template-name
        (substring
         (symbol-name rmd-template)
         (match-beginning 2)
         (match-end 2)))
  (message "Drafting using template %s from package %s" template-name template-pkg)
  (ess-eval-linewise
   (format "rmarkdown::draft(file = \"%s\", template = \"%s\",
                package = \"%s\", edit = FALSE)"
           rmd-file template-name template-pkg))
  )

;; Styling
(defun tide-save-and-style-file ()
  "Save the current buffer and style using styler"
  (interactive)
  (save-buffer)
  (let ((filename (buffer-file-name)))
    (ess-eval-linewise
     (format "styler::style_file(\"%s\")" filename))))

;; Set fontification
(setq ess-R-font-lock-keywords
      '((ess-R-fl-keyword:keywords   . t)
        (ess-R-fl-keyword:constants  . t)
        (ess-R-fl-keyword:modifiers  . t)
        (ess-R-fl-keyword:fun-defs   . t)
        (ess-R-fl-keyword:assign-ops . t)
        (ess-R-fl-keyword:%op%       . t)
        (ess-fl-keyword:fun-calls    . t)
        (ess-fl-keyword:numbers)
        (ess-fl-keyword:operators . t)
        (ess-fl-keyword:delimiters)
        (ess-fl-keyword:=)
        (ess-R-fl-keyword:F&T)))

;; Key Bindings

(defun spacemacs//ess-bind-keys-for-mode (mode)
  "Bind the keys in MODE."
  (spacemacs/declare-prefix-for-mode mode "md" "debug")
  (spacemacs/declare-prefix-for-mode mode "mD" "devtools")
  (spacemacs/declare-prefix-for-mode mode "mDc" "check")
  (spacemacs/declare-prefix-for-mode mode "mE" "extra")
  (spacemacs/declare-prefix-for-mode mode "mh" "help")
  (spacemacs/declare-prefix-for-mode mode "mm" "make")
  (spacemacs/declare-prefix-for-mode mode "mf" "fnmate")
  (spacemacs/declare-prefix-for-mode mode "mk" "rmarkdown")
  (spacemacs/declare-prefix-for-mode mode "mS" "shiny")
  (spacemacs/declare-prefix-for-mode mode "mc" "code")
  (spacemacs/set-leader-keys-for-major-mode mode
    "h" 'ess-doc-map              ;; help
    "d" 'ess-dev-map              ;; debug
    "D" 'ess-r-package-dev-map    ;; devtools
    "E" 'ess-extra-map            ;; extra
    ;; Make
    "mf" 'source-functions
    "mm" 'drake-make
    "mt" 'targets-make
    "mu" 'drake-unlock
    "mr" 'readd-target-at-point
    "ml" 'targets-read-target-at-point
    "mp" 'source-packages-file
    ;; Fnmate
    "ff" 'fnmate
    ;; REPL
    "i" 'ess-interrupt
    "o" 'ess-eval-word
    "e" 'ess-eval-paragraph-and-step
    ;; R Markdown
    "kc" 'polymode-eval-chunk
    "kr" 'tide-rmd-rend
    "kd" 'tide-draft-rmd
    ;; Style
    "cs" 'tide-save-and-style-file
    ;; Shiny
    "Sr" 'tide-shiny-run-app
    ))

(defun spacemacs//ess-bind-repl-keys-for-mode (mode)
  "Set the REPL keys in MODE."
  (spacemacs/declare-prefix-for-mode mode "ms" "repl")
  (spacemacs/set-leader-keys-for-major-mode mode
    ","  #'ess-eval-region-or-function-or-paragraph-and-step
    "'"  #'spacemacs/ess-start-repl
    "si" #'spacemacs/ess-start-repl
    "ss" #'ess-switch-to-inferior-or-script-buffer
    "sS" #'ess-switch-process
    "sB" #'ess-eval-buffer-and-go
    "sb" #'ess-eval-buffer
    "sd" #'ess-eval-region-or-line-and-step
    "sD" #'ess-eval-function-or-paragraph-and-step
    "sL" #'ess-eval-line-and-go
    "sl" #'ess-eval-line
    "sQ" #'ess-quit
    "sR" #'ess-eval-region-and-go
    "sr" #'ess-eval-region
    "sF" #'ess-eval-function-and-go
    "sf" #'ess-eval-function))

(defun spacemacs/ess-bind-keys-for-julia ()
  (spacemacs//ess-bind-keys-for-mode 'ess-julia-mode)
  (spacemacs//ess-bind-repl-keys-for-mode 'ess-julia-mode))

(defun spacemacs/ess-bind-keys-for-r ()
  (when ess-assign-key
    (define-key ess-r-mode-map ess-assign-key #'ess-insert-assign))

  (spacemacs//ess-bind-keys-for-mode 'ess-r-mode)
  (spacemacs//ess-bind-repl-keys-for-mode 'ess-r-mode))

(defun spacemacs/ess-bind-keys-for-inferior ()
  (define-key inferior-ess-mode-map (kbd "C-j") #'comint-next-input)
  (define-key inferior-ess-mode-map (kbd "C-k") #'comint-previous-input)
  (when ess-assign-key
    (define-key inferior-ess-r-mode-map ess-assign-key #'ess-insert-assign))

  (spacemacs/declare-prefix-for-mode 'inferior-ess-mode "ms" "repl")
  (spacemacs/declare-prefix-for-mode 'inferior-ess-mode "me" "eval")
  (spacemacs/declare-prefix-for-mode 'inferior-ess-mode "mg" "xref")
  (spacemacs/set-leader-keys-for-major-mode 'inferior-ess-mode
    ","  #'ess-smart-comma
    "ss" #'ess-switch-to-inferior-or-script-buffer))


;; REPL

(defun spacemacs/ess-start-repl ()
  "Start a REPL corresponding to the ess-language of the current buffer."
  (interactive)
  (cond
   ((string= "S" ess-language) (call-interactively 'R))
   ((string= "STA" ess-language) (call-interactively 'stata))
   ((string= "SAS" ess-language) (call-interactively 'SAS))
   ((string= "julia" ess-language) (call-interactively 'julia))))

(defun spacemacs//ess-fix-read-only-inferior-ess-mode ()
  "Fixes a bug when `comint-prompt-read-only' in non-nil.
See https://github.com/emacs-ess/ESS/issues/300"
  (setq-local comint-use-prompt-regexp nil)
  (setq-local inhibit-field-text-motion nil))
