;;; paredit.el --- minor mode for editing parentheses  -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2005--2011 Taylor R. Campbell

;; Author: Taylor R. Campbell
;; Version: 23 (beta)
;; Created: 2005-07-31
;; Keywords: lisp

;; NOTE:  THIS IS A BETA VERSION OF PAREDIT.  USE AT YOUR OWN RISK.
;; THIS FILE IS SUBJECT TO CHANGE, AND NOT SUITABLE FOR DISTRIBUTION
;; BY PACKAGE MANAGERS SUCH AS APT, PKGSRC, MACPORTS, &C.

;; Paredit is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Paredit is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with paredit.  If not, see <http://www.gnu.org/licenses/>.

;;; This file is permanently stored at
;;;   <http://mumble.net/~campbell/emacs/paredit-23.el>.
;;;
;;; The currently released version of paredit is available at
;;;   <http://mumble.net/~campbell/emacs/paredit.el>.
;;;
;;; The latest beta version of paredit is available at
;;;   <http://mumble.net/~campbell/emacs/paredit-beta.el>.
;;;
;;; Release notes are available at
;;;   <http://mumble.net/~campbell/emacs/paredit.release>.

;;; Install paredit by placing `paredit.el' in `/path/to/elisp', a
;;; directory of your choice, and adding to your .emacs file:
;;;
;;;   (add-to-list 'load-path "/path/to/elisp")
;;;   (autoload 'enable-paredit-mode "paredit"
;;;     "Turn on pseudo-structural editing of Lisp code."
;;;     t)
;;;
;;; Start Paredit Mode on the fly with `M-x paredit-mode RET', or
;;; always enable it in a major mode `M' (e.g., `lisp') with:
;;;
;;;   (add-hook M-mode-hook 'enable-paredit-mode)
;;;
;;; Customize paredit using `eval-after-load':
;;;
;;;   (eval-after-load 'paredit
;;;     '(progn
;;;        (define-key paredit-mode-map (kbd "ESC M-A-C-s-)")
;;;          'paredit-dwim)))
;;;
;;; Send questions, bug reports, comments, feature suggestions, &c.,
;;; via email to the author's surname at mumble.net.
;;;
;;; Paredit should run in GNU Emacs 21 or later and XEmacs 21.5 or
;;; later.
;;;
;;; *** WARNING *** IMPORTANT *** DO NOT SUBMIT BUGS BEFORE READING ***
;;;
;;; If you plan to submit a bug report, where some sequence of keys in
;;; Paredit Mode, or some sequence of paredit commands, doesn't do what
;;; you wanted, then it is helpful to isolate an example in a very
;;; small buffer, and it is **ABSOLUTELY**ESSENTIAL** that you supply,
;;; along with the sequence of keys or commands,
;;;
;;;   (1) the version of Emacs,
;;;   (2) the version of paredit.el[*], and
;;;   (3) the **COMPLETE** state of the buffer used to reproduce the
;;;       problem, including major mode, minor modes, local key
;;;       bindings, entire contents of the buffer, leading line breaks
;;;       or spaces, &c.
;;;
;;; It is often extremely difficult to reproduce problems, especially
;;; with commands such as `paredit-kill'.  If you do not supply **ALL**
;;; of this information, then it is highly probable that I cannot
;;; reproduce your problem no matter how hard I try, and the effect of
;;; submitting a bug without this information is only to waste your
;;; time and mine.  So, please, include all of the above information.
;;;
;;; [*] If you are using a beta version of paredit, be sure that you
;;;     are using the *latest* edition of the beta version, available
;;;     at <http://mumble.net/~campbell/emacs/paredit-beta.el>.  If you
;;;     are not using a beta version, then upgrade either to that or to
;;;     the latest release version; I cannot support older versions,
;;;     and I can't fathom any reason why you might be using them.  So
;;;     the answer to item (2) should be either `release' or `beta'.

;;; The paredit minor mode, Paredit Mode, binds a number of simple
;;; keys, notably `(', `)', `"', and `\', to commands that more
;;; carefully insert S-expression structures in the buffer.  The
;;; parenthesis delimiter keys (round or square) are defined to insert
;;; parenthesis pairs and move past the closing delimiter,
;;; respectively; the double-quote key is multiplexed to do both, and
;;; also to insert an escape if within a string; and backslashes prompt
;;; the user for the next character to input, because a lone backslash
;;; can break structure inadvertently.  These all have their ordinary
;;; behaviour when inside comments, and, outside comments, if truly
;;; necessary, you can insert them literally with `C-q'.
;;;
;;; The key bindings are designed so that when typing new code in
;;; Paredit Mode, you can generally use exactly the same keystrokes as
;;; you would have used without Paredit Mode.  Earlier versions of
;;; paredit.el did not conform to this, because Paredit Mode bound `)'
;;; to a command that would insert a newline.  Now `)' is bound to a
;;; command that does not insert a newline, and `M-)' is bound to the
;;; command that inserts a newline.  To revert to the former behaviour,
;;; add the following forms to an `eval-after-load' form for paredit.el
;;; in your .emacs file:
;;;
;;;   (define-key paredit-mode-map (kbd ")")
;;;     'paredit-close-round-and-newline)
;;;   (define-key paredit-mode-map (kbd "M-)")
;;;     'paredit-close-round)
;;;
;;; Paredit Mode also binds the usual keys for deleting and killing, so
;;; that they will not destroy any S-expression structure by killing or
;;; deleting only one side of a parenthesis or quote pair.  If the
;;; point is on a closing delimiter, `DEL' will move left over it; if
;;; it is on an opening delimiter, `C-d' will move right over it.  Only
;;; if the point is between a pair of delimiters will `C-d' or `DEL'
;;; delete them, and in that case it will delete both simultaneously.
;;; `M-d' and `M-DEL' kill words, but skip over any S-expression
;;; structure.  `C-k' kills from the start of the line, either to the
;;; line's end, if it contains only balanced expressions; to the first
;;; closing delimiter, if the point is within a form that ends on the
;;; line; or up to the end of the last expression that starts on the
;;; line after the point.
;;;
;;; The behaviour of the commands for deleting and killing can be
;;; overridden by passing a `C-u' prefix argument: `C-u DEL' will
;;; delete a character backward, `C-u C-d' will delete a character
;;; forward, and `C-u C-k' will kill text from the point to the end of
;;; the line, irrespective of the S-expression structure in the buffer.
;;; This can be used to fix mistakes in a buffer, but should generally
;;; be avoided.
;;;
;;; Paredit performs automatic reindentation as locally as possible, to
;;; avoid interfering with custom indentation used elsewhere in some
;;; S-expression.  Only the advanced S-expression manipulation commands
;;; automatically reindent, and only the forms that were immediately
;;; operated upon (and their subforms).
;;;
;;; This code is written for clarity, not efficiency.  It frequently
;;; walks over S-expressions redundantly.  If you have problems with
;;; the time it takes to execute some of the commands, let me know, but
;;; first be sure that what you're doing is reasonable: it is
;;; preferable to avoid immense S-expressions in code anyway.

;;; This assumes Unix-style LF line endings.

(defconst paredit-version 23)
(defconst paredit-beta-p t)

(eval-and-compile

  (defun paredit-xemacs-p ()
    ;; No idea where I got this definition from.  Edward O'Connor
    ;; (hober in #emacs) suggested the current definition.
    ;;   (and (boundp 'running-xemacs)
    ;;        running-xemacs)
    (featurep 'xemacs))

  (defun paredit-gnu-emacs-p ()
    ;++ This could probably be improved.
    (not (paredit-xemacs-p)))

  (defmacro xcond (&rest clauses)
    "Exhaustive COND.
Signal an error if no clause matches."
    `(cond ,@clauses
           (t (error "XCOND lost."))))

  (defalias 'paredit-warn (if (fboundp 'warn) 'warn 'message))

  (defvar paredit-sexp-error-type
    (with-temp-buffer
      (insert "(")
      (condition-case condition
          (backward-sexp)
        (error (if (eq (car condition) 'error)
                   (paredit-warn "%s%s%s%s%s"
                                 "Paredit is unable to discriminate"
                                 " S-expression parse errors from"
                                 " other errors. "
                                 " This may cause obscure problems. "
                                 " Please upgrade Emacs."))
               (car condition)))))

  (defmacro paredit-handle-sexp-errors (body &rest handler)
    `(condition-case ()
         ,body
       (,paredit-sexp-error-type ,@handler)))

  (put 'paredit-handle-sexp-errors 'lisp-indent-function 1)

  (defmacro paredit-ignore-sexp-errors (&rest body)
    `(paredit-handle-sexp-errors (progn ,@body)
       nil))

  (put 'paredit-ignore-sexp-errors 'lisp-indent-function 0)

  nil)

;;;; Minor Mode Definition

(defvar paredit-mode-map (make-sparse-keymap)
  "Keymap for the paredit minor mode.")

;;;###autoload
(define-minor-mode paredit-mode
  "Minor mode for pseudo-structurally editing Lisp code.
With a prefix argument, enable Paredit Mode even if there are
  imbalanced parentheses in the buffer.
Paredit behaves badly if parentheses are imbalanced, so exercise
  caution when forcing Paredit Mode to be enabled, and consider
  fixing imbalanced parentheses instead.
\\<paredit-mode-map>"
  :lighter " Paredit"
  ;; If we're enabling paredit-mode, the prefix to this code that
  ;; DEFINE-MINOR-MODE inserts will have already set PAREDIT-MODE to
  ;; true.  If this is the case, then first check the parentheses, and
  ;; if there are any imbalanced ones we must inhibit the activation of
  ;; paredit mode.  We skip the check, though, if the user supplied a
  ;; prefix argument interactively.
  (if (and paredit-mode
           (not current-prefix-arg))
      (if (not (fboundp 'check-parens))
          (paredit-warn "`check-parens' is not defined; %s"
                        "be careful of malformed S-expressions.")
          (condition-case condition
              (check-parens)
            (error (setq paredit-mode nil)
                   (signal (car condition) (cdr condition)))))))

(defun enable-paredit-mode ()
  "Turn on pseudo-structural editing of Lisp code."
  (interactive)
  (paredit-mode +1))

(defun disable-paredit-mode ()
  "Turn off pseudo-structural editing of Lisp code."
  (interactive)
  (paredit-mode -1))

(defvar paredit-backward-delete-key
  (xcond ((paredit-xemacs-p)    "BS")
         ((paredit-gnu-emacs-p) "DEL")))

(defvar paredit-forward-delete-keys
  (xcond ((paredit-xemacs-p)    '("DEL"))
         ((paredit-gnu-emacs-p) '("<delete>" "<deletechar>"))))

;;;; Paredit Keys

;;; Separating the definition and initialization of this variable
;;; simplifies the development of paredit, since re-evaluating DEFVAR
;;; forms doesn't actually do anything.

(defvar paredit-commands nil
  "List of paredit commands with their keys and examples.")

;;; Each specifier is of the form:
;;;   (key[s] function (example-input example-output) ...)
;;; where key[s] is either a single string suitable for passing to KBD
;;; or a list of such strings.  Entries in this list may also just be
;;; strings, in which case they are headings for the next entries.

(progn (setq paredit-commands
 `(
   "Basic Insertion Commands"
   ("("         paredit-open-round
                ("(a b |c d)"
                 "(a b (|) c d)")
                ("(foo \"bar |baz\" quux)"
                 "(foo \"bar (|baz\" quux)"))
   (")"         paredit-close-round
                ("(a b |c   )" "(a b c)|")
                ("; Hello,| world!"
                 "; Hello,)| world!"))
   ("M-)"       paredit-close-round-and-newline
                ("(defun f (x|  ))"
                 "(defun f (x)\n  |)")
                ("; (Foo.|"
                 "; (Foo.)|"))
   ("["         paredit-open-square
                ("(a b |c d)"
                 "(a b [|] c d)")
                ("(foo \"bar |baz\" quux)"
                 "(foo \"bar [baz\" quux)"))
   ("]"         paredit-close-square
                ("(define-key keymap [frob|  ] 'frobnicate)"
                 "(define-key keymap [frob]| 'frobnicate)")
                ("; [Bar.|"
                 "; [Bar.]|"))
   ("\""        paredit-doublequote
                ("(frob grovel |full lexical)"
                 "(frob grovel \"|\" full lexical)")
                ("(foo \"bar |baz\" quux)"
                 "(foo \"bar \\\"|baz\" quux)"))
   ("M-\""      paredit-meta-doublequote
                ("(foo \"bar |baz\" quux)"
                 "(foo \"bar baz\"\n     |quux)")
                ("(foo |(bar #\\x \"baz \\\\ quux\") zot)"
                 ,(concat "(foo \"|(bar #\\\\x \\\"baz \\\\"
                          "\\\\ quux\\\")\" zot)")))
   ("\\"        paredit-backslash
                ("(string #|)\n  ; Escaping character... (x)"
                 "(string #\\x|)")
                ("\"foo|bar\"\n  ; Escaping character... (\")"
                 "\"foo\\\"|bar\""))
   (";"         paredit-semicolon
                ("|(frob grovel)"
                 ";|(frob grovel)")
                ("(frob |grovel)"
                 "(frob ;grovel\n)")
                ("(frob |grovel (bloit\n               zargh))"
                 "(frob ;|grovel\n (bloit\n  zargh))")
                ("(frob grovel)          |"
                 "(frob grovel)          ;|"))
   ("M-;"       paredit-comment-dwim
                ("(foo |bar)   ; baz"
                 "(foo bar)                               ; |baz")
                ("(frob grovel)|"
                 "(frob grovel)                           ;|")
                ("    (foo bar)\n|\n    (baz quux)"
                 "    (foo bar)\n    ;; |\n    (baz quux)")
                ("    (foo bar) |(baz quux)"
                 "    (foo bar)\n    ;; |\n    (baz quux)")
                ("|(defun hello-world ...)"
                 ";;; |\n(defun hello-world ...)"))

   ("C-j"       paredit-newline
                ("(let ((n (frobbotz))) |(display (+ n 1)\nport))"
                 ,(concat "(let ((n (frobbotz)))"
                          "\n  |(display (+ n 1)"
                          "\n            port))")))

   "Deleting & Killing"
   (("C-d" ,@paredit-forward-delete-keys)
                paredit-forward-delete
                ("(quu|x \"zot\")" "(quu| \"zot\")")
                ("(quux |\"zot\")"
                 "(quux \"|zot\")"
                 "(quux \"|ot\")")
                ("(foo (|) bar)" "(foo | bar)")
                ("|(foo bar)" "(|foo bar)"))
   (,paredit-backward-delete-key
                paredit-backward-delete
                ("(\"zot\" q|uux)" "(\"zot\" |uux)")
                ("(\"zot\"| quux)"
                 "(\"zot|\" quux)"
                 "(\"zo|\" quux)")
                ("(foo (|) bar)" "(foo | bar)")
                ("(foo bar)|" "(foo bar|)"))
   ("C-k"       paredit-kill
                ("(foo bar)|     ; Useless comment!"
                 "(foo bar)|")
                ("(|foo bar)     ; Useful comment!"
                 "(|)     ; Useful comment!")
                ("|(foo bar)     ; Useless line!"
                 "|")
                ("(foo \"|bar baz\"\n     quux)"
                 "(foo \"|\"\n     quux)"))
   ("M-d"       paredit-forward-kill-word
                ("|(foo bar)    ; baz"
                 "(| bar)    ; baz"
                 "(|)    ; baz"
                 "()    ;|")
                (";;;| Frobnicate\n(defun frobnicate ...)"
                 ";;;|\n(defun frobnicate ...)"
                 ";;;\n(| frobnicate ...)"))
   (,(concat "M-" paredit-backward-delete-key)
                paredit-backward-kill-word
                ("(foo bar)    ; baz\n(quux)|"
                 "(foo bar)    ; baz\n(|)"
                 "(foo bar)    ; |\n()"
                 "(foo |)    ; \n()"
                 "(|)    ; \n()"))

   "Movement & Navigation"
   ("C-M-f"     paredit-forward
                ("(foo |(bar baz) quux)"
                 "(foo (bar baz)| quux)")
                ("(foo (bar)|)"
                 "(foo (bar))|"))
   ("C-M-b"     paredit-backward
                ("(foo (bar baz)| quux)"
                 "(foo |(bar baz) quux)")
                ("(|(foo) bar)"
                 "|((foo) bar)"))
   ("C-M-u"     paredit-backward-up)
   ("C-M-d"     paredit-forward-down)
   ("C-M-p"     paredit-backward-down)  ; Built-in, these are FORWARD-
   ("C-M-n"     paredit-forward-up)     ; & BACKWARD-LIST, which have
                                        ; no need given C-M-f & C-M-b.

   "Depth-Changing Commands"
   ("M-("       paredit-wrap-round
                ("(foo |bar baz)"
                 "(foo (|bar) baz)"))
   ("M-s"       paredit-splice-sexp
                ("(foo (bar| baz) quux)"
                 "(foo bar| baz quux)"))
   (("M-<up>" "ESC <up>")
                paredit-splice-sexp-killing-backward
                ("(foo (let ((x 5)) |(sqrt n)) bar)"
                 "(foo (sqrt n) bar)"))
   (("M-<down>" "ESC <down>")
                paredit-splice-sexp-killing-forward
                ("(a (b c| d e) f)"
                 "(a b c f)"))
   ("M-r"       paredit-raise-sexp
                ("(dynamic-wind in (lambda () |body) out)"
                 "(dynamic-wind in |body out)"
                 "|body"))

   "Barfage & Slurpage"
   (("C-)" "C-<right>")
                paredit-forward-slurp-sexp
                ("(foo (bar |baz) quux zot)"
                 "(foo (bar |baz quux) zot)")
                ("(a b ((c| d)) e f)"
                 "(a b ((c| d) e) f)"))
   (("C-}" "C-<left>")
                paredit-forward-barf-sexp
                ("(foo (bar |baz quux) zot)"
                 "(foo (bar |baz) quux zot)"))
   (("C-(" "C-M-<left>" "ESC C-<left>")
                paredit-backward-slurp-sexp
                ("(foo bar (baz| quux) zot)"
                 "(foo (bar baz| quux) zot)")
                ("(a b ((c| d)) e f)"
                 "(a (b (c| d)) e f)"))
   (("C-{" "C-M-<right>" "ESC C-<right>")
                paredit-backward-barf-sexp
                ("(foo (bar baz |quux) zot)"
                 "(foo bar (baz |quux) zot)"))

   "Miscellaneous Commands"
   ("M-S"       paredit-split-sexp
                ("(hello| world)"
                 "(hello)| (world)")
                ("\"Hello, |world!\""
                 "\"Hello, \"| \"world!\""))
   ("M-J"       paredit-join-sexps
                ("(hello)| (world)"
                 "(hello| world)")
                ("\"Hello, \"| \"world!\""
                 "\"Hello, |world!\"")
                ("hello-\n|  world"
                 "hello-|world"))
   ("C-c C-M-l" paredit-recentre-on-sexp)
   ("M-q"       paredit-reindent-defun)
   ))
       nil)                             ; end of PROGN

;;;;; Command Examples

(eval-and-compile
  (defmacro paredit-do-commands (vars string-case &rest body)
    (let ((spec     (nth 0 vars))
          (keys     (nth 1 vars))
          (fn       (nth 2 vars))
          (examples (nth 3 vars)))
      `(dolist (,spec paredit-commands)
         (if (stringp ,spec)
             ,string-case
           (let ((,keys (let ((k (car ,spec)))
                          (cond ((stringp k) (list k))
                                ((listp k) k)
                                (t (error "Invalid paredit command %s."
                                          ,spec)))))
                 (,fn (cadr ,spec))
                 (,examples (cddr ,spec)))
             ,@body)))))

  (put 'paredit-do-commands 'lisp-indent-function 2))

(defun paredit-define-keys ()
  (paredit-do-commands (spec keys fn examples)
      nil       ; string case
    (dolist (key keys)
      (define-key paredit-mode-map (read-kbd-macro key) fn))))

(defun paredit-function-documentation (fn)
  (let ((original-doc (get fn 'paredit-original-documentation))
        (doc (documentation fn 'function-documentation)))
    (or original-doc
        (progn (put fn 'paredit-original-documentation doc)
               doc))))

(defun paredit-annotate-mode-with-examples ()
  (let ((contents
         (list (paredit-function-documentation 'paredit-mode))))
    (paredit-do-commands (spec keys fn examples)
        (push (concat "\n\n" spec "\n")
              contents)
      (let ((name (symbol-name fn)))
        (if (string-match (symbol-name 'paredit-) name)
            (push (concat "\n\n\\[" name "]\t" name
                          (if examples
                              (mapconcat (lambda (example)
                                           (concat
                                            "\n"
                                            (mapconcat 'identity
                                                       example
                                                       "\n  --->\n")
                                            "\n"))
                                         examples
                                         "")
                              "\n  (no examples)\n"))
                  contents))))
    (put 'paredit-mode 'function-documentation
         (apply 'concat (reverse contents))))
  ;; PUT returns the huge string we just constructed, which we don't
  ;; want it to return.
  nil)

(defun paredit-annotate-functions-with-examples ()
  (paredit-do-commands (spec keys fn examples)
      nil       ; string case
    (put fn 'function-documentation
         (concat (paredit-function-documentation fn)
                 "\n\n\\<paredit-mode-map>\\[" (symbol-name fn) "]\n"
                 (mapconcat (lambda (example)
                              (concat "\n"
                                      (mapconcat 'identity
                                                 example
                                                 "\n  ->\n")
                                      "\n"))
                            examples
                            "")))))

;;;;; HTML Examples

(defun paredit-insert-html-examples ()
  "Insert HTML for a paredit quick reference table."
  (interactive)
  (let ((insert-lines
         (lambda (&rest lines)
           (mapc (lambda (line) (insert line) (newline))
                 lines)))
        (html-keys
         (lambda (keys)
           (mapconcat 'paredit-html-quote keys ", ")))
        (html-example
         (lambda (example)
           (concat "<table><tr><td><pre>"
                   (mapconcat 'paredit-html-quote
                              example
                              (concat "</pre></td></tr><tr><td>"
                                      "&nbsp;&nbsp;&nbsp;&nbsp;---&gt;"
                                      "</td></tr><tr><td><pre>"))
                   "</pre></td></tr></table>")))
        (firstp t))
    (paredit-do-commands (spec keys fn examples)
        (progn (if (not firstp)
                   (insert "</table>\n")
                   (setq firstp nil))
               (funcall insert-lines
                        (concat "<h3>" spec "</h3>")
                        "<table border=\"1\" cellpadding=\"1\">"
                        "  <tr>"
                        "    <th>Command</th>"
                        "    <th>Keys</th>"
                        "    <th>Examples</th>"
                        "  </tr>"))
      (let ((name (symbol-name fn)))
        (if (string-match (symbol-name 'paredit-) name)
            (funcall insert-lines
                     "  <tr>"
                     (concat "    <td><tt>" name "</tt></td>")
                     (concat "    <td align=\"center\">"
                             (funcall html-keys keys)
                             "</td>")
                     (concat "    <td>"
                             (if examples
                                 (mapconcat html-example examples
                                            "<hr>")
                                 "(no examples)")
                             "</td>")
                     "  </tr>")))))
  (insert "</table>\n"))

(defun paredit-html-quote (string)
  (with-temp-buffer
    (dotimes (i (length string))
      (insert (let ((c (elt string i)))
                (cond ((eq c ?\<) "&lt;")
                      ((eq c ?\>) "&gt;")
                      ((eq c ?\&) "&amp;")
                      ((eq c ?\') "&apos;")
                      ((eq c ?\") "&quot;")
                      (t c)))))
    (buffer-string)))

;;;; Delimiter Insertion

(eval-and-compile
  (defun paredit-conc-name (&rest strings)
    (intern (apply 'concat strings)))

  (defmacro define-paredit-pair (open close name)
    `(progn
       (defun ,(paredit-conc-name "paredit-open-" name) (&optional n)
         ,(concat "Insert a balanced " name " pair.
With a prefix argument N, put the closing " name " after N
  S-expressions forward.
If the region is active, `transient-mark-mode' is enabled, and the
  region's start and end fall in the same parenthesis depth, insert a
  " name " pair around the region.
If in a string or a comment, insert a single " name ".
If in a character literal, do nothing.  This prevents changing what was
  in the character literal to a meaningful delimiter unintentionally.")
         (interactive "P")
         (cond ((or (paredit-in-string-p)
                    (paredit-in-comment-p))
                (insert ,open))
               ((not (paredit-in-char-p))
                (paredit-insert-pair n ,open ,close 'goto-char))))
       (defun ,(paredit-conc-name "paredit-close-" name) ()
         ,(concat "Move past one closing delimiter and reindent.
\(Agnostic to the specific closing delimiter.)
If in a string or comment, insert a single closing " name ".
If in a character literal, do nothing.  This prevents changing what was
  in the character literal to a meaningful delimiter unintentionally.")
         (interactive)
         (paredit-move-past-close ,close))
       (defun ,(paredit-conc-name "paredit-close-" name "-and-newline") ()
         ,(concat "Move past one closing delimiter, add a newline,"
                  " and reindent.
If there was a margin comment after the closing delimiter, preserve it
  on the same line.")
         (interactive)
         (paredit-move-past-close-and-newline ,close))
       (defun ,(paredit-conc-name "paredit-wrap-" name)
           (&optional argument)
         ,(concat "Wrap the following S-expression.
See `paredit-wrap-sexp' for more details.")
         (interactive "P")
         (paredit-wrap-sexp argument ,open ,close))
       (add-to-list 'paredit-wrap-commands
                    ',(paredit-conc-name "paredit-wrap-" name)))))

(defvar paredit-wrap-commands '(paredit-wrap-sexp)
  "List of paredit commands that wrap S-expressions.
Used by `paredit-yank-pop'; for internal paredit use only.")

(define-paredit-pair ?\( ?\) "round")
(define-paredit-pair ?\[ ?\] "square")
(define-paredit-pair ?\{ ?\} "curly")
(define-paredit-pair ?\< ?\> "angled")

;;; Aliases for the old names.

(defalias 'paredit-open-parenthesis 'paredit-open-round)
(defalias 'paredit-close-parenthesis 'paredit-close-round)
(defalias 'paredit-close-parenthesis-and-newline
  'paredit-close-round-and-newline)

(defalias 'paredit-open-bracket 'paredit-open-square)
(defalias 'paredit-close-bracket 'paredit-close-square)
(defalias 'paredit-close-bracket-and-newline
  'paredit-close-square-and-newline)

(defun paredit-move-past-close (close)
  (cond ((or (paredit-in-string-p)
             (paredit-in-comment-p))
         (insert close))
        ((not (paredit-in-char-p))
         (paredit-move-past-close-and-reindent close)
         (paredit-blink-paren-match nil))))

(defun paredit-move-past-close-and-newline (close)
  (if (or (paredit-in-string-p)
          (paredit-in-comment-p))
      (insert close)
    (if (paredit-in-char-p) (forward-char))
    (paredit-move-past-close-and-reindent close)
    (let ((comment.point (paredit-find-comment-on-line)))
      (newline)
      (if comment.point
          (save-excursion
            (forward-line -1)
            (end-of-line)
            (indent-to (cdr comment.point))
            (insert (car comment.point)))))
    (lisp-indent-line)
    (paredit-ignore-sexp-errors (indent-sexp))
    (paredit-blink-paren-match t)))

(defun paredit-find-comment-on-line ()
  "Find a margin comment on the current line.
Return nil if there is no such comment or if there is anything but
  whitespace until such a comment.
If such a comment exists, delete the comment (including all leading
  whitespace) and return a cons whose car is the comment as a string
  and whose cdr is the point of the comment's initial semicolon,
  relative to the start of the line."
  (save-excursion
    (paredit-skip-whitespace t (point-at-eol))
    (and (eq ?\; (char-after))
         (not (eq ?\; (char-after (1+ (point)))))
         (not (or (paredit-in-string-p)
                  (paredit-in-char-p)))
         (let* ((start                  ;Move to before the semicolon.
                 (progn (backward-char) (point)))
                (comment
                 (buffer-substring start (point-at-eol))))
           (paredit-skip-whitespace nil (point-at-bol))
           (delete-region (point) (point-at-eol))
           (cons comment (- start (point-at-bol)))))))

(defun paredit-insert-pair (n open close forward)
  (let* ((regionp
          (and (paredit-region-active-p)
               (paredit-region-safe-for-insert-p)))
         (end
          (and regionp
               (not n)
               (prog1 (region-end) (goto-char (region-beginning))))))
    (let ((spacep (paredit-space-for-delimiter-p nil open)))
      (if spacep (insert " "))
      (insert open)
      (save-excursion
        ;; Move past the desired region.
        (cond (n (funcall forward
                          (save-excursion
                            (forward-sexp (prefix-numeric-value n))
                            (point))))
              (regionp (funcall forward (+ end (if spacep 2 1)))))
        (insert close)
        (if (paredit-space-for-delimiter-p t close)
            (insert " "))))))

(defun paredit-region-safe-for-insert-p ()
  (save-excursion
    (let ((beginning (region-beginning))
          (end (region-end)))
      (goto-char beginning)
      (let* ((beginning-state (paredit-current-parse-state))
             (end-state
              (parse-partial-sexp beginning end nil nil beginning-state)))
        (and (=  (nth 0 beginning-state)   ; 0. depth in parens
                 (nth 0 end-state))
             (eq (nth 3 beginning-state)   ; 3. non-nil if inside a
                 (nth 3 end-state))        ;    string
             (eq (nth 4 beginning-state)   ; 4. comment status, yada
                 (nth 4 end-state))
             (eq (nth 5 beginning-state)   ; 5. t if following char
                 (nth 5 end-state)))))))   ;    quote

(defvar paredit-space-for-delimiter-predicates nil
  "List of predicates for whether to put space by delimiter at point.
Each predicate is a function that is is applied to two arguments, ENDP
  and DELIMITER, and that returns a boolean saying whether to put a
  space next to the delimiter -- before the delimiter if ENDP is false,
  after the delimiter if ENDP is true.
If any predicate returns false, no space is inserted: every predicate
  has veto power.
Each predicate may assume that the point is not at the beginning of the
  buffer, if ENDP is false, or at the end of the buffer, if ENDP is
  true; and that the point is not preceded, if ENDP is false, or
  followed, if ENDP is true, by a word or symbol constituent, a quote,
  or the delimiter matching DELIMITER.
Each predicate should examine only text before the point, if ENDP is
  false, or only text after the point, if ENDP is true.")

(defun paredit-space-for-delimiter-p (endp delimiter)
  ;; If at the buffer limit, don't insert a space.  If there is a word,
  ;; symbol, other quote, or non-matching parenthesis delimiter (i.e. a
  ;; close when want an open the string or an open when we want to
  ;; close the string), do insert a space.
  (and (not (if endp (eobp) (bobp)))
       (memq (char-syntax (if endp (char-after) (char-before)))
             (list ?w ?_ ?\"
                   (let ((matching (matching-paren delimiter)))
                     (and matching (char-syntax matching)))
                   (and (not endp)
                        (eq ?\" (char-syntax delimiter))
                        ?\) )))
       (catch 'exit
         (dolist (predicate paredit-space-for-delimiter-predicates)
           (if (not (funcall predicate endp delimiter))
               (throw 'exit nil)))
         t)))

(defun paredit-move-past-close-and-reindent (close)
  (let ((open (paredit-missing-close)))
    (if open
        (if (eq close (matching-paren open))
            (save-excursion
              (message "Missing closing delimiter: %c" close)
              (insert close))
            (error "Mismatched missing closing delimiter: %c ... %c"
                   open close))))
  (up-list)
  (if (catch 'return                    ; This CATCH returns T if it
        (while t                        ; should delete leading spaces
          (save-excursion               ; and NIL if not.
            (let ((before-paren (1- (point))))
              (back-to-indentation)
              (cond ((not (eq (point) before-paren))
                     ;; Can't call PAREDIT-DELETE-LEADING-WHITESPACE
                     ;; here -- we must return from SAVE-EXCURSION
                     ;; first.
                     (throw 'return t))
                    ((save-excursion (forward-line -1)
                                     (end-of-line)
                                     (paredit-in-comment-p))
                     ;; Moving the closing delimiter any further
                     ;; would put it into a comment, so we just
                     ;; indent the closing delimiter where it is and
                     ;; abort the loop, telling its continuation that
                     ;; no leading whitespace should be deleted.
                     (lisp-indent-line)
                     (throw 'return nil))
                    (t (delete-indentation)))))))
      (paredit-delete-leading-whitespace)))

(defun paredit-missing-close ()
  (save-excursion
    (paredit-handle-sexp-errors (backward-up-list)
      (error "Not inside a list."))
    (let ((open (char-after)))
      (paredit-handle-sexp-errors (progn (forward-sexp) nil)
        open))))

(defun paredit-delete-leading-whitespace ()
  ;; This assumes that we're on the closing delimiter already.
  (save-excursion
    (backward-char)
    (while (let ((syn (char-syntax (char-before))))
             (and (or (eq syn ?\ ) (eq syn ?-))     ; whitespace syntax
                  ;; The above line is a perfect example of why the
                  ;; following test is necessary.
                  (not (paredit-in-char-p (1- (point))))))
      (backward-delete-char 1))))

(defun paredit-blink-paren-match (another-line-p)
  (if (and blink-matching-paren
           (or (not show-paren-mode) another-line-p))
      (paredit-ignore-sexp-errors
        (save-excursion
          (backward-sexp)
          (forward-sexp)
          ;; SHOW-PAREN-MODE inhibits any blinking, so we disable it
          ;; locally here.
          (let ((show-paren-mode nil))
            (blink-matching-open))))))

(defun paredit-doublequote (&optional n)
  "Insert a pair of double-quotes.
With a prefix argument N, wrap the following N S-expressions in
  double-quotes, escaping intermediate characters if necessary.
If the region is active, `transient-mark-mode' is enabled, and the
  region's start and end fall in the same parenthesis depth, insert a
  pair of double-quotes around the region, again escaping intermediate
  characters if necessary.
Inside a comment, insert a literal double-quote.
At the end of a string, move past the closing double-quote.
In the middle of a string, insert a backslash-escaped double-quote.
If in a character literal, do nothing.  This prevents accidentally
  changing a what was in the character literal to become a meaningful
  delimiter unintentionally."
  (interactive "P")
  (cond ((paredit-in-string-p)
         (if (eq (cdr (paredit-string-start+end-points))
                 (point))
             (forward-char)             ; We're on the closing quote.
             (insert ?\\ ?\" )))
        ((paredit-in-comment-p)
         (insert ?\" ))
        ((not (paredit-in-char-p))
         (paredit-insert-pair n ?\" ?\" 'paredit-forward-for-quote))))

(defun paredit-meta-doublequote (&optional n)
  "Move to the end of the string, insert a newline, and indent.
If not in a string, act as `paredit-doublequote'; if no prefix argument
  is specified and the region is not active or `transient-mark-mode' is
  disabled, the default is to wrap one S-expression, however, not
  zero."
  (interactive "P")
  (if (not (paredit-in-string-p))
      (paredit-doublequote (or n
                               (and (not (paredit-region-active-p))
                                    1)))
    (let ((start+end (paredit-string-start+end-points)))
      (goto-char (1+ (cdr start+end)))
      (newline)
      (lisp-indent-line)
      (paredit-ignore-sexp-errors (indent-sexp)))))

(defun paredit-forward-for-quote (end)
  (let ((state (paredit-current-parse-state)))
    (while (< (point) end)
      (let ((new-state (parse-partial-sexp (point) (1+ (point))
                                           nil nil state)))
        (if (paredit-in-string-p new-state)
            (if (not (paredit-in-string-escape-p))
                (setq state new-state)
              ;; Escape character: turn it into an escaped escape
              ;; character by appending another backslash.
              (insert ?\\ )
              ;; Now the point is after both escapes, and we want to
              ;; rescan from before the first one to after the second
              ;; one.
              (setq state
                    (parse-partial-sexp (- (point) 2) (point)
                                        nil nil state))
              ;; Advance the end point, since we just inserted a new
              ;; character.
              (setq end (1+ end)))
          ;; String: escape by inserting a backslash before the quote.
          (backward-char)
          (insert ?\\ )
          ;; The point is now between the escape and the quote, and we
          ;; want to rescan from before the escape to after the quote.
          (setq state
                (parse-partial-sexp (1- (point)) (1+ (point))
                                    nil nil state))
          ;; Advance the end point for the same reason as above.
          (setq end (1+ end)))))))

;;;; Escape Insertion

(defun paredit-backslash ()
  "Insert a backslash followed by a character to escape."
  (interactive)
  (insert ?\\ )
  ;; This funny conditional is necessary because PAREDIT-IN-COMMENT-P
  ;; assumes that PAREDIT-IN-STRING-P already returned false; otherwise
  ;; it may give erroneous answers.
  (if (or (paredit-in-string-p)
          (not (paredit-in-comment-p)))
      (let ((delp t))
        (unwind-protect (setq delp
                              (call-interactively 'paredit-escape))
          ;; We need this in an UNWIND-PROTECT so that the backlash is
          ;; left in there *only* if PAREDIT-ESCAPE return NIL normally
          ;; -- in any other case, such as the user hitting C-g or an
          ;; error occurring, we must delete the backslash to avoid
          ;; leaving a dangling escape.  (This control structure is a
          ;; crock.)
          (if delp (backward-delete-char 1))))))

;;; This auxiliary interactive function returns true if the backslash
;;; should be deleted and false if not.

(defun paredit-escape (char)
  ;; I'm too lazy to figure out how to do this without a separate
  ;; interactive function.
  (interactive "cEscaping character...")
  (if (eq char 127)                     ; The backslash was a typo, so
      t                                 ; the luser wants to delete it.
    (insert char)                       ; (Is there a better way to
    nil))                               ; express the rubout char?
                                        ; ?\^? works, but ugh...)

(defun paredit-newline ()
  "Insert a newline and indent it.
This is like `newline-and-indent', but it not only indents the line
  that the point is on but also the S-expression following the point,
  if there is one.
Move forward one character first if on an escaped character.
If in a string, just insert a literal newline.
If in a comment and if followed by invalid structure, call
  `indent-new-comment-line' to keep the invalid structure in a
  comment."
  (interactive)
  (cond ((paredit-in-string-p)
         (newline))
        ((paredit-in-comment-p)
         (if (paredit-region-ok-p (point) (point-at-eol))
             (progn (newline-and-indent)
                    (paredit-ignore-sexp-errors (indent-sexp)))
             (indent-new-comment-line)))
        (t
         (if (paredit-in-char-p)
             (forward-char))
         (newline-and-indent)
         ;; Indent the following S-expression, but don't signal an
         ;; error if there's only a closing delimiter after the point.
         (paredit-ignore-sexp-errors (indent-sexp)))))

(defun paredit-reindent-defun (&optional argument)
  "Reindent the definition that the point is on.
If the point is in a string or a comment, fill the paragraph instead,
  and with a prefix argument, justify as well."
  (interactive "P")
  (if (or (paredit-in-string-p)
          (paredit-in-comment-p))
      (fill-paragraph argument)
    (save-excursion
      (end-of-defun)
      (beginning-of-defun)
      (indent-sexp))))

;;;; Comment Insertion

(defun paredit-semicolon (&optional n)
  "Insert a semicolon.
With a prefix argument N, insert N semicolons.
If in a string, do just that and nothing else.
If in a character literal, move to the beginning of the character
  literal before inserting the semicolon.
If the enclosing list ends on the line after the point, break the line
  after the last S-expression following the point.
If a list begins on the line after the point but ends on a different
  line, break the line after the last S-expression following the point
  before the list."
  (interactive "p")
  (if (or (paredit-in-string-p) (paredit-in-comment-p))
      (insert (make-string (or n 1) ?\; ))
    (if (paredit-in-char-p)
        (backward-char 2))
    (let ((line-break-point (paredit-semicolon-find-line-break-point)))
      (if line-break-point
          (paredit-semicolon-with-line-break line-break-point (or n 1))
          (insert (make-string (or n 1) ?\; ))))))

(defun paredit-semicolon-find-line-break-point ()
  (let ((line-break-point nil)
        (eol (point-at-eol)))
    (and (save-excursion
           (paredit-handle-sexp-errors
               (progn
                 (while
                     (progn
                       (setq line-break-point (point))
                       (forward-sexp)
                       (and (eq eol (point-at-eol))
                            (not (eobp)))))
                 (backward-sexp)
                 (eq eol (point-at-eol)))
             ;; If we hit the end of an expression, but the closing
             ;; delimiter is on another line, don't break the line.
             (save-excursion
               (paredit-skip-whitespace t (point-at-eol))
               (not (or (eolp) (eq (char-after) ?\; ))))))
         line-break-point)))

(defun paredit-semicolon-with-line-break (line-break-point n)
  (let ((line-break-marker (make-marker)))
    (set-marker line-break-marker line-break-point)
    (set-marker-insertion-type line-break-marker t)
    (insert (make-string (or n 1) ?\; ))
    (save-excursion
      (goto-char line-break-marker)
      (set-marker line-break-marker nil)
      (newline)
      (lisp-indent-line)
      ;; This step is redundant if we are inside a list, but even if we
      ;; are at the top level, we want at least to indent whatever we
      ;; bumped off the line.
      (paredit-ignore-sexp-errors (indent-sexp))
      (paredit-indent-sexps))))

;;; This is all a horrible, horrible hack, primarily for GNU Emacs 21,
;;; in which there is no `comment-or-uncomment-region'.

(autoload 'comment-forward "newcomment")
(autoload 'comment-normalize-vars "newcomment")
(autoload 'comment-region "newcomment")
(autoload 'comment-search-forward "newcomment")
(autoload 'uncomment-region "newcomment")

(defun paredit-initialize-comment-dwim ()
  (require 'newcomment)
  (if (not (fboundp 'comment-or-uncomment-region))
      (defalias 'comment-or-uncomment-region
        (lambda (beginning end &optional argument)
          (interactive "*r\nP")
          (if (save-excursion (goto-char beginning)
                              (comment-forward (point-max))
                              (<= end (point)))
              (uncomment-region beginning end argument)
              (comment-region beginning end argument)))))
  (defalias 'paredit-initialize-comment-dwim 'comment-normalize-vars)
  (comment-normalize-vars))

(defun paredit-comment-dwim (&optional argument)
  "Call the Lisp comment command you want (Do What I Mean).
This is like `comment-dwim', but it is specialized for Lisp editing.
If transient mark mode is enabled and the mark is active, comment or
  uncomment the selected region, depending on whether it was entirely
  commented not not already.
If there is already a comment on the current line, with no prefix
  argument, indent to that comment; with a prefix argument, kill that
  comment.
Otherwise, insert a comment appropriate for the context and ensure that
  any code following the comment is moved to the next line.
At the top level, where indentation is calculated to be at column 0,
  insert a triple-semicolon comment; within code, where the indentation
  is calculated to be non-zero, and on the line there is either no code
  at all or code after the point, insert a double-semicolon comment;
  and if the point is after all code on the line, insert a single-
  semicolon margin comment at `comment-column'."
  (interactive "*P")
  (paredit-initialize-comment-dwim)
  (cond ((paredit-region-active-p)
         (comment-or-uncomment-region (region-beginning)
                                      (region-end)
                                      argument))
        ((paredit-comment-on-line-p)
         (if argument
             (comment-kill (if (integerp argument) argument nil))
             (comment-indent)))
        (t (paredit-insert-comment))))

(defun paredit-comment-on-line-p ()
  "True if there is a comment on the line following point.
This is expected to be called only in `paredit-comment-dwim'; do not
  call it elsewhere."
  (save-excursion
    (beginning-of-line)
    (let ((comment-p nil))
      ;; Search forward for a comment beginning.  If there is one, set
      ;; COMMENT-P to true; if not, it will be nil.
      (while (progn
               (setq comment-p          ;t -> no error
                     (comment-search-forward (point-at-eol) t))
               (and comment-p
                    (or (paredit-in-string-p)
                        (paredit-in-char-p (1- (point))))))
        (forward-char))
      comment-p)))

(defun paredit-insert-comment ()
  (let ((code-after-p
         (save-excursion (paredit-skip-whitespace t (point-at-eol))
                         (not (eolp))))
        (code-before-p
         (save-excursion (paredit-skip-whitespace nil (point-at-bol))
                         (not (bolp)))))
    (cond ((and (bolp)
                (let ((indent
                       (let ((indent (calculate-lisp-indent)))
                         (if (consp indent) (car indent) indent))))
                  (and indent (zerop indent))))
           ;; Top-level comment
           (if code-after-p (save-excursion (newline)))
           (insert ";;; "))
          ((or code-after-p (not code-before-p))
           ;; Code comment
           (if code-before-p (newline))
           (lisp-indent-line)
           (insert ";; ")
           (if code-after-p
               (save-excursion
                 (newline)
                 (lisp-indent-line)
                 (paredit-indent-sexps))))
          (t
           ;; Margin comment
           (indent-to comment-column 1) ; 1 -> force one leading space
           (insert ?\; )))))

;;;; Character Deletion

(defun paredit-forward-delete (&optional argument)
  "Delete a character forward or move forward over a delimiter.
If on an opening S-expression delimiter, move forward into the
  S-expression.
If on a closing S-expression delimiter, refuse to delete unless the
  S-expression is empty, in which case delete the whole S-expression.
With a numeric prefix argument N, delete N characters forward.
With a `C-u' prefix argument, simply delete a character forward,
  without regard for delimiter balancing."
  (interactive "P")
  (cond ((or (consp argument) (eobp))
         (delete-char 1))
        ((integerp argument)
         (if (< argument 0)
             (paredit-backward-delete argument)
             (while (> argument 0)
               (paredit-forward-delete)
               (setq argument (- argument 1)))))
        ((paredit-in-string-p)
         (paredit-forward-delete-in-string))
        ((paredit-in-comment-p)
         ;++ What to do here?  This could move a partial S-expression
         ;++ into a comment and thereby invalidate the file's form,
         ;++ or move random text out of a comment.
         (delete-char 1))
        ((paredit-in-char-p)            ; Escape -- delete both chars.
         (backward-delete-char 1)
         (delete-char 1))
        ((eq (char-after) ?\\ )         ; ditto
         (delete-char 2))
        ((let ((syn (char-syntax (char-after))))
           (or (eq syn ?\( )
               (eq syn ?\" )))
         (if (save-excursion
               (paredit-handle-sexp-errors (progn (forward-sexp) t)
                 nil))
             (forward-char)
           (message "Deleting spurious opening delimiter.")
           (delete-char 1)))
        ((and (not (paredit-in-char-p (1- (point))))
              (eq (char-syntax (char-after)) ?\) )
              (eq (char-before) (matching-paren (char-after))))
         (backward-delete-char 1)       ; Empty list -- delete both
         (delete-char 1))               ;   delimiters.
        ;; Just delete a single character, if it's not a closing
        ;; delimiter.  (The character literal case is already handled
        ;; by now.)
        ((not (eq (char-syntax (char-after)) ?\) ))
         (delete-char 1))))

(defun paredit-forward-delete-in-string ()
  (let ((start+end (paredit-string-start+end-points)))
    (cond ((not (eq (point) (cdr start+end)))
           ;; If it's not the close-quote, it's safe to delete.  But
           ;; first handle the case that we're in a string escape.
           (cond ((paredit-in-string-escape-p)
                  ;; We're right after the backslash, so backward
                  ;; delete it before deleting the escaped character.
                  (backward-delete-char 1))
                 ((eq (char-after) ?\\ )
                  ;; If we're not in a string escape, but we are on a
                  ;; backslash, it must start the escape for the next
                  ;; character, so delete the backslash before deleting
                  ;; the next character.
                  (delete-char 1)))
           (delete-char 1))
          ((eq (1- (point)) (car start+end))
           ;; If it is the close-quote, delete only if we're also right
           ;; past the open-quote (i.e. it's empty), and then delete
           ;; both quotes.  Otherwise we refuse to delete it.
           (backward-delete-char 1)
           (delete-char 1)))))

(defun paredit-backward-delete (&optional argument)
  "Delete a character backward or move backward over a delimiter.
If on a closing S-expression delimiter, move backward into the
  S-expression.
If on an opening S-expression delimiter, refuse to delete unless the
  S-expression is empty, in which case delete the whole S-expression.
With a numeric prefix argument N, delete N characters backward.
With a `C-u' prefix argument, simply delete a character backward,
  without regard for delimiter balancing."
  (interactive "P")
  (cond ((or (consp argument) (bobp))
         ;++ Should this untabify?
         (backward-delete-char 1))
        ((integerp argument)
         (if (< argument 0)
             (paredit-forward-delete (- 0 argument))
             (while (> argument 0)
               (paredit-backward-delete)
               (setq argument (- argument 1)))))
        ((paredit-in-string-p)
         (paredit-backward-delete-in-string))
        ((paredit-in-comment-p)
         (backward-delete-char 1))
        ((paredit-in-char-p)            ; Escape -- delete both chars.
         (backward-delete-char 1)
         (delete-char 1))
        ((paredit-in-char-p (1- (point)))
         (backward-delete-char 2))      ; ditto
        ((let ((syn (char-syntax (char-before))))
           (or (eq syn ?\) )
               (eq syn ?\" )))
         (if (save-excursion
               (paredit-handle-sexp-errors (progn (backward-sexp) t)
                 nil))
             (backward-char)
           (message "Deleting spurious closing delimiter.")
           (backward-delete-char 1)))
        ((and (eq (char-syntax (char-before)) ?\( )
              (eq (char-after) (matching-paren (char-before))))
         (backward-delete-char 1)       ; Empty list -- delete both
         (delete-char 1))               ;   delimiters.
        ;; Delete it, unless it's an opening delimiter.  The case of
        ;; character literals is already handled by now.
        ((not (eq (char-syntax (char-before)) ?\( ))
         (backward-delete-char-untabify 1))))

(defun paredit-backward-delete-in-string ()
  (let ((start+end (paredit-string-start+end-points)))
    (cond ((not (eq (1- (point)) (car start+end)))
           ;; If it's not the open-quote, it's safe to delete.
           (if (paredit-in-string-escape-p)
               ;; If we're on a string escape, since we're about to
               ;; delete the backslash, we must first delete the
               ;; escaped char.
               (delete-char 1))
           (backward-delete-char 1)
           (if (paredit-in-string-escape-p)
               ;; If, after deleting a character, we find ourselves in
               ;; a string escape, we must have deleted the escaped
               ;; character, and the backslash is behind the point, so
               ;; backward delete it.
               (backward-delete-char 1)))
          ((eq (point) (cdr start+end))
           ;; If it is the open-quote, delete only if we're also right
           ;; past the close-quote (i.e. it's empty), and then delete
           ;; both quotes.  Otherwise we refuse to delete it.
           (backward-delete-char 1)
           (delete-char 1)))))

;;;; Killing

(defun paredit-kill (&optional argument)
  "Kill a line as if with `kill-line', but respecting delimiters.
In a string, act exactly as `kill-line' but do not kill past the
  closing string delimiter.
On a line with no S-expressions on it starting after the point or
  within a comment, act exactly as `kill-line'.
Otherwise, kill all S-expressions that start after the point.
With a `C-u' prefix argument, just do the standard `kill-line'.
With a numeric prefix argument N, do `kill-line' that many times."
  (interactive "P")
  (cond (argument
         (kill-line (if (integerp argument) argument 1)))
        ((paredit-in-string-p)
         (paredit-kill-line-in-string))
        ((paredit-in-comment-p)
         (kill-line))
        ((save-excursion (paredit-skip-whitespace t (point-at-eol))
                         (or (eolp) (eq (char-after) ?\; )))
         ;** Be careful about trailing backslashes.
         (if (paredit-in-char-p)
             (backward-char))
         (kill-line))
        (t (paredit-kill-sexps-on-line))))

(defun paredit-kill-line-in-string ()
  (if (save-excursion (paredit-skip-whitespace t (point-at-eol))
                      (eolp))
      (kill-line)
    (save-excursion
      ;; Be careful not to split an escape sequence.
      (if (paredit-in-string-escape-p)
          (backward-char))
      (kill-region (point)
                   (min (point-at-eol)
                        (cdr (paredit-string-start+end-points)))))))

(defun paredit-kill-sexps-on-line ()
  (if (paredit-in-char-p)               ; Move past the \ and prefix.
      (backward-char 2))                ; (# in Scheme/CL, ? in elisp)
  (let ((beginning (point))
        (eol (point-at-eol)))
    (let ((end-of-list-p (paredit-forward-sexps-to-kill beginning eol)))
      ;; If we got to the end of the list and it's on the same line,
      ;; move backward past the closing delimiter before killing.  (This
      ;; allows something like killing the whitespace in (    ).)
      (if end-of-list-p (progn (up-list) (backward-char)))
      (if kill-whole-line
          (paredit-kill-sexps-on-whole-line beginning)
        (kill-region beginning
                     ;; If all of the S-expressions were on one line,
                     ;; i.e. we're still on that line after moving past
                     ;; the last one, kill the whole line, including
                     ;; any comments; otherwise just kill to the end of
                     ;; the last S-expression we found.  Be sure,
                     ;; though, not to kill any closing parentheses.
                     (if (and (not end-of-list-p)
                              (eq (point-at-eol) eol))
                         eol
                         (point)))))))

;;; Please do not try to understand this code unless you have a VERY
;;; good reason to do so.  I gave up trying to figure it out well
;;; enough to explain it, long ago.

(defun paredit-forward-sexps-to-kill (beginning eol)
  (let ((end-of-list-p nil)
        (firstp t))
    ;; Move to the end of the last S-expression that started on this
    ;; line, or to the closing delimiter if the last S-expression in
    ;; this list is on the line.
    (catch 'return
      (while t
        ;; This and the `kill-whole-line' business below fix a bug that
        ;; inhibited any S-expression at the very end of the buffer
        ;; (with no trailing newline) from being deleted.  It's a
        ;; bizarre fix that I ought to document at some point, but I am
        ;; too busy at the moment to do so.
        (if (and kill-whole-line (eobp)) (throw 'return nil))
        (save-excursion
          (paredit-handle-sexp-errors (forward-sexp)
            (up-list)
            (setq end-of-list-p (eq (point-at-eol) eol))
            (throw 'return nil))
          (if (or (and (not firstp)
                       (not kill-whole-line)
                       (eobp))
                  (paredit-handle-sexp-errors
                      (progn (backward-sexp) nil)
                    t)
                  (not (eq (point-at-eol) eol)))
              (throw 'return nil)))
        (forward-sexp)
        (if (and firstp
                 (not kill-whole-line)
                 (eobp))
            (throw 'return nil))
        (setq firstp nil)))
    end-of-list-p))

(defun paredit-kill-sexps-on-whole-line (beginning)
  (kill-region beginning
               (or (save-excursion     ; Delete trailing indentation...
                     (paredit-skip-whitespace t)
                     (and (not (eq (char-after) ?\; ))
                          (point)))
                   ;; ...or just use the point past the newline, if
                   ;; we encounter a comment.
                   (point-at-eol)))
  (cond ((save-excursion (paredit-skip-whitespace nil (point-at-bol))
                         (bolp))
         ;; Nothing but indentation before the point, so indent it.
         (lisp-indent-line))
        ((eobp) nil)       ; Protect the CHAR-SYNTAX below against NIL.
        ;; Insert a space to avoid invalid joining if necessary.
        ((let ((syn-before (char-syntax (char-before)))
               (syn-after  (char-syntax (char-after))))
           (or (and (eq syn-before ?\) )            ; Separate opposing
                    (eq syn-after  ?\( ))           ;   parentheses,
               (and (eq syn-before ?\" )            ; string delimiter
                    (eq syn-after  ?\" ))           ;   pairs,
               (and (memq syn-before '(?_ ?w))      ; or word or symbol
                    (memq syn-after  '(?_ ?w)))))   ;   constituents.
         (insert " "))))

;;;;; Killing Words

;;; This is tricky and asymmetrical because backward parsing is
;;; extraordinarily difficult or impossible, so we have to implement
;;; killing in both directions by parsing forward.

(defun paredit-forward-kill-word ()
  "Kill a word forward, skipping over intervening delimiters."
  (interactive)
  (let ((beginning (point)))
    (skip-syntax-forward " -")
    (let* ((parse-state (paredit-current-parse-state))
           (state (paredit-kill-word-state parse-state 'char-after)))
      (while (not (or (eobp)
                      (eq ?w (char-syntax (char-after)))))
        (setq parse-state
              (progn (forward-char 1) (paredit-current-parse-state))
;;               (parse-partial-sexp (point) (1+ (point))
;;                                   nil nil parse-state)
              )
        (let* ((old-state state)
               (new-state
                (paredit-kill-word-state parse-state 'char-after)))
          (cond ((not (eq old-state new-state))
                 (setq parse-state
                       (paredit-kill-word-hack old-state
                                               new-state
                                               parse-state))
                 (setq state
                       (paredit-kill-word-state parse-state
                                                'char-after))
                 (setq beginning (point)))))))
    (goto-char beginning)
    (kill-word 1)))

(defun paredit-backward-kill-word ()
  "Kill a word backward, skipping over any intervening delimiters."
  (interactive)
  (if (not (or (bobp)
               (eq (char-syntax (char-before)) ?w)))
      (let ((end (point)))
        (backward-word 1)
        (forward-word 1)
        (goto-char (min end (point)))
        (let* ((parse-state (paredit-current-parse-state))
               (state
                (paredit-kill-word-state parse-state 'char-before)))
          (while (and (< (point) end)
                      (progn
                        (setq parse-state
                              (parse-partial-sexp (point) (1+ (point))
                                                  nil nil parse-state))
                        (or (eq state
                                (paredit-kill-word-state parse-state
                                                         'char-before))
                            (progn (backward-char 1) nil)))))
          (if (and (eq state 'comment)
                   (eq ?\# (char-after (point)))
                   (eq ?\| (char-before (point))))
              (backward-char 1)))))
  (backward-kill-word 1))

;;;;;; Word-Killing Auxiliaries

(defun paredit-kill-word-state (parse-state adjacent-char-fn)
  (cond ((paredit-in-comment-p parse-state) 'comment)
        ((paredit-in-string-p  parse-state) 'string)
        ((memq (char-syntax (funcall adjacent-char-fn))
               '(?\( ?\) ))
         'delimiter)
        (t 'other)))

;;; This optionally advances the point past any comment delimiters that
;;; should probably not be touched, based on the last state change and
;;; the characters around the point.  It returns a new parse state,
;;; starting from the PARSE-STATE parameter.

(defun paredit-kill-word-hack (old-state new-state parse-state)
  (cond ((and (not (eq old-state 'comment))
              (not (eq new-state 'comment))
              (not (paredit-in-string-escape-p))
              (eq ?\# (char-before))
              (eq ?\| (char-after)))
         (forward-char 1)
         (paredit-current-parse-state)
;;          (parse-partial-sexp (point) (1+ (point))
;;                              nil nil parse-state)
         )
        ((and (not (eq old-state 'comment))
              (eq new-state 'comment)
              (eq ?\; (char-before)))
         (skip-chars-forward ";")
         (paredit-current-parse-state)
;;          (parse-partial-sexp (point) (save-excursion
;;                                        (skip-chars-forward ";"))
;;                              nil nil parse-state)
         )
        (t parse-state)))

(defun paredit-copy-as-kill ()
  "Save in the kill ring the region that `paredit-kill' would kill."
  (interactive)
  (cond ((paredit-in-string-p)
         (paredit-copy-as-kill-in-string))
        ((paredit-in-comment-p)
         (copy-region-as-kill (point) (point-at-eol)))
        ((save-excursion (paredit-skip-whitespace t (point-at-eol))
                         (or (eolp) (eq (char-after) ?\; )))
         ;** Be careful about trailing backslashes.
         (save-excursion
           (if (paredit-in-char-p)
               (backward-char))
           (copy-region-as-kill (point) (point-at-eol))))
        (t (paredit-copy-sexps-as-kill))))

(defun paredit-copy-as-kill-in-string ()
  (save-excursion
    (if (paredit-in-string-escape-p)
        (backward-char))
    (copy-region-as-kill (point)
                         (min (point-at-eol)
                              (cdr (paredit-string-start+end-points))))))

(defun paredit-copy-sexps-as-kill ()
  (save-excursion
    (if (paredit-in-char-p)
        (backward-char 2))
    (let ((beginning (point))
          (eol (point-at-eol)))
      (let ((end-of-list-p (paredit-forward-sexps-to-kill beginning eol)))
        (if end-of-list-p (progn (up-list) (backward-char)))
        (copy-region-as-kill beginning
                             (cond (kill-whole-line
                                    (or (save-excursion
                                          (paredit-skip-whitespace t)
                                          (and (not (eq (char-after) ?\; ))
                                               (point)))
                                        (point-at-eol)))
                                   ((and (not end-of-list-p)
                                         (eq (point-at-eol) eol))
                                    eol)
                                   (t
                                    (point))))))))

;;;; Safe Region Killing/Copying

;;; This is an experiment.  It's not enough: `paredit-kill-ring-save'
;;; is always safe; it's `yank' that's not safe, but even trickier to
;;; implement than `paredit-kill-region'.  Also, the heuristics for
;;; `paredit-kill-region' are slightly too conservative -- they will
;;; sometimes reject killing regions that would be safe to kill.
;;; (Consider, e,g., a region that starts in a comment and ends in the
;;; middle of a symbol at the end of a line: that's safe to kill, but
;;; `paredit-kill-region' won't allow it.)  I don't know whether they
;;; are too liberal: I haven't constructed a region that is unsafe to
;;; kill but which `paredit-kill-region' will kill, but I haven't ruled
;;; out the possibility either.

(defun paredit-kill-ring-save (beginning end)
  "Save the balanced region, but don't kill it, like `kill-ring-save'.
If the text of the region is imbalanced, signal an error instead.
With a prefix argument, disregard any imbalance."
  (interactive "r")
  (if (not current-prefix-arg)
      (paredit-check-region beginning end))
  (setq this-command 'kill-ring-save)
  (kill-ring-save beginning end))

(defun paredit-kill-region (beginning end)
  "Kill balanced text between point and mark, like `kill-region'.
If that text is imbalanced, signal an error instead."
  (interactive "r")
  (if (and beginning end)
      ;; Check that region begins and ends in a sufficiently similar
      ;; state, so that deleting it will leave the buffer balanced.
      (save-excursion
        (goto-char beginning)
        (let* ((state (paredit-current-parse-state))
               (state* (parse-partial-sexp beginning end nil nil state)))
          (paredit-check-region-state state state*))))
  (setq this-command 'kill-region)
  (kill-region beginning end))

(defun paredit-check-region-state (beginning-state end-state)
  (paredit-check-region-state-depth beginning-state end-state)
  (paredit-check-region-state-string beginning-state end-state)
  (paredit-check-region-state-comment beginning-state end-state)
  (paredit-check-region-state-char-quote beginning-state end-state))

(defun paredit-check-region-state-depth (beginning-state end-state)
  (let ((beginning-depth (nth 0 beginning-state))
        (end-depth (nth 0 end-state)))
    (if (not (= beginning-depth end-depth))
        (error "Mismatched parenthesis depth: %S at start, %S at end."
               beginning-depth
               end-depth))))

(defun paredit-check-region-state-string (beginning-state end-state)
  (let ((beginning-string-p (nth 3 beginning-state))
        (end-string-p (nth 3 end-state)))
    (if (not (eq beginning-string-p end-string-p))
        (error "Mismatched string state: start %sin string, end %sin string."
               (if beginning-string-p "" "not ")
               (if end-string-p "" "not ")))))

(defun paredit-check-region-state-comment (beginning-state end-state)
  (let ((beginning-comment-state (nth 4 beginning-state))
        (end-comment-state (nth 4 end-state)))
    (if (not (or (eq beginning-comment-state end-comment-state)
                 (and (eq beginning-comment-state nil)
                      (eq end-comment-state t)
                      (eolp))))
        (error "Mismatched comment state: %s"
               (cond ((and (integerp beginning-comment-state)
                           (integerp end-comment-state))
                      (format "depth %S at start, depth %S at end."
                              beginning-comment-state
                              end-comment-state))
                     ((integerp beginning-comment-state)
                      "start in nested comment, end otherwise.")
                     ((integerp end-comment-state)
                      "end in nested comment, start otherwise.")
                     (beginning-comment-state
                      "start in comment, end not in comment.")
                     (end-comment-state
                      "end in comment, start not in comment.")
                     (t
                      (format "start %S, end %S."
                              beginning-comment-state
                              end-comment-state)))))))

(defun paredit-check-region-state-char-quote (beginning-state end-state)
  (let ((beginning-char-quote (nth 5 beginning-state))
        (end-char-quote (nth 5 end-state)))
    (if (not (eq beginning-char-quote end-char-quote))
        (let ((phrase "character quotation"))
          (error "Mismatched %s: start %sin %s, end %sin %s."
                 phrase
                 (if beginning-char-quote "" "not ")
                 phrase
                 (if end-char-quote "" "not ")
                 phrase)))))

;;;; Cursor and Screen Movement

(eval-and-compile
  (defmacro defun-saving-mark (name bvl doc &rest body)
    `(defun ,name ,bvl
       ,doc
       ,(xcond ((paredit-xemacs-p)
                '(interactive "_"))
               ((paredit-gnu-emacs-p)
                '(interactive)))
       ,@body)))

(defun-saving-mark paredit-forward ()
  "Move forward an S-expression, or up an S-expression forward.
If there are no more S-expressions in this one before the closing
  delimiter, move past that closing delimiter; otherwise, move forward
  past the S-expression following the point."
  (paredit-handle-sexp-errors
      (forward-sexp)
    ;++ Is it necessary to use UP-LIST and not just FORWARD-CHAR?
    (if (paredit-in-string-p) (forward-char) (up-list))))

(defun-saving-mark paredit-backward ()
  "Move backward an S-expression, or up an S-expression backward.
If there are no more S-expressions in this one before the opening
  delimiter, move past that opening delimiter backward; otherwise, move
  move backward past the S-expression preceding the point."
  (paredit-handle-sexp-errors
      (backward-sexp)
    (if (paredit-in-string-p) (backward-char) (backward-up-list))))

;;; Why is this not in lisp.el?

(defun backward-down-list (&optional arg)
  "Move backward and descend into one level of parentheses.
With ARG, do this that many times.
A negative argument means move forward but still descend a level."
  (interactive "p")
  (down-list (- (or arg 1))))

;;; Thanks to Marco Baringer for suggesting & writing this function.

(defun paredit-recentre-on-sexp (&optional n)
  "Recentre the screen on the S-expression following the point.
With a prefix argument N, encompass all N S-expressions forward."
  (interactive "P")
  (save-excursion
    (forward-sexp n)
    (let ((end-point (point)))
      (backward-sexp n)
      (let ((start-point (point)))
        (forward-line (/ (count-lines start-point end-point) 2))
        (recenter)))))

(defun paredit-focus-on-defun ()
  "Moves display to the top of the definition at point."
  (interactive)
  (beginning-of-defun)
  (recenter 0))

;;;; Generalized Upward/Downward Motion

(defun paredit-up/down (n vertical-direction)
  (let ((horizontal-direction (if (< 0 n) +1 -1)))
    (while (/= n 0)
      (goto-char
       (paredit-next-up/down-point horizontal-direction vertical-direction))
      (setq n (- n horizontal-direction)))))

(defun paredit-next-up/down-point (horizontal-direction vertical-direction)
  (let ((state (paredit-current-parse-state))
        (scan-lists
         (lambda ()
           (scan-lists (point) horizontal-direction vertical-direction))))
    (cond ((paredit-in-string-p state)
           (let ((start+end (paredit-string-start+end-points state)))
             (if (< 0 vertical-direction)
                 (if (< 0 horizontal-direction)
                     (+ 1 (cdr start+end))
                     (car start+end))
                 ;; We could let the user try to descend into lists
                 ;; within the string, but that would be asymmetric
                 ;; with the up case, which rises out of the whole
                 ;; string and not just out of a list within the
                 ;; string, so this case will just be an error.
                 (error "Can't descend further into string."))))
          ((< 0 vertical-direction)
           ;; When moving up, just try to rise up out of the list.
           (or (funcall scan-lists)
               (buffer-end horizontal-direction)))
          ((< vertical-direction 0)
           ;; When moving down, look for a string closer than a list,
           ;; and use that if we find it.
           (let* ((list-start
                   (paredit-handle-sexp-errors (funcall scan-lists) nil))
                  (string-start
                   (paredit-find-next-string-start horizontal-direction
                                                   list-start)))
             (if (and string-start list-start)
                 (if (< 0 horizontal-direction)
                     (min string-start list-start)
                     (max string-start list-start))
                 (or string-start
                     ;; Scan again: this is a kludgey way to report the
                     ;; error if there really was one.
                     (funcall scan-lists)
                     (buffer-end horizontal-direction)))))
          (t
           (error "Vertical direction must be nonzero in `%s'."
                  'paredit-up/down)))))

(defun paredit-find-next-string-start (horizontal-direction limit)
  (let ((next-char (if (< 0 horizontal-direction) 'char-after 'char-before))
        (pastp (if (< 0 horizontal-direction) '< '>)))
    (paredit-handle-sexp-errors
        (save-excursion
          (catch 'exit
            (while t
              (if (and limit (funcall pastp (point) limit))
                  (throw 'exit nil))
              (forward-sexp horizontal-direction)
              (save-excursion
                (backward-sexp horizontal-direction)
                (if (eq ?\" (char-syntax (funcall next-char)))
                    (throw 'exit (+ (point) horizontal-direction)))))))
      nil)))

(defun paredit-forward-down (&optional argument)
  "Move forward down into a list.
With a positive argument, move forward down that many levels.
With a negative argument, move backward down that many levels."
  (interactive "p")
  (paredit-up/down (or argument +1) -1))

(defun paredit-backward-up (&optional argument)
  "Move backward up out of the enclosing list.
With a positive argument, move backward up that many levels.
With a negative argument, move forward up that many levels.
If in a string initially, that counts as one level."
  (interactive "p")
  (paredit-up/down (- 0 (or argument +1)) +1))

(defun paredit-forward-up (&optional argument)
  "Move forward up out of the enclosing list.
With a positive argument, move forward up that many levels.
With a negative argument, move backward up that many levels.
If in a string initially, that counts as one level."
  (interactive "p")
  (paredit-up/down (or argument +1) +1))

(defun paredit-backward-down (&optional argument)
  "Move backward down into a list.
With a positive argument, move backward down that many levels.
With a negative argument, move forward down that many levels."
  (interactive "p")
  (paredit-up/down (- 0 (or argument +1)) -1))

;;;; Depth-Changing Commands:  Wrapping, Splicing, & Raising

(defun paredit-wrap-sexp (&optional argument open close)
  "Wrap the following S-expression.
If a `C-u' prefix argument is given, wrap all S-expressions following
  the point until the end of the buffer or of the enclosing list.
If a numeric prefix argument N is given, wrap N S-expressions.
Automatically indent the newly wrapped S-expression.
As a special case, if the point is at the end of a list, simply insert
  a parenthesis pair, rather than inserting a lone opening delimiter
  and then signalling an error, in the interest of preserving
  structure.
By default OPEN and CLOSE are round delimiters."
  (interactive "P")
  (paredit-lose-if-not-in-sexp 'paredit-wrap-sexp)
  (let ((open (or open ?\( ))
        (close (or close ?\) )))
    (paredit-handle-sexp-errors
        ((lambda (n) (paredit-insert-pair n open close 'goto-char))
         (cond ((integerp argument) argument)
               ((consp argument) (paredit-count-sexps-forward))
               ((paredit-region-active-p) nil)
               (t 1)))
      (insert close)
      (backward-char)))
  (save-excursion (backward-up-list) (indent-sexp)))

(defun paredit-count-sexps-forward ()
  (save-excursion
    (let ((n 0))
      (paredit-ignore-sexp-errors
        (while (not (eobp))
          (forward-sexp)
          (setq n (+ n 1))))
      n)))

(defun paredit-yank-pop (&optional argument)
  "Replace just-yanked text with the next item in the kill ring.
If this command follows a `yank', just run `yank-pop'.
If this command follows a `paredit-wrap-sexp', or any other paredit
  wrapping command (see `paredit-wrap-commands'), run `yank' and
  reindent the enclosing S-expression.
If this command is repeated, run `yank-pop' and reindent the enclosing
  S-expression.

The argument is passed on to `yank' or `yank-pop'; see their
  documentation for details."
  (interactive "*p")
  (cond ((eq last-command 'yank)
         (yank-pop argument))
        ((memq last-command paredit-wrap-commands)
         (yank argument)
         ;; `yank' futzes with `this-command'.
         (setq this-command 'paredit-yank-pop)
         (save-excursion (backward-up-list) (indent-sexp)))
        ((eq last-command 'paredit-yank-pop)
         ;; Pretend we just did a `yank', so that we can use
         ;; `yank-pop' without duplicating its definition.
         (setq last-command 'yank)
         (yank-pop argument)
         ;; Return to our original state.
         (setq last-command 'paredit-yank-pop)
         (setq this-command 'paredit-yank-pop)
         (save-excursion (backward-up-list) (indent-sexp)))
        (t (error "Last command was not a yank or a wrap: %s" last-command))))

;;; Thanks to Marco Baringer for the suggestion of a prefix argument
;;; for PAREDIT-SPLICE-SEXP.  (I, Taylor R. Campbell, however, still
;;; implemented it, in case any of you lawyer-folk get confused by the
;;; remark in the top of the file about explicitly noting code written
;;; by other people.)

(defun paredit-splice-sexp (&optional argument)
  "Splice the list that the point is on by removing its delimiters.
With a prefix argument as in `C-u', kill all S-expressions backward in
  the current list before splicing all S-expressions forward into the
  enclosing list.
With two prefix arguments as in `C-u C-u', kill all S-expressions
  forward in the current list before splicing all S-expressions
  backward into the enclosing list.
With a numerical prefix argument N, kill N S-expressions backward in
  the current list before splicing the remaining S-expressions into the
  enclosing list.  If N is negative, kill forward.
Inside a string, unescape all backslashes, or signal an error if doing
  so would invalidate the buffer's structure."
  (interactive "P")
  (if (paredit-in-string-p)
      (paredit-splice-string argument)
      (save-excursion
        (paredit-kill-surrounding-sexps-for-splice argument)
        (let ((end (point)))
          (backward-up-list)            ; Go up to the beginning...
          (save-excursion
            (forward-char 1)            ; (Skip over leading whitespace
            (paredit-skip-whitespace t end)
            (setq end (point)))         ;   for the `delete-region'.)
          (let ((indent-start nil) (indent-end nil))
            (save-excursion
              (setq indent-start (point))
              (forward-sexp)            ; Go forward an expression, to
              (backward-delete-char 1)  ;   delete the end delimiter.
              (setq indent-end (point)))
            (delete-region (point) end) ; ...to delete the open char.
            ;; Reindent only the region we preserved.
            (indent-region indent-start indent-end))))))

(defun paredit-kill-surrounding-sexps-for-splice (argument)
  (cond ((or (paredit-in-string-p)
             (paredit-in-comment-p))
         (error "Invalid context for splicing S-expressions."))
        ((or (not argument) (eq argument 0)) nil)
        ((or (numberp argument) (eq argument '-))
         ;; Kill S-expressions before/after the point by saving the
         ;; point, moving across them, and killing the region.
         (let* ((argument (if (eq argument '-) -1 argument))
                (saved (paredit-point-at-sexp-boundary (- argument))))
           (goto-char saved)
           (paredit-ignore-sexp-errors (backward-sexp argument))
           (paredit-hack-kill-region saved (point))))
        ((consp argument)
         (let ((v (car argument)))
           (if (= v 4)                  ;One `C-u'.
               ;; Move backward until we hit the open paren; then
               ;; kill that selected region.
               (let ((end (point)))
                 (paredit-ignore-sexp-errors
                   (while (not (bobp))
                     (backward-sexp)))
                 (paredit-hack-kill-region (point) end))
               ;; Move forward until we hit the close paren; then
               ;; kill that selected region.
               (let ((beginning (point)))
                 (paredit-ignore-sexp-errors
                   (while (not (eobp))
                     (forward-sexp)))
                 (paredit-hack-kill-region beginning (point))))))
        (t (error "Bizarre prefix argument `%s'." argument))))

(defun paredit-splice-sexp-killing-backward (&optional n)
  "Splice the list the point is on by removing its delimiters, and
  also kill all S-expressions before the point in the current list.
With a prefix argument N, kill only the preceding N S-expressions."
  (interactive "P")
  (paredit-splice-sexp (if n
                           (prefix-numeric-value n)
                           '(4))))

(defun paredit-splice-sexp-killing-forward (&optional n)
  "Splice the list the point is on by removing its delimiters, and
  also kill all S-expressions after the point in the current list.
With a prefix argument N, kill only the following N S-expressions."
  (interactive "P")
  (paredit-splice-sexp (if n
                           (- (prefix-numeric-value n))
                           '(16))))

(defun paredit-raise-sexp (&optional argument)
  "Raise the following S-expression in a tree, deleting its siblings.
With a prefix argument N, raise the following N S-expressions.  If N
  is negative, raise the preceding N S-expressions.
If the point is on an S-expression, such as a string or a symbol, not
  between them, that S-expression is considered to follow the point."
  (interactive "P")
  (save-excursion
    (cond ((paredit-in-string-p)
           (goto-char (car (paredit-string-start+end-points))))
          ((paredit-in-char-p)
           (backward-sexp))
          ((paredit-in-comment-p)
           (error "No S-expression to raise in comment.")))
    ;; Select the S-expressions we want to raise in a buffer substring.
    (let* ((n (prefix-numeric-value argument))
           (bound (scan-sexps (point) n))
           (sexps
            (if (< n 0)
                (buffer-substring bound (paredit-point-at-sexp-end))
                (buffer-substring (paredit-point-at-sexp-start) bound))))
      ;; Move up to the list we're raising those S-expressions out of and
      ;; delete it.
      (backward-up-list)
      (delete-region (point) (scan-sexps (point) 1))
      (let* ((indent-start (point))
             (indent-end (save-excursion (insert sexps) (point))))
        (indent-region indent-start indent-end)))))

(defun paredit-convolute-sexp (&optional n)
  "Convolute S-expressions.
Save the S-expressions preceding point and delete them.
Splice the S-expressions following point.
Wrap the enclosing list in a new list prefixed by the saved text.
With a prefix argument N, move up N lists before wrapping."
  (interactive "p")
  (paredit-lose-if-not-in-sexp 'paredit-convolute-sexp)
  (let (open close)                     ;++ Is this a good idea?
    (let ((prefix
           (let ((end (point)))
             (paredit-ignore-sexp-errors
               (while (not (bobp)) (backward-sexp)))
             (prog1 (buffer-substring (point) end)
               (backward-up-list)
               (save-excursion (forward-sexp)
                               (setq close (char-before))
                               (backward-delete-char 1))
               (setq open (char-after))
               (delete-region (point) end)))))
      (backward-up-list n)
      (paredit-insert-pair 1 open close 'goto-char)
      (insert prefix)
      (backward-up-list)
      (paredit-ignore-sexp-errors (indent-sexp)))))

(defun paredit-splice-string (argument)
  (let ((original-point (point))
        (start+end (paredit-string-start+end-points)))
    (let ((start (car start+end))
          (end (cdr start+end)))
      ;; START and END both lie before the respective quote
      ;; characters, which we want to delete; thus we increment START
      ;; by one to extract the string, and we increment END by one to
      ;; delete the string.
      (let* ((escaped-string
              (cond ((not (consp argument))
                     (buffer-substring (1+ start) end))
                    ((= 4 (car argument))
                     (buffer-substring original-point end))
                    (t
                     (buffer-substring (1+ start) original-point))))
             (unescaped-string
              (paredit-unescape-string escaped-string)))
        (if (not unescaped-string)
            (error "Unspliceable string.")
          (save-excursion
            (goto-char start)
            (delete-region start (1+ end))
            (insert unescaped-string))
          (if (not (and (consp argument)
                        (= 4 (car argument))))
              (goto-char (- original-point 1))))))))

(defun paredit-unescape-string (string)
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (while (and (not (eobp))
                ;; nil -> no bound; t -> no errors.
                (search-forward "\\" nil t))
      (delete-char -1)
      (forward-char))
    (condition-case condition
        (progn (check-parens) (buffer-string))
      (error nil))))

;;;; Slurpage & Barfage

(defun paredit-forward-slurp-sexp ()
  "Add the S-expression following the current list into that list
  by moving the closing delimiter.
Automatically reindent the newly slurped S-expression with respect to
  its new enclosing form.
If in a string, move the opening double-quote forward by one
  S-expression and escape any intervening characters as necessary,
  without altering any indentation or formatting."
  (interactive)
  (save-excursion
    (cond ((or (paredit-in-comment-p)
               (paredit-in-char-p))
           (error "Invalid context for slurping S-expressions."))
          ((paredit-in-string-p)
           (paredit-forward-slurp-into-string))
          (t
           (paredit-forward-slurp-into-list)))))

(defun paredit-forward-slurp-into-list ()
  (up-list)                             ; Up to the end of the list to
  (let ((close (char-before)))          ;   save and delete the closing
    (backward-delete-char 1)            ;   delimiter.
    (catch 'return                      ; Go to the end of the desired
      (while t                          ;   S-expression, going up a
        (paredit-handle-sexp-errors     ;   list if it's not in this,
            (progn (paredit-forward-and-indent)
                   (throw 'return nil))
          (up-list)
          (setq close                   ; adjusting for mixed
                (prog1 (char-before)    ;   delimiters as necessary,
                  (backward-delete-char 1)
                  (insert close))))))
    (insert close)))                    ; to insert that delimiter.

(defun paredit-forward-slurp-into-string ()
  (goto-char (1+ (cdr (paredit-string-start+end-points))))
  ;; Signal any errors that we might get first, before mucking with the
  ;; buffer's contents.
  (save-excursion (forward-sexp))
  (let ((close (char-before)))
    (backward-delete-char 1)
    (paredit-forward-for-quote (save-excursion (forward-sexp) (point)))
    (insert close)))

(defun paredit-forward-barf-sexp ()
  "Remove the last S-expression in the current list from that list
  by moving the closing delimiter.
Automatically reindent the newly barfed S-expression with respect to
  its new enclosing form."
  (interactive)
  (paredit-lose-if-not-in-sexp 'paredit-forward-barf-sexp)
  (save-excursion
    (up-list)                           ; Up to the end of the list to
    (let ((close (char-before)))        ;   save and delete the closing
      (backward-delete-char 1)          ;   delimiter.
      (paredit-ignore-sexp-errors       ; Go back to where we want to
        (backward-sexp))                ;   insert the delimiter.
      (paredit-skip-whitespace nil)     ; Skip leading whitespace.
      (cond ((bobp)
             (error "Barfing all subexpressions with no open-paren?"))
            ((paredit-in-comment-p)     ; Don't put the close-paren in
             (newline-and-indent)))     ;   a comment.
      (insert close))
    ;; Reindent all of the newly barfed S-expressions.
    (paredit-forward-and-indent)))

(defun paredit-backward-slurp-sexp ()
  "Add the S-expression preceding the current list into that list
  by moving the closing delimiter.
Automatically reindent the whole form into which new S-expression was
  slurped.
If in a string, move the opening double-quote backward by one
  S-expression and escape any intervening characters as necessary,
  without altering any indentation or formatting."
  (interactive)
  (save-excursion
    (cond ((or (paredit-in-comment-p)
               (paredit-in-char-p))
           (error "Invalid context for slurping S-expressions."))
          ((paredit-in-string-p)
           (paredit-backward-slurp-into-string))
          (t
           (paredit-backward-slurp-into-list)))))

(defun paredit-backward-slurp-into-list ()
  (backward-up-list)
  (let ((open (char-after)))
    (delete-char 1)
    (catch 'return
      (while t
        (paredit-handle-sexp-errors
            (progn (backward-sexp) (throw 'return nil))
          (backward-up-list)
          (setq open
                (prog1 (char-after)
                  (save-excursion (insert open) (delete-char 1)))))))
    (insert open))
  ;; Reindent the line at the beginning of wherever we inserted the
  ;; opening delimiter, and then indent the whole S-expression.
  (backward-up-list)
  (lisp-indent-line)
  (indent-sexp))

(defun paredit-backward-slurp-into-string ()
  (goto-char (car (paredit-string-start+end-points)))
  ;; Signal any errors that we might get first, before mucking with the
  ;; buffer's contents.
  (save-excursion (backward-sexp))
  (let ((open (char-after))
        (target (point)))
    (delete-char 1)
    (backward-sexp)
    (insert open)
    (paredit-forward-for-quote target)))

(defun paredit-backward-barf-sexp ()
  "Remove the first S-expression in the current list from that list
  by moving the closing delimiter.
Automatically reindent the barfed S-expression and the form from which
  it was barfed."
  (interactive)
  (paredit-lose-if-not-in-sexp 'paredit-backward-barf-sexp)
  (save-excursion
    (backward-up-list)
    (let ((open (char-after)))
      (delete-char 1)
      (paredit-ignore-sexp-errors
        (paredit-forward-and-indent))
      (while (progn (paredit-skip-whitespace t)
                    (eq (char-after) ?\; ))
        (forward-line 1))
      (if (eobp)
          (error "Barfing all subexpressions with no close-paren?"))
      ;** Don't use `insert' here.  Consider, e.g., barfing from
      ;**   (foo|)
      ;** and how `save-excursion' works.
      (insert-before-markers open))
    (backward-up-list)
    (lisp-indent-line)
    (indent-sexp)))

;;;; Splitting & Joining

(defun paredit-split-sexp ()
  "Split the list or string the point is on into two."
  (interactive)
  (cond ((paredit-in-string-p)
         (insert "\"")
         (save-excursion (insert " \"")))
        ((or (paredit-in-comment-p)
             (paredit-in-char-p))
         (error "Invalid context for splitting S-expression."))
        (t (let ((open  (save-excursion (backward-up-list)
                                        (char-after)))
                 (close (save-excursion (up-list)
                                        (char-before))))
             (delete-horizontal-space)
             (insert close)
             (save-excursion (insert ?\ )
                             (insert open)
                             (backward-char)
                             (indent-sexp))))))

(defun paredit-join-sexps ()
  "Join the S-expressions adjacent on either side of the point.
Both must be lists, strings, or atoms; error if there is a mismatch."
  (interactive)
  ;++ How ought this to handle comments intervening symbols or strings?
  (save-excursion
    (if (or (paredit-in-comment-p)
            (paredit-in-string-p)
            (paredit-in-char-p))
        (error "Invalid context for joining S-expressions.")
      (let ((left-point  (paredit-point-at-sexp-end))
            (right-point (paredit-point-at-sexp-start)))
        (let ((left-char (char-before left-point))
              (right-char (char-after right-point)))
          (let ((left-syntax (char-syntax left-char))
                (right-syntax (char-syntax right-char)))
            (cond ((>= left-point right-point)
                   (error "Can't join a datum with itself."))
                  ((and (eq left-syntax  ?\) )
                        (eq right-syntax ?\( )
                        (eq left-char (matching-paren right-char))
                        (eq right-char (matching-paren left-char)))
                   ;; Leave intermediate formatting alone.
                   (goto-char right-point)
                   (delete-char 1)
                   (goto-char left-point)
                   (backward-delete-char 1)
                   (backward-up-list)
                   (indent-sexp))
                  ((and (eq left-syntax  ?\" )
                        (eq right-syntax ?\" ))
                   ;; Delete any intermediate formatting.
                   (delete-region (1- left-point)
                                  (1+ right-point)))
                  ((and (memq left-syntax  '(?w ?_)) ; Word or symbol
                        (memq right-syntax '(?w ?_)))
                   (delete-region left-point right-point))
                  (t
                   (error "Mismatched S-expressions to join.")))))))))

;;;; Variations on the Lurid Theme

;;; I haven't the imagination to concoct clever names for these.

(defun paredit-add-to-previous-list ()
  "Add the S-expression following point to the list preceding point."
  (interactive)
  (paredit-lose-if-not-in-sexp 'paredit-add-to-previous-list)
  (save-excursion
    (backward-down-list)
    (paredit-forward-slurp-sexp)))

(defun paredit-add-to-next-list ()
  "Add the S-expression preceding point to the list following point.
If no S-expression precedes point, move up the tree until one does."
  (interactive)
  (paredit-lose-if-not-in-sexp 'paredit-add-to-next-list)
  (save-excursion
    (down-list)
    (paredit-backward-slurp-sexp)))

(defun paredit-join-with-previous-list ()
  "Join the list the point is on with the previous list in the buffer."
  (interactive)
  (paredit-lose-if-not-in-sexp 'paredit-join-with-previous-list)
  (save-excursion
    (while (paredit-handle-sexp-errors (save-excursion (backward-sexp) nil)
             (backward-up-list)
             t))
    (paredit-join-sexps)))

(defun paredit-join-with-next-list ()
  "Join the list the point is on with the next list in the buffer."
  (interactive)
  (paredit-lose-if-not-in-sexp 'paredit-join-with-next-list)
  (save-excursion
    (while (paredit-handle-sexp-errors (save-excursion (forward-sexp) nil)
             (up-list)
             t))
    (paredit-join-sexps)))

;;;; Utilities

(defun paredit-in-string-escape-p ()
  "True if the point is on a character escape of a string.
This is true only if the character is preceded by an odd number of
  backslashes.
This assumes that `paredit-in-string-p' has already returned true."
  (let ((oddp nil))
    (save-excursion
      (while (eq (char-before) ?\\ )
        (setq oddp (not oddp))
        (backward-char)))
    oddp))

(defun paredit-in-char-p (&optional argument)
  "True if the point is immediately after a character literal.
A preceding escape character, not preceded by another escape character,
  is considered a character literal prefix.  (This works for elisp,
  Common Lisp, and Scheme.)
Assumes that `paredit-in-string-p' is false, so that it need not handle
  long sequences of preceding backslashes in string escapes.  (This
  assumes some other leading character token -- ? in elisp, # in Scheme
  and Common Lisp.)"
  (let ((argument (or argument (point))))
    (and (eq (char-before argument) ?\\ )
         (not (eq (char-before (1- argument)) ?\\ )))))

(defun paredit-indent-sexps ()
  "If in a list, indent all following S-expressions in the list."
  (let ((start (point))
        (end (paredit-handle-sexp-errors (progn (up-list) (point)) nil)))
    (if end
        (indent-region start end))))

(defun paredit-forward-and-indent ()
  "Move forward an S-expression, indenting it with `indent-region'."
  (let ((start (point)))
    (forward-sexp)
    (indent-region start (point))))

(defun paredit-skip-whitespace (trailing-p &optional limit)
  "Skip past any whitespace, or until the point LIMIT is reached.
If TRAILING-P is nil, skip leading whitespace; otherwise, skip trailing
  whitespace."
  (funcall (if trailing-p 'skip-chars-forward 'skip-chars-backward)
           " \t\n"  ; This should skip using the syntax table, but LF
           limit))    ; is a comment end, not newline, in Lisp mode.

(defalias 'paredit-region-active-p
  (xcond ((paredit-xemacs-p) 'region-active-p)
         ((paredit-gnu-emacs-p)
          (lambda ()
            (and mark-active transient-mark-mode)))))

(defun paredit-hack-kill-region (start end)
  "Kill the region between START and END.
Do not append to any current kill, and
 do not let the next kill append to this one."
  (interactive "r")                     ;Eh, why not?
  ;; KILL-REGION sets THIS-COMMAND to tell the next kill that the last
  ;; command was a kill.  It also checks LAST-COMMAND to see whether it
  ;; should append.  If we bind these locally, any modifications to
  ;; THIS-COMMAND will be masked, and it will not see LAST-COMMAND to
  ;; indicate that it should append.
  (let ((this-command nil)
        (last-command nil))
    (kill-region start end)))

;;;;; S-expression Parsing Utilities

;++ These routines redundantly traverse S-expressions a great deal.
;++ If performance issues arise, this whole section will probably have
;++ to be refactored to preserve the state longer, like paredit.scm
;++ does, rather than to traverse the definition N times for every key
;++ stroke as it presently does.

(defun paredit-current-parse-state ()
  "Return parse state of point from beginning of defun."
  (let ((point (point)))
    (beginning-of-defun)
    ;; Calling PARSE-PARTIAL-SEXP will advance the point to its second
    ;; argument (unless parsing stops due to an error, but we assume it
    ;; won't in paredit-mode).
    (parse-partial-sexp (point) point)))

(defun paredit-in-string-p (&optional state)
  "True if the parse state is within a double-quote-delimited string.
If no parse state is supplied, compute one from the beginning of the
  defun to the point."
  ;; 3. non-nil if inside a string (the terminator character, really)
  (and (nth 3 (or state (paredit-current-parse-state)))
       t))

(defun paredit-string-start+end-points (&optional state)
  "Return a cons of the points of open and close quotes of the string.
The string is determined from the parse state STATE, or the parse state
  from the beginning of the defun to the point.
This assumes that `paredit-in-string-p' has already returned true, i.e.
  that the point is already within a string."
  (save-excursion
    ;; 8. character address of start of comment or string; nil if not
    ;;    in one
    (let ((start (nth 8 (or state (paredit-current-parse-state)))))
      (goto-char start)
      (forward-sexp 1)
      (cons start (1- (point))))))

(defun paredit-in-comment-p (&optional state)
  "True if parse state STATE is within a comment.
If no parse state is supplied, compute one from the beginning of the
  defun to the point."
  ;; 4. nil if outside a comment, t if inside a non-nestable comment,
  ;;    else an integer (the current comment nesting)
  (and (nth 4 (or state (paredit-current-parse-state)))
       t))

(defun paredit-point-at-sexp-boundary (n)
  (cond ((< n 0) (paredit-point-at-sexp-start))
        ((= n 0) (point))
        ((> n 0) (paredit-point-at-sexp-end))))

(defun paredit-point-at-sexp-start ()
  (save-excursion
    (forward-sexp)
    (backward-sexp)
    (point)))

(defun paredit-point-at-sexp-end ()
  (save-excursion
    (backward-sexp)
    (forward-sexp)
    (point)))

(defun paredit-lose-if-not-in-sexp (command)
  (if (or (paredit-in-string-p)
          (paredit-in-comment-p)
          (paredit-in-char-p))
      (error "Invalid context for command `%s'." command)))

(defun paredit-check-region (start end)
  (save-restriction
    (narrow-to-region start end)
    (if (fboundp 'check-parens)
        (check-parens)
        (save-excursion
          (goto-char (point-min))
          (while (not (eobp))
            (forward-sexp))))))

(defun paredit-region-ok-p (start end)
  (paredit-handle-sexp-errors
      (progn
        (save-restriction
          (narrow-to-region start end)
          ;; Can't use `check-parens' here -- it signals the wrong kind
          ;; of errors.
          (save-excursion
            (goto-char (point-min))
            (while (not (eobp))
              (forward-sexp))))
        t)
    nil))

;;;; Initialization

(paredit-define-keys)
(paredit-annotate-mode-with-examples)
(paredit-annotate-functions-with-examples)

(provide 'paredit)

;;; Local Variables:
;;; outline-regexp: "\n;;;;+"
;;; End:

;;; paredit.el ends here
