(define-rewrite if_to_case
  (replace
   (IF *=test_expr *=then_stmt &optional *=else_stmt)
   (CASE (OR_REDUCE $test_expr) (LIST PARALLEL_CASE)
	 (CASE_ITEM (LIST "1'b1") $then_stmt)
	 (if $else_stmt
	     (DEFAULT $else_stmt)))))


(define-rewrite case_expr
  (replace
   (CASE $expr &rest =rest)
   (BEGIN
    (BLOCK_ASSIGN $expr (LREF $var))
    (CASE (REF $var) $rest))))


(define-rewrite case_expr
  (replace
   (and
    ((CASE CASEX CASEZ) =case *=expr &rest =body)
    "($var = v2nl_temp_id (), 1)")
   (BEGIN
    (BLOCK_ASSIGN $expr (LREF $var))
    ($case.token (REF $var) $rest))))


(define-rewrite foo
  (replace
   (REF ID >$id)
   (LREF $id)))


(define-rewrite explicit_case ()
  ((or CASE CASEX CASEZ) $test_expr $pragmas
   (repeat
    (CASE_ITEM 
     (replace
      (LIST $term1 &rest $terms)
      (OR_REDUCE $term1 $terms))
     &rest))
   &rest))


(define-rewrite explicit_case ()
  (replace
   ((CASE CASEX CASEZ) =case $case_expr "$var = v2nl_new_id ();"
    (LIST &rest=pragmas)
    (repeat
     (CASE_ITEM 
      (replace
       (LIST (repeat 
	      (replace 
	       $term
	       (EQ2 (REF $var) $term)))
	     =terms)
       (OR_REDUCE $terms))
      &rest)) =branches &rest =default)
   (BEGIN
    (BLOCK_ASSIGN $case_expr (LREF $var))
    ($case.token "1'b1" (LIST . $pragmas) $branches . $default)))


(define-rewrite lhs_refs ()
  ((or BLOCK_ASSIGN NONBLOCK_ASSIGN)
   $rhs
   (and $lhs (apply ref_to_lref $lhs))
   &optional $delay))


(define-rewrite ref_to_lref ()
  (replace
   (REF &rest $args)
   (LREF . $args)))


($tokvar TOKEN)

token-pattern
($token-var token-pattern)

&rest
node-pattern
$node-var
($node-var . node-pattern)


(or ($add . (+ $arg1 $arg2))
    ($sub . (- $arg1 $arg2))

