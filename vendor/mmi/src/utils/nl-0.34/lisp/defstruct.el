(defconst defstruct-rcsid
  "$Id: defstruct.el,v 1.1 1996/10/03 05:10:23 jka Exp $")


;;; $Log: defstruct.el,v $
;;; Revision 1.1  1996/10/03 05:10:23  jka
;;; Initial revision
;;;


(defun defstruct-constructor-name (name)
  (intern (concat (symbol-name name) "-cons")))

(defun defstruct-constructor-def (name fields)
  `(defmacro ,(defstruct-constructor-name name) ,(cons '&optional fields)
     (cons 'vector
	   (cons '(quote ,name)
		 ,(cons 'list fields)))))


(defun defstruct-predicate-name (name)
  (intern (concat (symbol-name name) "-p")))

(defun defstruct-predicate-def (name fields)
  `(defmacro ,(defstruct-predicate-name name) (x)
     (list 'and
	   (list 'vectorp x)
	   (list '= (list 'length x) ,(1+ (length fields)))
	   (list 'eq (list 'aref x 0) '(quote ,name)))))


(defun defstruct-selector-name (name field)
  (intern (concat (symbol-name name) "-" (symbol-name field))))

(defun defstruct-selector-def (name field index)
  `(defmacro ,(defstruct-selector-name name field) (x)
     (list 'aref x ,index)))


(defun defstruct-settor-name (name field)
  (intern (concat (symbol-name name) "-set-" (symbol-name field))))

(defun defstruct-settor-def (name field index)
  `(defmacro ,(defstruct-settor-name name field) (x y)
     (list 'aset x ,index y)))


(defmacro defstruct (name fields)
  (let ((constructor (defstruct-constructor-def name fields))
	(predicate (defstruct-predicate-def name fields))
	(accessors nil)
	(return-value `(quote ,name))
	(f fields)
	(index 1))

    (while f
      (setq accessors (cons (defstruct-selector-def name (car f) index)
			    (cons (defstruct-settor-def name (car f) index)
				  accessors))
	    index (1+ index)
	    f (cdr f)))

    (cons 'prog1
	  (cons return-value
		(cons constructor
		      (cons predicate accessors))))))


(defmacro macro-to-function (mac-sym)
  (let* ((mac (eval mac-sym))
	 (def (symbol-function mac))
	args)
    (cond ((not (eq (car def) 'macro))
	   (error "Not a macro."))
	  ((byte-code-function-p (cdr def))
	   (setq args (aref 0 (cdr def))))
	  (t
	   (setq args (nth 2 def))))
    (list `function `(lambda ,args (,mac ,@args)))))


(provide 'defstruct)
