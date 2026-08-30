(defmacro flambda (args &rest body)
  (list 'function `(lambda ,args ,@body)))


(put 'flambda 'lisp-indent-function 'defun)


(provide 'flambda)
