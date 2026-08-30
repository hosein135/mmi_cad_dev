-*-emacs-lisp-*-

(define-predicate ast2g_is_register (reset sense clock d q)
  (ALWAYS 
   (or (POSEDGE =sense $clock)
       (NEGEDGE =sense $clock))
	  