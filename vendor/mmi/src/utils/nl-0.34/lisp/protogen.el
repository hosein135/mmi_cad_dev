(require 'flambda)
(require 'defstruct)


(defstruct cfun (name scope returns args doc))


(defvar protogen-internal-header "proto_int.h")
(defvar protogen-external-header "proto_ext.h")
(defvar protogen-doc-file "doc.t")


(defun protogen-do-batch ()
  (write-region "" nil protogen-external-header nil 'silent)
  (write-region "" nil protogen-internal-header nil 'silent)
  (write-region "" nil protogen-doc-file nil 'silent)
  (mapcar
   (flambda (file)
     (message "Generating prototypes and documentation for %s" file)
     (find-file file)
     (write-region (format "/* %s */\n\n" file) nil protogen-external-header t
		   'silent)
     (write-region (format "/* %s */\n\n" file) nil protogen-internal-header t
		   'silent)
     (protogen-gen-buffer)
     (write-region "\n\n" nil protogen-external-header t 'silent)
     (write-region "\n\n" nil protogen-internal-header t 'silent)
     (kill-buffer (current-buffer)))
   command-line-args-left))


(defun protogen-gen-buffer ()
  (let ((funs (protogen-get-functions)))
    (mapcar
     (flambda (fun)
       (cond
	((eq (cfun-scope fun) 'static)
	 )
	((eq (cfun-scope fun) 'internal)
	 (protogen-gen-prototype fun protogen-internal-header))
	((eq (cfun-scope fun) 'exported)
	 (protogen-gen-prototype fun protogen-external-header)
	 (if (cfun-doc fun)
	     (protogen-gen-doc fun protogen-doc-file)))
	(t
	 (error "%s" fun))))
     funs)))


(defun protogen-gen-prototype (fun file)
  (write-region
   (concat (format "extern %s %s (" (cfun-returns fun) (cfun-name fun))
	   (if (cfun-args fun)
	       (mapconcat 'car (cfun-args fun) ", ")
	     "void")
	   ");\n")
   nil file t 'silent))


(defun protogen-gen-doc (fun file)
  (save-window-excursion
    (set-buffer (get-buffer-create " *proto-doc*"))
    (widen) (erase-buffer)
    (insert (cfun-doc fun))

    (goto-char (point-min))
    (while (search-forward "\n" nil t)
      (replace-match " " nil nil))
    (goto-char (point-min))
    (fill-paragraph nil)
    (indent-region (point-min) (point-max) 4)

    (goto-char (point-min))
    (insert (format "\n\n%s %s (" (cfun-returns fun) (cfun-name fun)))
    (insert (if (cfun-args fun)
		(mapconcat (flambda (arg)
			     (concat (car arg) " " (cdr arg)))
			   (cfun-args fun)
			   ", ")
	      "void"))
    (insert ")\n\n")

    (write-region (point-min) (point-max) file t 'silent)))


(defun protogen-is-forward ()
  (save-excursion
    (forward-char -1)
    (forward-sexp 1)
    (looking-at "[ \t\n]*;")))
       

(defun protogen-get-functions ()
  (let* ((symbol+ "[A-Za-z0-9_]+")
	 (whitespace "[ \t\n\r\f]")
	 (whitespace+ (concat whitespace "+"))
	 (whitespace* (concat whitespace "*"))
	 (pointer (concat "\\(" whitespace* (regexp-quote "*") "+"
			  "\\|" whitespace "\\)"))
	 (doc-start (concat "^" (regexp-quote "/**")))
	 (doc-end   (regexp-quote "**/"))
	 (doc-body  "\\([^*]+\\|\\*[^*/]\\|\\*\\*[^/]\\)+")
	 (static "\\(^static\\)")
	 (exported (concat "\\(^"
			   (regexp-quote "/*")
			   "[ \t]*exported[ \t]*"
			   (regexp-quote "*/")
			   "\\)"))
	 (internal (concat "\\(^"
			   (regexp-quote "/*")
			   "[ \t]*internal[ \t]*"
			   (regexp-quote "*/")
			   "\\)"))
	 (funs nil))
    
    (save-excursion
      (goto-char (point-min))

      (while (re-search-forward
	      (concat "\\(" doc-start whitespace*
		      "\\(" doc-body "\\)"
		      doc-end whitespace* "\\)?"
		      "\\(" static "\\|" exported "\\|" internal "\\)"
		      whitespace+
		      "\\(" symbol+ pointer "\\)" whitespace*
		      "\\(" symbol+ "\\)" whitespace* "(")
	      nil t)

	(if (protogen-is-forward)
	    (progn
	      (forward-char -1)
	      (forward-sexp 1))
	  (let ((doc-string (and (match-beginning 2)
				 (buffer-substring (match-beginning 2)
						   (match-end 2))))
		(ret-type (buffer-substring (match-beginning 8) (match-end 8)))
		(fun-name (buffer-substring (match-beginning 10) (match-end 10)))
		scope
		args)

	    (if (/= ?* (aref ret-type (1- (length ret-type))))
		(setq ret-type (substring ret-type 0 -1)))

	    (cond
	     ((match-beginning 5)
	      (setq scope 'static))
	     ((match-beginning 6)
	      (setq scope 'exported))
	     ((match-beginning 7)
	      (setq scope 'internal)))

	    (forward-char -1)
	    (if (looking-at (concat "(" whitespace* "void" whitespace* ")"))
		(progn
		  (goto-char (match-end 0))
		  (setq args nil))
	      (while (not (looking-at ")"))
		(forward-char 1)
		(if (looking-at (concat whitespace*
					(regexp-quote "...")
					whitespace*))
		    (progn
		      (goto-char (match-end 0))
		      (setq args (cons (list "...") args)))
		  (re-search-forward (concat whitespace* "\\([^,)]+\\)"))
		  (setq args (cons (protogen-extract-arg 
				    (buffer-substring (match-beginning 1)
						      (match-end 1)))
				   args))))

	      (setq args (nreverse args)))

	    (setq funs (cons (cfun-cons fun-name scope ret-type args doc-string)
			     funs)))
	    
	  (search-forward "{")
	  (forward-char -1)
	  (forward-sexp 1))))

    (nreverse funs)))


(defun protogen-extract-arg (str)
  (string-match "[ \n]*\\([A-Za-z0-9_]+\\)[ \n]*$" str)
  (cons (substring str 0 (match-beginning 0))
	(substring str (match-beginning 1) (match-end 1))))


