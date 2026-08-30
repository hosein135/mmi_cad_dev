;;;
;;;  rule	: *			;; Matches any non-null node.
;;;
;;;		| (and rule+)		;; Matches if all rules match,
;;;					;; stops at first mismatch.
;;;
;;;		| (or rule+)		;; Matches if any rule matches,
;;;					;; stops at first match.
;;;
;;;		| (not rule)		;; Matches if rule doesn't match.
;;;
;;;		| (test STRING)		;; Matches if C expression STRING
;;;					;; is true.
;;;
;;;		| (replace rule replacement+)
;;;					;; Matches if rule matches, replaces
;;;					;; the match with replacement.
;;;
;;;		| (call-rewrite REWRITE)
;;;					;; Calls the specified rewrite rule on
;;;					;; the current node.  Always matches.
;;;	
;;;	        | (call-predicate PREDICATE)
;;;					;; Calls the specified predicate on the
;;;					;; the current node.  Matches if the 
;;;					;; predicate returns TRUE.
;;;  
;;;		| (let local-vars rule) ;; Matches if rule matches.  Binds
;;;					;; local variables before matching.
;;;
;;;		| $VARIABLE		;; Matches any non-null node, binds
;;;					;; VARIABLE the node matched.
;;;
;;;		| pattern		;; Matches if pattern matches.
;;;
;;;		| [token args]		;; The match condition is obtained by
;;;					;; calling rewrite-match-node with 
;;;					;; arguments (token . args).
;;;
;;;		| INTEGER		;; The match condition is obtained by
;;;					;; calling rewrite-match-integer-node
;;;					;; with the node and the integer as
;;;					;; arguments.
;;;
;;;		| STRING		;; The match condition is obtained by
;;;					;; calling rewrite-match-string-node
;;;					;; with the node and the string as
;;;					;; arguments.
;;;
;;;		| FLOAT			;; The match condition is obtained by
;;;					;; calling rewrite-match-float-node
;;;					;; with the node and the float as
;;;					;; arguments.
;;;
;;;		| 'SYMBOL		;; The match condition is obtained by
;;;					;; calling rewrite-match-symbol-node
;;;					;; with the node and the symbol as
;;;					;; arguments.
;;;		;
;;;
;;;
;;;  local-vars	: STRING		
;;;		| (STRING+)
;;;		;
;;;
;;;
;;;  replacement: tree
;;;
;;;		| (if STRING replacement replacement)
;;;					;; Performs the first replacement if
;;;					;; C expression STRING is true,
;;;					;; otherwise performs the second.
;;;		| (copy tree)
;;;
;;;		;
;;;
;;;
;;;  tree	: $VARIABLE		;; Replaces with the value of VARIABLE.
;;;
;;;		| (token tree* [. $VARIABLE])
;;;					;; Replaces with a node that has token
;;;					;; as its token, and the trees as
;;;					;; children.  If the optional 
;;;					;; ". $VARIABLE" is present, the
;;;					;; value of that variable is the 
;;;					;; remaining children.
;;;
;;;		| [token args]		;; Replaces with a node obtained by
;;;					;; calling rewrite-create-node with 
;;;					;; arguments (token . args).
;;;
;;;		| INTEGER		;; Replaces with a node obtained by
;;;					;; calling rewrite-create-integer-node
;;;					;; with the integer as an argument.
;;;
;;;		| STRING		;; Replaces with a node obtained by
;;;					;; calling rewrite-create-string-node
;;;					;; with the string as an argument.
;;;
;;;		| FLOAT			;; Replaces with a node obtained by
;;;					;; calling rewrite-create-float-node
;;;					;; with the float as an argument.
;;;
;;;		| 'SYMBOL		;; Replaces with a node obtained by
;;;					;; calling rewrite-create-symbol-node
;;;					;; with the symbol as an argument.
;;;		;
;;;
;;;
;;;  token      : TOKEN			;; TOKEN is the token.
;;;
;;;		| $VARIABLE.token	;; the token of the node referred to by
;;;					;; VARIABLE is the token
;;;		;
;;;
;;;  args       : any number of lisp expressions
;;;		;
;;;
;;;
;;;  pattern	: (token-set child*)	;; Matches any node whose token is a
;;;					;; member of the token set and whose
;;;					;; children match the child specifiers.
;;;		;
;;;
;;;
;;;  token-set	: TOKEN			;; The token set include just the
;;;					;; given token.
;;;
;;;		| ^TOKEN		;; The token set includes all but the
;;;					;; given token.
;;;
;;;		| (TOKEN+)		;; The token set includes all the
;;;					;; listed tokens.
;;;
;;;		| (^ TOKEN+)		;; The token set includes all but the
;;;					;; listed tokens.
;;;		;
;;;
;;;
;;;  child	: rule			;; Matches if the child matches the 
;;;					;; rule.  Advances to the next child.
;;;
;;;		| &rest			;; Matches any remaining sequence of
;;;					;; children.  Semantically equivalent
;;;					;; to "(repeat *)"
;;;
;;;		| &optional		;; Means the pattern matches even if
;;;					;; any of the following children are
;;;					;; not present.
;;;
;;;		| (repeat child+)	;; Match zero or more sequences of
;;;					;; children until one of them doesn't
;;;					;; match or the end is reached.
;;;					;; Advances to the child that caused
;;;					;; the repeat loop to terminate.
;;;
;;;		| (do STRING)		;; Don't match anything, just insert
;;;					;; the string contents as C code.  The
;;;					;; string may contain $ variables.
;;;
;;;		| =VARIABLE		;; Bind the specified variable to the
;;;					;; most recently matched child.  If 
;;;					;; no children have been matched (i.e.
;;;					;; just the parent), bind the variable
;;;					;; to the parent.
;;;		;
;;;
;;;
;;; The user must supply the following functions, all of which return
;;; a string that is either a C expression or a C statement.  Unless
;;; oterwise noted, the arguments to these functions are strings.
;;;
;;; (rewrite-declare-node var &optional value)
;;;
;;;   Returns a statement that declares var to be a node.  If value is
;;;   present, it should be used to initialize var.
;;;
;;; (rewrite-declare-token var &optional value)
;;;
;;;   Returns a statement that declares var to be a token.  If value
;;;   is present, it should be used to initialize var.
;;;
;;; (rewrite-create-integer-node n)
;;;
;;;   Returns an expression that creates a node representing an
;;;   integer in a replacement tree.  The argument is an integer.
;;;
;;; (rewrite-create-string-node n)
;;;
;;;   Returns an expression that creates a node representing a
;;;   string in a replacement tree.  The argument is a string.
;;;
;;; (rewrite-create-float-node n)
;;;
;;;   Returns an expression that creates a node representing a
;;;   float in a replacement tree.  The argument is a float.
;;;
;;; (rewrite-create-node token &rest args)
;;;
;;;   Returns an expression that creates a node with the specified
;;;   token (a symbol) and arguments (strings).
;;;
;;; (rewrite-compare-token token variable)
;;;
;;;   Returns an expression that compares variable (a string) to token
;;;   (a symbol).
;;;
;;; (rewrite-get node field)
;;;
;;;   Returns an expression that accesses the specified field (a
;;;   symbol) of the specified node (a string).
;;;
;;; (rewrite-set node field)
;;;
;;;   Returns a statement that sets the specified field (a symbol) of
;;;   the specified node (a string) to the specified value (a string).
;;;


(require 'setl)
(require 'pp)


(defvar rewrite-current-indent 0)


(defun rewrite-goto-child ()
  (indent-to rewrite-current-indent 1)
  (insert "__prev_start = __prev_end = __tree;\n")
  (indent-to rewrite-current-indent 1)
  (insert (format "__tree = %s;\n\n" (rewrite-get "__tree" 'child))))


(defun rewrite-goto-sibling ()
  (indent-to rewrite-current-indent 1)
  (insert "__prev_start = __prev_end = __tree;\n")
  (indent-to rewrite-current-indent 1)
  (insert (format "__tree = %s;\n" (rewrite-get "__tree" 'sibling))))


(defun rewrite-string-replace-match (regexp string newtext &optional literal)
  (let ((start 0)
	from-end)

    (while (string-match regexp string start)
      (setq from-end (- (length string) (match-end 0)))
      (setq string (replace-match newtext t literal string))
      (setq start (- (length string) from-end)))

    string))


;;(defun rewrite-format-c-code (str)
;;  (rewrite-string-replace-match
;;   "$\\([A-Za-z0-9_]+\\)" str
;;   (concat (rewrite-format-variable "\\1") "_start")))


(defun rewrite-format-c-code (str)
  (let ((start 0)
	(s str)
	var replacement)
    (while (string-match "$\\([A-Za-z0-9_]+\\)\\(\\.\\([A-Za-z0-9_]+\\)\\)?"
			 s start)
      (setq from-end (- (length s) (match-end 0)))

      (setq var (concat 
		 (rewrite-format-variable 
		  (substring s (match-beginning 1) (match-end 1)))
		 "_start"))

      (if (match-beginning 2)
	  (setq replacement
		(rewrite-get var 
			     (intern (substring s (match-beginning 3)
						(match-end 3)))))
	(setq replacement var))

      (setq s (replace-match replacement t t s))
      (setq start (- (length s) from-end)))
    s))


(defun rewrite-is-token-symbol (sym)
  (let* ((name (symbol-name sym))
	 (i 0)
	 (n (length name))
	 char)
    (if (= (aref name 0) ?^)
	(setq i (1+ i))
      (while (and (< i n) 
		  (setq char (aref name i))
		  (or (and (>= char ?A)
			   (<= char ?Z))
		      (and (>= char ?0)
			   (<= char ?9))
		      (eq char ?_)))
	(setq i (1+ i)))

    (= i n))))


(defun rewrite-is-token-set (tokens)
  (or (listp tokens)
      (and (symbolp tokens)
	   (rewrite-is-token-symbol tokens))))


(defun rewrite-is-not-token (token)
  (let ((name (symbol-name token)))
    (= (aref name 0) ?^)))


(defun rewrite-strip-not (token)
  (let ((name (symbol-name token)))
    (intern (substring name 1))))


(defun rewrite-get-token-set (tokens)
  (if (listp tokens)
      tokens
    (if (rewrite-is-not-token tokens)
	(list '^ (rewrite-strip-not tokens))
      (list tokens))))


(defun rewrite-save-var (name)
  (rewrite-note (format "saving %s" name))
  (indent-to rewrite-current-indent 1)
  (insert "{\n")

  (setq rewrite-current-indent (+ rewrite-current-indent 2))
  (indent-to rewrite-current-indent 1)
  (insert (rewrite-declare-node name))
  (insert "\n"))


(defun rewrite-restore-var ()
  (setq rewrite-current-indent (- rewrite-current-indent 2))

  (indent-to rewrite-current-indent 1)
  (insert "}\n"))


(defun rewrite-catch-begin ()
  (indent-to rewrite-current-indent 1)
  (insert "do {\n")

  (setq rewrite-current-indent (+ rewrite-current-indent 2)))


(defun rewrite-catch-end ()
  (setq rewrite-current-indent (- rewrite-current-indent 2))

  (indent-to rewrite-current-indent 1)
  (insert "} while (0);\n"))


(defun rewrite-pattern-begin (pattern)
  (rewrite-note (format "beginning pattern (%s...)" (car pattern)))
  (rewrite-catch-begin)
  (indent-to rewrite-current-indent 1)
  (insert (rewrite-declare-node "__temp" "__tree"))
  (insert "\n")
  (indent-to rewrite-current-indent 1)
  (insert (rewrite-declare-node "__tree" "__temp"))
  (insert "\n")
  (indent-to rewrite-current-indent 1)
  (insert (rewrite-declare-node "__prev_start" "NULL"))
  (insert "\n")
  (indent-to rewrite-current-indent 1)
  (insert (rewrite-declare-node "__prev_end" "NULL"))
  (insert "\n")
  (insert "\n"))


(defun rewrite-pattern-end (pattern)
  (rewrite-note (format "end pattern (%s...)" (car pattern)))
  (rewrite-catch-end))


(defun rewrite-reset-match ()
  (indent-to rewrite-current-indent 1)
  (insert "__match = 1;\n"))


(defun rewrite-invert-match ()
  (indent-to rewrite-current-indent 1)
  (insert "__match = !__match;\n"))


(defun rewrite-if-begin (cond)
  (indent-to rewrite-current-indent 1)
  (insert (format "if ( %s ) {\n" cond))
  (setq rewrite-current-indent (+ rewrite-current-indent 2)))


(defun rewrite-if-else ()
  (indent-to (- rewrite-current-indent 2) 1)
  (insert "}\n")
  (indent-to (- rewrite-current-indent 2) 1)
  (insert "else {\n"))


(defun rewrite-if-end ()
  (setq rewrite-current-indent (- rewrite-current-indent 2))
  (indent-to rewrite-current-indent 1)
  (insert "}\n"))


(defun rewrite-while-begin (cond)
  (indent-to rewrite-current-indent 1)
  (insert (format "while ( %s ) {\n" cond))
  (setq rewrite-current-indent (+ rewrite-current-indent 2)))


(defun rewrite-while-end ()
  (setq rewrite-current-indent (- rewrite-current-indent 2))
  (indent-to rewrite-current-indent 1)
  (insert (format "}\n")))


(defun rewrite-if-match-begin ()
  (rewrite-if-begin "__match"))


(defun rewrite-if-no-match-begin ()
  (rewrite-if-begin "! __match"))


(defun rewrite-throw ()
  (indent-to rewrite-current-indent 1)
  (insert "break;\n"))


(defun rewrite-return ()
  (indent-to rewrite-current-indent 1)
  (insert "return;\n"))


(defun rewrite-throw-on-match ()
  (rewrite-if-match-begin)
  (rewrite-throw)
  (rewrite-if-end))


(defun rewrite-throw-on-no-match ()
  (rewrite-if-no-match-begin)
  (rewrite-throw)
  (rewrite-if-end))


(defun rewrite-return-on-no-match ()
  (rewrite-if-no-match-begin)
  (rewrite-return)
  (rewrite-if-end))


(defun rewrite-match-token-set (token-set)
  (let ((toks (rewrite-get-token-set token-set)))
    (indent-to rewrite-current-indent 1)
    (insert "__match = 0;\n")
    (rewrite-if-begin "__tree != NULL")

    (indent-to rewrite-current-indent 1)
    (insert (rewrite-declare-token "__token" (rewrite-get "__tree" 'token)))
    (insert "\n")

    (indent-to rewrite-current-indent 1)
    (if (eq (car toks) '^)
	(progn
	  (insert "__match = !(")
	  (setq toks (cdr toks)))
      (insert "__match =  ("))

    (while toks
      (insert (rewrite-compare-token (car toks) "__token"))
      (setq toks (cdr toks))
      (if toks
	  (progn
	    (insert " ||\n")
	    (indent-to (+ rewrite-current-indent 12) 1))))
    (insert ");\n")

    (rewrite-if-end)))


(defun rewrite-note-match (str)
  (indent-to rewrite-current-indent 1)
  (insert (format "/* matching \"%s\" */\n" str)))


(defun rewrite-note (str)
  (indent-to rewrite-current-indent 1)
  (insert (format "/* %s */\n" str)))


(defun rewrite-match-null ()
  (indent-to rewrite-current-indent 1)
  (insert "__match = (__tree == NULL);\n"))


(defun rewrite-match-non-null ()
  (indent-to rewrite-current-indent 1)
  (insert "__match = (__tree != NULL);\n"))


(defun rewrite-get-variable-name (sym)
  (let ((str (symbol-name sym)))
    (substring str 1)))


(defun rewrite-format-variable (name)
  (concat "__" name "_node"))


(defun rewrite-bind-symbol (var value_start value_end)
  (indent-to rewrite-current-indent 1)
  (insert
   (format "%s_start = %s;\n"
	   (rewrite-format-variable (rewrite-get-variable-name var))
	   value_start))
  (indent-to rewrite-current-indent 1)
  (insert
   (format "%s_end = %s;\n"
	   (rewrite-format-variable (rewrite-get-variable-name var))
	   value_end)))
  


(defun rewrite-action (string)
  (rewrite-note (format "action \"%s\"" string))
  (let ((stmt (rewrite-format-c-code string)))
    (indent-to rewrite-current-indent 1)
    (insert stmt)
    (insert "\n")))


(defun rewrite-repeat-begin ()
  (rewrite-note "(repeat")

  (indent-to rewrite-current-indent 1)
  (insert "{\n")
  (setq rewrite-current-indent (+ rewrite-current-indent 2))
  (indent-to rewrite-current-indent 1)
  (insert (rewrite-declare-node "__temp" "__prev_start"))
  (insert "\n")
  (indent-to rewrite-current-indent 1)
  (insert (rewrite-declare-node "__prev_start" "__temp"))
  (insert "\n")
  (indent-to rewrite-current-indent 1)
  (insert "int __first = 1;\n")
  (indent-to rewrite-current-indent 1)
  (insert "do {\n")
  (setq rewrite-current-indent (+ rewrite-current-indent 2)))


(defun rewrite-repeat-end (where)
  (indent-to rewrite-current-indent 1)
  (insert "__first = 0;\n");
  (setq rewrite-current-indent (- rewrite-current-indent 2))
  (rewrite-note "end of (repeat...)")
  (indent-to rewrite-current-indent 1)
  (insert "} while (__match);\n\n")
  (setq rewrite-current-indent (- rewrite-current-indent 2))
  (indent-to rewrite-current-indent 1)
  (insert "}\n")
  (rewrite-note
   "have to set __prev_start to point to the beginning of the repeat")
  (indent-to rewrite-current-indent 1)
  (insert "__prev_start = ")
  (cond
   ((eq (car where) 'pointer)
    (insert (format "*%s" (cdr where))))
   ((eq (car where) 'parent)
    (insert (rewrite-get (cdr where) 'child)))
   ((eq (car where) 'parent-firstonly)
    (insert "__first ? ")
    (insert (rewrite-get (cdr where) 'child))
    (insert " : ")
    (insert (rewrite-get (cdr where) 'sibling)))
   ((eq (car where) 'sibling)
    (insert (rewrite-get (cdr where) 'sibling)))
   (t
    (error "bogus value for 'where' -> %s" where)))
  (insert ";\n"))

;;  (rewrite-note "have to do this after repeat to get __prev synced up")
;;  (rewrite-save-var "__tree")
;;  (indent-to rewrite-current-indent 1)
;;  (insert "__tree = __prev;\n")
;;  (rewrite-goto-sibling)
;;  (rewrite-goto-sibling)
;;  (rewrite-restore-var)


(defun rewrite-generate-pattern-child (child optional rest where)
  (cond 
   ((eq child '&rest)
    (setq rest t)
    (rewrite-note "&rest")
    (indent-to rewrite-current-indent 1)
    (insert "__prev_start = __prev_end = __tree;\n")
    (rewrite-note "have to scan to the end of the list to set __prev_end")
    (indent-to rewrite-current-indent 1)
    (rewrite-if-begin "__prev_start != NULL")
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-declare-node "__temp" "__prev_start"))
    (insert "\n")
    (rewrite-while-begin (format "(__temp = %s) != NULL"
				 (rewrite-get "__temp" 'sibling)))
    (indent-to rewrite-current-indent 1)
    (insert "__prev_end = __temp;\n")
    (rewrite-while-end)
    (rewrite-if-end)
    (setq where '(sibling . "__prev_end")))

   ((eq child '&optional)
    (if rest
	(error "&optional follows &rest -> %s" pattern))
    (setq optional t)
    (rewrite-note "&optional"))

   ((and (symbolp child)
	 (= (aref (symbol-name child) 0) ?=))
    (rewrite-bind-symbol child "__prev_start" "__prev_end"))

   ((and (listp child)
	 (eq (car child) 'do))
    (rewrite-action child))

   ((and (listp child)
	 (eq (car child) 'repeat))
    (if rest
	(error "repeat form follows &rest -> %s" pattern))

    (let ((children (cdr child))
	  (where-save where))
      (rewrite-repeat-begin)
      (while children
	(setl (optional rest where)
	      (rewrite-generate-pattern-child (car children)
					      optional rest
					      (if (eq (car where) 'parent)
						  (cons 'parent-firstonly
							(cdr where))
						where)))
	(setq children (cdr children)))
      (rewrite-match-non-null)
      (rewrite-repeat-end where-save)
      (rewrite-note "repeat construct always matches")
      (rewrite-reset-match)))

   (t
    (if rest
	(error "rule follows &rest -> %s" pattern))

    (rewrite-generate-rule child where)
	    
    (if optional
	(progn
	  (rewrite-note "&optional is in effect")
	  (rewrite-note "only advance to sibling if matched")
	  (rewrite-if-match-begin)
	  (rewrite-goto-sibling)
	  (rewrite-if-end)
	  (rewrite-reset-match))
      (rewrite-throw-on-no-match)
      (rewrite-goto-sibling))

    (setq where '(sibling . "__prev_end"))))

  (list optional rest where))


(defun rewrite-generate-pattern (pattern)
  (if (not (listp pattern))
      (error "rewrite-generate-pattern: bogus pattern -> %s" pattern))

  (let ((children (cdr pattern))
	(optional nil)
	(rest nil)
	child
	where)

    (rewrite-pattern-begin pattern)

    (rewrite-note-match (format "(%s" (car pattern)))
    (rewrite-match-token-set (car pattern))
    (rewrite-throw-on-no-match)

    (rewrite-goto-child)
    (setq where '(parent . "__prev_start"))

    (while children
      (setq child (car children)
	    children (cdr children))

      (setl (optional rest where)
	    (rewrite-generate-pattern-child child optional rest where)))

    (rewrite-note-match ")")
    
    (if rest
	(progn
	  (rewrite-note "&rest is in effect, so always match")
	  (rewrite-reset-match))
      (rewrite-match-null)
      (rewrite-throw-on-no-match))

    (rewrite-pattern-end pattern)))


(defun rewrite-generate-test (rule)
  (if (not (and (listp rule) (eq (car rule) 'test)))
      (error "rewrite-generate-test: invalid predicate -> %s" rule)

    (let ((c-expr (rewrite-format-c-code (cadr rule))))
      (rewrite-note (format "%s" rule))
      (indent-to rewrite-current-indent 1)
      (insert (format "__match = (%s);\n" c-expr)))))


(defun rewrite-generate-special (fun args)
  (indent-to rewrite-current-indent 1)
  (insert (format "__match = (%s);\n" (apply fun "__tree" args))))


(defun rewrite-generate-or (rule where)
  (let ((terms (cdr rule))
	term)
    (rewrite-note "(or")
    (rewrite-catch-begin)
    (while terms
      (rewrite-generate-rule (car terms) where)
      (rewrite-throw-on-match)
      (setq terms (cdr terms)))
    (rewrite-note "end of (or...)")
    (rewrite-catch-end)))


(defun rewrite-generate-and (rule where)
  (rewrite-note "(and")
  (let ((terms (cdr rule))
	term)
    (rewrite-catch-begin)
    (while terms
      (rewrite-generate-rule (car terms) where)
      (rewrite-throw-on-no-match)
      (setq terms (cdr terms)))
    (rewrite-note "end of (and...)")
    (rewrite-catch-end)))


(defun rewrite-construct-siblings (sibs next)
  (cond 
   ((null sibs)
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s;\n" next)))
   ((listp sibs)
    (rewrite-construct-siblings (cdr sibs) next)
    (indent-to rewrite-current-indent 1)
    (insert "__sibling = __new_tree_start;\n")
    (rewrite-save-var "__sibling")
    (rewrite-construct (car sibs))
    (rewrite-restore-var)
    (rewrite-if-begin "__new_tree_end != NULL")
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set "__new_tree_end" 'sibling "__sibling"))
    (indent-to rewrite-current-indent 1)
    (insert "\n")
    ;;(rewrite-if-else)
    ;;(indent-to rewrite-current-indent 1)
    ;;(insert "__new_tree = __sibling;\n")
    (rewrite-if-end))
   ((symbolp sibs)
    (indent-to rewrite-current-indent 1)
    (insert (format "__sibling = %s_start;\n"
		    (rewrite-format-variable
		     (rewrite-get-variable-name sibs)))))

   (t 
    (error "bogus constructor -> %s" sibs))))


(defun rewrite-is-variable-field (sym)
  (let ((str (symbol-name sym)))
    (and (= (aref (symbol-name sym) 0) ?$)
	 (string-match "\\." str))))


(defun rewrite-parse-variable-field (sym)
  (let ((str (symbol-name sym)))
    (string-match
     "\\$\\([A-Za-z_][A-Za-z0-9_]*\\)\\.\\([A-Za-z_][A-Za-z0-9_]*\\)"
     str)

    (if (not (and (= (match-beginning 0) 0)
		  (= (match-end 0) (length str))))
	(error "bogus $variable in replacement -> %s"))

    (cons 
     (substring str (match-beginning 1) (match-end 1))
     (intern (substring str (match-beginning 2) (match-end 2))))))


(defun rewrite-construct-parent (token)
  (if (not (symbolp token))
      (error "bogus token in replacement -> %s" token))

  (let (tok)
    (rewrite-note (format "constructing node with token %s" token))
    (cond
     ((rewrite-is-token-symbol token)
      (setq tok token))

     ((rewrite-is-variable-field token)
      (let ((field (rewrite-parse-variable-field token)))
	(setq tok (rewrite-get (concat (rewrite-format-variable (car field))
				       "_start")
			       (cdr field)))))
     
     (t
      (error "bogus token in replacement -> %s" token)))
      
    (indent-to rewrite-current-indent 1)
    (insert "{\n")
    (indent-to (+ rewrite-current-indent 2) 1)
    (insert (rewrite-declare-token "__token" tok))
    (insert "\n")
    (indent-to (+ rewrite-current-indent 2) 1)
    (insert (rewrite-declare-node "__child" "__new_tree_start"))
    (insert "\n")
    (indent-to (+ rewrite-current-indent 2) 1)
    (insert "__new_tree_start = " (rewrite-create-node "__token") ";\n")
    (indent-to (+ rewrite-current-indent 2) 1)
    (insert (rewrite-set "__new_tree_start" 'file_line "__file, __line") "\n")
    
    (indent-to (+ rewrite-current-indent 2) 1)
    (insert "__new_tree_end = __new_tree_start;\n")
    (indent-to (+ rewrite-current-indent 2) 1)
    (insert (rewrite-set "__new_tree_start" 'child "__child"))
    (insert "\n")
    (indent-to rewrite-current-indent 1)
    (insert "}\n")))


(defun rewrite-format-constructor-arg (arg)
  (if (and (symbolp arg)
	   (rewrite-is-variable-field arg))
      (let ((field (rewrite-parse-variable-field arg)))
	(rewrite-get (concat (rewrite-format-variable (car field)) "_start")
		     (cdr field)))
    arg))


(defun rewrite-construct (tree)
  (cond
   ((null tree)
    ;; do nothing
    )

   ((vectorp tree)
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s;\n"
		    (apply 'rewrite-create-node 
			   (mapcar 'rewrite-format-constructor-arg tree))))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_end = __new_tree_start;\n"))
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set "__new_tree_start" 'file_line "__file, __line") "\n"))

   ((and (symbolp tree)
	 (= (aref (symbol-name tree) 0) ?$))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s_start;\n"
		    (rewrite-format-variable
		     (rewrite-get-variable-name tree))))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_end = %s_end;\n" 
		    (rewrite-format-variable
		     (rewrite-get-variable-name tree)))))

   ((and (symbolp tree)
	 (rewrite-is-token-symbol tree))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s;\n" (rewrite-create-node tree)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_end = __new_tree_start;\n"))
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set "__new_tree_start" 'file_line "__file, __line") "\n"))

   ((integerp tree)
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s;\n"
		    (rewrite-create-integer-node tree)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_end = __new_tree_start;\n"))
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set "__new_tree_start" 'file_line "__file, __line") "\n"))

   ((stringp tree)
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s;\n"
		    (rewrite-create-string-node tree)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_end = __new_tree_start;\n"))
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set "__new_tree_start" 'file_line "__file, __line") "\n"))
    
   ((floatp tree)
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s;\n"
		    (rewrite-create-float-node tree)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_end = __new_tree_start;\n"))
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set "__new_tree_start" 'file_line "__file, __line") "\n"))

   ((and (listp tree)
	 (eq (car tree) 'quote)
	 (symbolp (nth 1 tree))
	 (null (nthcdr 2 tree)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_start = %s;\n"
		    (rewrite-create-symbol-node (nth 1 tree))))
    (indent-to rewrite-current-indent 1)
    (insert (format "__new_tree_end = __new_tree_start;\n"))
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set "__new_tree_start" 'file_line "__file, __line") "\n"))
	 
   ((and (listp tree)
	 (eq (car tree) 'if))
    (let ((test-expr (nth 1 tree))
	  (then-tree (nth 2 tree))
	  (else-tree (nth 3 tree)))
      (rewrite-if-begin (rewrite-format-c-code test-expr))
      (rewrite-construct then-tree)
      (if else-tree
	  (progn
	    (rewrite-if-else)
	    (rewrite-construct else-tree)))
      (rewrite-if-end)))

   ((listp tree)
    (rewrite-construct-siblings (cdr tree) "NULL")
    (rewrite-construct-parent (car tree)))

   (t
    (error "bogus stuff in replacement tree -> %s" tree))))


(defun rewrite-generate-not (rule where)
  (if (= (length rule) 2)
      (error "rewrite-generate-not: bogus value for rule -> %s" rule))
  (rewrite-generate-rule (cadr rule) where)
  (rewrite-invert-match))


(defun rewrite-generate-let (rule where)
  (if (/= (length rule) 3)
      (error "rewrite-generate-let: bogus value for rule -> %s" rule))

  (let ((locals (nth 1 rule))
	(body (nth 2 rule)))

    (rewrite-note "(let")
    (indent-to rewrite-current-indent 1)
    (insert "{\n")
    (setq rewrite-current-indent (+ rewrite-current-indent 2))

    (cond
     ((stringp locals)
      (indent-to rewrite-current-indent 1)
      (insert locals)
      (newline))
     ((listp locals)
      (let ((l locals))
	(while l
	  (indent-to rewrite-current-indent 1)
	  (insert (car l))
	  (newline)
	  (setq l (cdr l)))))
     (t
      (error "malformed let: %s" rule)))

    (newline)
    (rewrite-generate-rule body where)

    (rewrite-note "end of (let...)")
    (setq rewrite-current-indent (- rewrite-current-indent 2))
    (indent-to rewrite-current-indent 1)
    (insert "}\n")))


(defun rewrite-insert-node (what-begin what-end where)
  (cond
   ((eq (car where) 'pointer)
    (indent-to rewrite-current-indent 1)
    (insert (format "*%s = %s;" (cdr where) what-begin))
    (insert "\n"))
   ((eq (car where) 'parent)
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set (cdr where) 'child what-begin))
    (insert "\n"))
   ((eq (car where) 'parent-firstonly)
    (rewrite-if-begin "__first")
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set (cdr where) 'child what-begin))
    (insert "\n")
    (rewrite-if-else)
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set (cdr where) 'sibling what-begin))
    (insert "\n")
    (rewrite-if-end))
   ((eq (car where) 'sibling)
    (indent-to rewrite-current-indent 1)
    (insert (rewrite-set (cdr where) 'sibling what-begin))
    (insert "\n"))
   (t
    (error "bogus value for 'where' -> %s" where)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__tree = %s;\n" what-end)))


(defun rewrite-generate-replace (rule where)
  (let ((repl-rule (cadr rule))
	(replacement (cddr rule)))
    (rewrite-note "(replace")
    (rewrite-generate-rule repl-rule where)
    (rewrite-if-match-begin)

    (rewrite-note "(replace...) rule matched, now construct replacement")
    (indent-to rewrite-current-indent 1)
    (insert "{\n")
    (setq rewrite-current-indent (+ rewrite-current-indent 2))

    (indent-to rewrite-current-indent 1)
    (insert "char *__file = " (rewrite-get "__tree" 'file) ";\n")

    (indent-to rewrite-current-indent 1)
    (insert "int __line = " (rewrite-get "__tree" 'line) ";\n")

    (indent-to rewrite-current-indent 1)
    (insert (rewrite-declare-node "__new_tree_start"))
    (insert "\n")

    (indent-to rewrite-current-indent 1)
    (insert (rewrite-declare-node "__new_tree_end"))
    (insert "\n")

    (indent-to rewrite-current-indent 1)
    (insert (rewrite-declare-node "__sibling"))
    (insert "\n")

    (rewrite-construct-siblings replacement (rewrite-get "__tree" 'sibling))

    (rewrite-insert-node "__new_tree_start" "__new_tree_end" where)

    (setq rewrite-current-indent (- rewrite-current-indent 2))
    (indent-to rewrite-current-indent 1)
    (insert "}\n")
    (rewrite-note "end of (replace...)")
    (rewrite-if-end)))


(defun rewrite-generate-call-rewrite (rule where)
  (let ((name (cadr rule)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__tree = %s (__tree);\n" name))
    (rewrite-insert-node "__tree" "__tree" where)))


(defun rewrite-generate-call-predicate (rule where)
  (let ((name (cadr rule)))
    (indent-to rewrite-current-indent 1)
    (insert (format "__match = %s (&__tree);\n" name))))


(defun rewrite-generate-rule (rule where)
  (cond
   ((eq rule '*)
    (rewrite-match-non-null))

   ((and (symbolp rule)
	 (= (aref (symbol-name rule) 0) ?$))
    (rewrite-note-match rule)
    (rewrite-match-non-null)
    (rewrite-if-match-begin)
    (rewrite-bind-symbol rule "__tree" "__tree")
    (rewrite-if-end))

   ((and (listp rule)
	 (eq (car rule) 'quote)
	 (symbolp (nth 1 rule))
	 (null (nthcdr 2 rule)))
    (rewrite-note-match rule)
    (rewrite-generate-special 'rewrite-match-symbol-node (cdr rule)))
   
   ((integerp rule)
    (rewrite-note-match (int-to-string rule))
    (rewrite-generate-special 'rewrite-match-integer-node (list rule)))

   ((floatp rule)
    (rewrite-note-match (format "%f" rule))
    (rewrite-generate-special 'rewrite-match-float-node (list rule)))

   ((stringp rule)
    (rewrite-note-match rule)
    (rewrite-generate-special 'rewrite-match-string-node (list rule)))

   ((vectorp rule)
    (rewrite-note-match rule)
    (let ((args (mapcar 'identity rule)))
      (rewrite-generate-special 'rewrite-match-node args)))

   ((eq (car rule) 'let)
    (rewrite-generate-let rule where))

   ((eq (car rule) 'test)
    (rewrite-generate-test rule))

   ((eq (car rule) 'or)
    (rewrite-generate-or rule where))

   ((eq (car rule) 'and)
    (rewrite-generate-and rule where))

   ((eq (car rule) 'not)
    (rewrite-generate-not rule where))

   ((eq (car rule) 'call-rewrite)
    (rewrite-generate-call-rewrite rule where))

   ((eq (car rule) 'call-predicate)
    (rewrite-generate-call-predicate rule where))

   ((eq (car rule) 'replace)
    (rewrite-generate-replace rule where))

   ((rewrite-is-token-set (car rule))
    (rewrite-generate-pattern rule))

   (t
    (error "bogus rule -> %s" rule))))


(defun rewrite-get-vars (rule table)
  (cond
   ((null rule)
    nil)

   ((symbolp rule)
    (let ((char (aref (symbol-name rule) 0))
	  var-name)
      (if (or (= char ?$) (= char ?=))
	  (progn
	    (if (rewrite-is-variable-field rule)
		(setq var-name (car (rewrite-parse-variable-field rule)))
	      (setq var-name (rewrite-get-variable-name rule)))
	    (intern (rewrite-format-variable var-name) table)))))

   ((listp rule)
    (let ((elts rule))
      (while (and elts (listp elts))
	(rewrite-get-vars (car elts) table)
	(setq elts (cdr elts)))
      (if elts
	  (rewrite-get-vars elts table))))

   (t
    nil)))

   
(defun rewrite-declare-vars (rule)
  (let ((table (make-vector 271 nil)))
    (rewrite-get-vars rule table)
    (mapatoms (flambda (var)
		(if var
		    (progn
		      (indent-to rewrite-current-indent 1)
		      (insert (rewrite-declare-node (format "%s_start" var)))
		      (insert "\n")
		      (indent-to rewrite-current-indent 1)
		      (insert (rewrite-declare-node (format "%s_end" var)))
		      (insert "\n"))))
	      table)))


(defun rewrite-do-rewrite (name flags rules)
  (mapcar (flambda (flag)
	    (or (memq flag '(:preorder :postorder :static :skip_children))
		(error "define-rewrite: invalid flag -> %s" flag)))
	  flags)

  (save-excursion
    (unwind-protect
	(progn
	  (set-buffer (get-buffer-create "*rewrite*"))

	  (let* ((postwalk (not (memq ':preorder flags)))
		 (walker-name (format "__%s_%swalker"
				      (symbol-name name)
				      (if postwalk "post" "pre"))))

	    (insert "static\n")
	    (insert "nl_walk_status\n")
	    (insert (format "%s (nl_ast *__root_p, void *__ptr)\n"
			    walker-name))
	    (insert "{\n")
	    (insert "  nl_ast __tree;\n")
	    (insert "  int __match;\n")
	    (insert "  nl_walk_status __status = nl_walk_status_continue;\n")

	    (mapcar (flambda (rule)
		      (insert "\n")
		      (insert "  /* rule: ")
		      (insert (rewrite-string-replace-match 
			       "\n\\(.\\)"
			       (rewrite-string-replace-match 
				"\t" 
				(rewrite-string-replace-match
				 "\\\\\\."
				 (pp-to-string rule)
				 ".")
				"        ")
			       "\n           \\1"))
		      (insert "  */\n")
		      (insert "  {\n")

		      (setq rewrite-current-indent 4)
		      (rewrite-declare-vars rule)
		      (insert "\n")

		      (insert "    __tree = *__root_p;\n")
		      (rewrite-generate-rule rule '(pointer . "__root_p"))

		      (insert "  }\n")

		      (if (memq ':skip_children flags)
			  (progn
			    (rewrite-if-match-begin)
			    (indent-to 4)
			    (insert "__status = nl_walk_status_skip;\n")
			    (rewrite-if-end))))
		    rules)

	    (insert "  return nl_walk_status_continue;\n")
	    (insert "}\n\n")

	    (if (memq ':static flags)
		(insert "static\n"))
	    (insert "nl_ast\n")
	    (insert (symbol-name name))
	    (insert " (nl_ast tree)\n")
	    (insert "{\n")
	    (insert "  nl_ast root = tree;\n")
	    (insert (format "  nl_ast_walk (&root, %s, %s, NULL);\n"
			    (if postwalk "NULL" walker-name)
			    (if postwalk walker-name "NULL")))
	    (insert "  return root;\n")
	    (insert "}\n\n")
	    (buffer-string)))

      (kill-buffer (current-buffer)))))


(defmacro define-rewrite (name &rest body)
  (let ((bodyform body)
	(flags nil))

    (while (and (symbolp (car bodyform))
		(eq (aref (symbol-name (car bodyform)) 0) ?:))
      (setq flags (cons (car bodyform) flags)
	    bodyform (cdr bodyform)))

    `(rewrite-do-rewrite (quote ,name) (quote ,flags) (quote ,bodyform))))


(defun rewrite-do-predicate (name flags rule)
  (mapcar (flambda (flag)
	    (or (memq flag '(:static))
		(error "define-predicate: invalid flag -> %s" flag)))
	  flags)

  (save-excursion
    (unwind-protect
	(progn
	  (set-buffer (get-buffer-create "*rewrite*"))

	  (if (memq ':static flags)
	    (insert "static\n"))

	  (insert "int\n")
	  (insert (format "%s (nl_ast *__root_p)\n" name))
			  
	  (insert "{\n")
	  (insert "  nl_ast __tree;\n")
	  (insert "  int __match;\n")

	  (insert "\n")
	  (insert "  /* rule: ")
	  (insert (rewrite-string-replace-match 
		   "\n\\(.\\)"
		   (rewrite-string-replace-match 
		    "\t" 
		    (rewrite-string-replace-match
		     "\\\\\\."
		     (pp-to-string rule)
		     ".")
		    "        ")
		   "\n           \\1"))
	  (insert "  */\n")
	  (insert "  {\n")

	  (setq rewrite-current-indent 4)
	  (rewrite-declare-vars rule)
	  (insert "\n")

	  (insert "    __tree = *__root_p;\n")
	  (rewrite-generate-rule rule '(pointer . "__root_p"))

	  (insert "  }\n")

	  (insert "  return __match;\n")
	  (insert "}\n\n")
	  (buffer-string))

      (kill-buffer (current-buffer)))))


(defmacro define-predicate (name &rest body)
  (let ((bodyform body)
	(flags nil))

    (while (and (symbolp (car bodyform))
		(eq (aref (symbol-name (car bodyform)) 0) ?:))
      (setq flags (cons (car bodyform) flags)
	    bodyform (cdr bodyform)))

    `(rewrite-do-predicate (quote ,name) (quote ,flags)
			   (quote ,(car bodyform)))))
