(defmacro setl (var-list values)
  (let ((setq-form nil)
	(vars var-list))

    (while vars
      (setq setq-form (cons '(car --setl-tmp--)
			    (cons (car vars) setq-form)))
      (setq vars (cdr vars))
      (if vars
	  (setq setq-form (cons '(cdr --setl-tmp--)
				(cons '--setl-tmp-- setq-form)))))

    (setq setq-form `(setq --setl-tmp-- --setl-values--
			   ,@(nreverse setq-form)))

    `(let ((--setl-values-- ,values)
	   --setl-tmp--)
       (if (/= (length --setl-values--) ,(length var-list))
	   (error "setl: wrong number of values, %d instead of %d in %s"
		  (length --setl-values--) ,(length var-list) --setl-values--)
	 ,setq-form
	 --setl-values--))))

(provide 'setl)
