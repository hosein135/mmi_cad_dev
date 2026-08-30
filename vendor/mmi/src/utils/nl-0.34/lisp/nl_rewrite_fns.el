(defvar rewrite-tokens
  '(
    (ALWAYS nl_token_always)
    (AND nl_token_and)
    (ANDAND nl_token_andand)
    (AND_REDUCE nl_token_and_reduce)
    (BEGIN nl_token_begin)
    (BIN nl_token_bin)
    (BITNOT nl_token_bitnot)
    (BLOCK_ASSIGN nl_token_block_assign)
    (CALL nl_token_call)
    (CASE nl_token_case)
    (CASEX nl_token_casex)
    (CASEZ nl_token_casez)
    (CASE_ITEM nl_token_case_item)
    (CONCAT nl_token_concat)
    (DEC nl_token_dec)
    (DEFAULT nl_token_default)
    (EQ2 nl_token_eq2)
    (FULL_CASE nl_token_full_case)
    (FUNCALL nl_token_funcall)
    (HEX nl_token_hex)
    (ID nl_token_id)
    (IF nl_token_if)
    (IN nl_token_in)
    (LIST nl_token_list)
    (LOGNOT nl_token_lognot)
    (LREF nl_token_lref)
    (NAND nl_token_nand)
    (NEGEDGE nl_token_negedge)
    (NONBLOCK_ASSIGN nl_token_nonblock_assign)
    (NOR nl_token_nor)
    (NUMBER nl_token_number)
    (OCT nl_token_oct)
    (OR nl_token_or)
    (OROR nl_token_oror)
    (OR_REDUCE nl_token_or_reduce)
    (OUT nl_token_out)
    (PARALLEL_CASE nl_token_parallel_case)
    (POSEDGE nl_token_posedge)
    (REF nl_token_ref)
    (REPEAT_CONCAT nl_token_repeat_concat)
    (SHL nl_token_shl)
    (SHR nl_token_shr)
    (VARSHL nl_token_varshl)
    (VARSHR nl_token_varshr)
    (VNUM nl_token_vnum)
    (XNOR nl_token_xnor)
    (XNOR_REDUCE nl_token_xnor_reduce)
    (XOR nl_token_xor)
    (XOR_REDUCE nl_token_xor_reduce)
    ))


(defvar rewrite-token-table
  (let ((toks rewrite-tokens)
	(table (make-vector 101 nil)))

    (while toks
      (put 
       (intern (symbol-name (car (car toks))) table)
       'tokdef
       (cadr (car toks)))

      (setq toks (cdr toks)))

    table))

      
(defun rewrite-translate-token (token)
  (let* ((name (symbol-name token))
	 (toksym (intern-soft name rewrite-token-table)))
    (if toksym
	(get toksym 'tokdef)
      (error "Unrecognized token: %s" name))))


(defun rewrite-match-id-node (node name)
  (concat
   (format "nl_ast_token (%s) == nl_token_id"  node)
   " && "
   (format "strcmp (nl_id_ast_name ((nl_id_ast) %s), " node)
   (if (stringp name)
       (format "\"%s\"" name)
     (format "%s" name))
   ") == 0"))


(defun rewrite-match-vnum-node (node name)
  (concat
   (format "nl_ast_token (%s) == nl_token_vnum"  node)
   " && "
   (format "strcmp (nl_vnum_ast_bits ((nl_vnum_ast) %s), " node)
   (if (stringp name)
       (format "\"%s\"" name)
     (format "%s" name))
   ") == 0"))


(defun rewrite-match-number-node (node value)
  (concat
   (format "nl_ast_token (%s) == nl_token_number" node)
   " && "
   (format "nl_number_ast_value ((nl_number_ast) %s) == %s" node value)))


(defun rewrite-match-ref-node (token node object)
  (let ((tok (rewrite-translate-token token)))
    (concat
     (format "nl_ast_token (%s) == %s" node token)
     " && "
     (format "nl_ref_ast_object ((nl_ref_ast) %s) == %s" node object))))


(defun rewrite-match-in-node (node index)
  (concat
   (format "nl_ast_token (%s) == nl_token_in" node)
   " && "
   (format "nl_in_ast_index ((nl_in_ast) %s) == %s" node value)))


(defun rewrite-match-out-node (node index)
  (concat
   (format "nl_ast_token (%s) == nl_token_out" node)
   " && "
   (format "nl_out_ast_index ((nl_out_ast) %s) == %s" node value)))


(defun rewrite-match-other-node (token)
  (format "nl_ast_token (%s) == %s" token))


(defun rewrite-create-id-node (name)
  (format "(nl_ast) nl_id_ast_create (%s)" name))


(defun rewrite-create-symbol-node (name)
  (format "(nl_ast) nl_id_ast_create (\"%s\")" name))


(defun rewrite-create-number-node (value)
  (format "(nl_ast) nl_number_ast_create (%s)" value))


(defun rewrite-create-vnum-node (bits)
  (format "(nl_ast) nl_vnum_ast_create (\"%s\")" bits))


(defun rewrite-create-ref-node (obj)
  (format "(nl_ast) nl_ref_ast_create (nl_token_ref, %s)" obj))


(defun rewrite-create-lref-node (obj)
  (format "(nl_ast) nl_ref_ast_create (nl_token_lref, %s)" obj))


(defun rewrite-create-in-node (index)
  (format "(nl_ast) nl_in_ast_create (%s)" index))


(defun rewrite-create-out-node (index)
  (format "(nl_ast) nl_out_ast_create (%s)" index))


(defun rewrite-create-other-node (token)
  (format "nl_ast_create (%s)" token))


;;;
;;; rewrite.el interface functions begin here
;;;


(defun rewrite-declare-node (var &optional value)
  (if value
      (format "nl_ast %s = %s;" var value)
    (format "nl_ast %s = NULL;" var)))


(defun rewrite-declare-token (var &optional value)
  (if value
      (format "nl_token %s = %s;" var 
	      (if (symbolp value)
		  (rewrite-translate-token value)
		value))
    (format "nl_token %s = nl_token_null;" var)))


(defun rewrite-create-integer-node (n)
  (rewrite-create-number-node (concat n)))


(defun rewrite-create-string-node (n)
  (error "can't create string nodes"))


(defun rewrite-create-float-node (value)
  (error "can't create float nodes"))


(defun rewrite-create-node (token &rest args)
  (cond
   ((stringp token)
    (apply 'rewrite-create-other-node token args))
   ((eq token 'ID)
    (apply 'rewrite-create-id-node args))
   ((eq token 'NUMBER)
    (apply 'rewrite-create-number-node args))
   ((eq token 'VNUM)
    (apply 'rewrite-create-vnum-node args))
   ((eq token 'REF)
    (apply 'rewrite-create-ref-node args))
   ((eq token 'LREF)
    (apply 'rewrite-create-lref-node args))
   ((eq token 'IN)
    (apply 'rewrite-create-in-node args))
   ((eq token 'OUT)
    (apply 'rewrite-create-out-node args))
   (t
    (apply 'rewrite-create-other-node 
	   (rewrite-translate-token token) args))))


(defun rewrite-match-integer-node (node value)
  (rewrite-match-number-node node value))


(defun rewrite-match-string-node (node value)
  (rewrite-match-vnum-node node value))


(defun rewrite-match-node (node token &rest args)
  (cond
   ((stringp token)
    (apply 'rewrite-match-other-node token node args))
   ((eq token 'ID)
    (apply 'rewrite-match-id-node node args))
   ((eq token 'VNUM)
    (apply 'rewrite-match-vnum-node node args))
   ((eq token 'NUMBER)
    (apply 'rewrite-match-integer-node node args))
   ((eq token 'REF)
    (apply 'rewrite-match-ref-node token node args))
   ((eq token 'LREF)
    (apply 'rewrite-match-ref-node token node args))
   ((eq token 'IN)
    (apply 'rewrite-match-in-node node args))
   ((eq token 'OUT)
    (apply 'rewrite-match-out-node node args))
   (t
    (apply 'rewrite-match-other-node 
	   (rewrite-translate-token token) node args))))


(defun rewrite-compare-token (token var)
  (format "%s == %s" var (rewrite-translate-token token)))


(defun rewrite-get (node field)
  (cond
   ((eq field 'token)
    (format "nl_ast_token (%s)" node))
   ((eq field 'file)
    (format "nl_ast_file (%s)" node))
   ((eq field 'line)
    (format "nl_ast_line (%s)" node))
   ((eq field 'width)
    (format "nl_ast_width (%s)" node))
   ((eq field 'name)
    (format "nl_id_ast_name ((nl_id_ast) %s)" node))
   ((eq field 'in_index)
    (format "nl_in_ast_index ((nl_in_ast) %s)" node))
   ((eq field 'out_index)
    (format "nl_out_ast_index ((nl_out_ast) %s)" node))
   ((eq field 'value)
    (format "nl_number_ast_value ((nl_number_ast) %s)" node))
   ((eq field 'bits)
    (format "nl_vnum_ast_bits ((nl_vnum_ast) %s)" node))
   ((eq field 'object)
    (format "nl_ref_ast_object ((nl_ref_ast) %s)" node))
   ((eq field 'sibling)
    (format "nl_ast_sibling (%s)" node))
   ((eq field 'child)
    (format "nl_ast_child (%s)" node))
   (t
    (error "rewrite-get: invalid field -> %s" field))))


(defun rewrite-set (node field value)
  (cond
   ((eq field 'sibling)
    (format "nl_ast_set_sibling (%s, %s);" node value))
   ((eq field 'child)
    (format "nl_ast_set_child (%s, %s);" node value))
   ((eq field 'file_line)
    (format "nl_ast_set_file_line (%s, %s);" node value))
   (t
    (error "rewrite-set: invalid field -> %s" field))))
