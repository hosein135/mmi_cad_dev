(require 'flambda)


(defmacro define-schema (name &rest decls)
  `(schema-generate (quote ,name) (quote ,decls)))


(defun schema-do-walk (schema walker common)
  (let ((ok-nodes '(primitive require type enum class struct)))
    (mapcar 
     (flambda (sch)
       (if (eq (car sch) 'class)
	   (schema-do-walk (nthcdr 3 sch) walker (append common (nth 2 sch)))
	 (or (memq (car sch) ok-nodes)
	     (error 
	      (format (concat "schema error: invalid node type '%s' - "
			      "Should be one of %s")
		      (car sch) ok-nodes))))

       (apply walker sch common nil))
     
     schema)))


(defun schema-walk (schema walker)
  (schema-do-walk schema walker nil))


(defun schema-intern-types (schema table)
  (schema-walk
   schema
   (flambda (sch common)
     (setq sym (intern (symbol-name (nth 1 sch)) table))
     (put sym 'schema sch))))


(defun schema-check-types (schema table)
  (schema-walk
   schema
   (flambda (sch common)
     (if (memq (car sch) '(class struct))
	 (mapcar 
	  (flambda (field)
	    (let* ((field-type (nth 1 field))
		   (type (if (listp field-type) (car field-type) field-type))
		   (name (symbol-name type)))
	      (if (intern-soft name table)
		  nil
		(error "schema error: undeclared data type '%s'" name))))
	  (nth 2 sch))))))


(defun schema-declare-public-types (schema table)
  (schema-walk
   schema
   (flambda (sch common)
     (if (memq (car sch) '(class struct))
	 (mapcar 
	  (flambda (field)
	    (if (memq 'public (nthcdr 2 field))
		(schema-type-declare-public (nth 1 sch) table)))
	  (nth 2 sch))))))


(defun schema-build-type-table (schema)
  (let ((table (make-vector 1023 nil)))
    (schema-intern-types schema table)
    (schema-check-types schema table)
    (schema-declare-public-types schema table)
    table))


(defun schema-type-name (sch-name type table)
  (if (listp type)
      (car type)
    (let* ((sym (intern-soft (symbol-name type) table))
	   (prop (get sym 'schema)))
      (if (null prop)
	  (error "schema internal error: type not found '%s'" type)
	(cond
	 ((memq (car prop) '(primitive require))
	  (symbol-name sym))
	 ((eq (car prop) 'enum)
	  (format "%s_%s" sch-name sym))
	 ((eq (car prop) 'type)
	  (format "%s_%s" sch-name sym))
	 ((eq (car prop) 'struct)
	  (format "struct %s_%s_s *" sch-name sym))
	 ((eq (car prop) 'class)
	  (format "struct %s_%s_s *" sch-name sym))
	 (t
	  (error (format "schema-type-name(): unknown type -> %s"
			 (car prop)))))))))


(defun schema-type-declare-public (type table)
  (let* ((type-name (if (listp type) (car type) type))
	 (sym (intern-soft (symbol-name type) table)))
    (put sym 'public t)))


(defun schema-type-is-public (type table)
  (let* ((sym (intern (symbol-name type) table)))
    (or (get sym 'public)
	(eq (car (get sym 'schema)) 'class))))


(defun schema-generate (name schema)
  (let ((table (schema-build-type-table schema))
	(internal-header-file (format "%s_gen_int.h" name))
	(external-header-file (format "%s_gen_ext.h" name))
	(c-file (format "%s_gen.c" name))
	(internal-header-buf (get-buffer-create "*internal-header*"))
	(external-header-buf (get-buffer-create "*external-header*"))
	(c-file-buf (get-buffer-create "*c-file*")))
      
    (set-buffer internal-header-buf)
    (widen)
    (erase-buffer)

    (set-buffer external-header-buf)
    (widen)
    (erase-buffer)

    (set-buffer c-file-buf)
    (widen)
    (erase-buffer)

    (set-buffer internal-header-buf)
    (schema-generate-internal-types name schema table nil)
    (schema-generate-internal-prototypes name schema table nil)
    (write-region (point-min) (point-max) internal-header-file nil 'silent)
    (kill-buffer internal-header-buf)

    (set-buffer external-header-buf)
    (schema-generate-external-types name schema table nil)
    (schema-generate-external-prototypes name schema table nil)
    (write-region (point-min) (point-max) external-header-file nil 'silent)
    (kill-buffer external-header-buf)

    (set-buffer c-file-buf)
    (schema-generate-includes name schema)
    (insert (format "#include \"port.h\"\n"))
    (insert (format "#include \"%s_gen_ext.h\"\n" name))
    (insert (format "#include \"%s_gen_int.h\"\n" name))
    (insert "\n\n")
    (schema-generate-accessors name schema table nil)
    (write-region (point-min) (point-max) c-file nil 'silent)
    (kill-buffer c-file-buf)
    ))


(defun schema-generate-internal-types (name schema table common)
  (schema-walk
   schema
   (flambda (sch common)
     (if (memq (car sch) '(class struct))
	 (schema-generate-type name sch table common)))))


(defun schema-generate-external-types (name schema table common)
  (schema-walk
   schema
   (flambda (sch common)
     (if (memq (car sch) '(class struct))
	 (schema-generate-struct-typedef name sch)
       (schema-generate-type name sch table common)))))


(defun schema-generate-type (name sch table common)
  (cond
   ((eq (car sch) 'enum)
    (schema-generate-enum name sch)
    (schema-generate-enum-typedef name sch))

   ((eq (car sch) 'type)
    (schema-generate-random-typedef name sch table))

   ((eq (car sch) 'class)
    (schema-generate-union name sch)
    (schema-generate-struct name sch table common t))

   ((eq (car sch) 'struct)
    (schema-generate-struct name sch table common nil))))


(defun schema-generate-enum (name sch)
  (insert (format "enum %s_%s {\n " name (nth 1 sch)))
  (let ((first t)
	str)
    (mapcar
     (flambda (elt)
       (if first
	   (setq first nil)
	 (insert ","))
	   
       (setq str (format " %s_%s_%s" name (nth 1 sch) elt))

       (if (> (+ (current-column) (length str)) 78)
	   (insert "\n "))

       (insert str))
     (nth 2 sch)))

  (insert "\n};\n\n"))


(defun schema-generate-enum-typedef (name sch)
  (insert (format "typedef enum %s_%s %s_%s;\n\n"
		  name (nth 1 sch) name (nth 1 sch))))


(defun schema-generate-random-typedef (name sch table)
  (insert "typedef ")

  (if (stringp (nth 2 sch))
      (insert (format (nth 2 sch) (format "%s_%s" name (nth 1 sch))))
    (insert (format "%s %s_%s"
		    (schema-type-name name (nth 2 sch) table)
		    name (nth 1 sch))))

  (insert ";\n\n"))


(defun schema-generate-union (name sch)
  (insert (format "union %s_%s_u {\n" name (nth 1 sch)))

  (mapcar
   (flambda (sch)
     (if (or (eq (car sch) 'class)
	     (eq (car sch) 'struct))
	 (insert (format "  struct %s_%s_s %s;\n"
			 name (nth 1 sch) (nth 1 sch)))))
   (nthcdr 3 sch))

  (insert "};\n\n"))


(defun schema-generate-struct (name sch table common is-class)
  (insert (format "struct %s_%s_s {\n" name (nth 1 sch)))
  (schema-generate-fields common name table)
  (schema-generate-fields (nth 2 sch) name table)
  (if is-class
      (progn
	(insert (format "  char __extra_space[sizeof (union %s_%s_u)\n"
			name (nth 1 sch)))
	(schema-generate-field-sizeofs common name table)
	(schema-generate-field-sizeofs (nth 2 sch) name table)
	(insert (format "                    ];\n"))))
  (insert "};\n\n"))


(defun schema-generate-fields (fields name table)
  (mapcar
   (flambda (field)
     (insert (format "  %s %s;\n"
		     (schema-type-name name (nth 1 field) table)
		     (nth 0 field))))
   fields))


(defun schema-generate-field-sizeofs (fields name table)
  (mapcar
   (flambda (field)
     (insert (format "                     - sizeof (%s)\n"
		     (schema-type-name name (nth 1 field) table))))
   fields))


(defun schema-generate-struct-typedef (name sch)
  (insert (format "typedef struct %s_%s_s * %s_%s;\n\n"
		  name (nth 1 sch) name (nth 1 sch))))


(defun schema-generate-includes (name schema)
  (let ((include-table (make-vector 1023 nil)))
    (schema-walk
     schema
     (flambda (sch common)
       (if (eq (car sch) 'require)
	   (mapcar
	    (flambda (file)
	      (if (intern-soft (nth 2 sch) include-table)
		  nil
		(insert (format "#include \"%s\"\n" file))
		(intern (nth 2 sch) include-table)))
	    (nthcdr 2 sch)))))))
 

(defun schema-generate-accessors (name schema table common)
  (schema-walk
   schema
   (flambda (sch common)
     (cond
      ((eq (car sch) 'enum)
       (schema-generate-enum-to-string name sch)
       (schema-generate-string-to-enum name sch))
      
      ((memq (car sch) '(class struct))
       (schema-generate-struct-accessors name sch table common))))))


(defun schema-generate-enum-to-string (name sch)
  (insert "const char *\n")
  (insert (format "%s_%s_to_string (enum %s_%s e)\n"
		  name (nth 1 sch) name (nth 1 sch)))
  (insert "{\n")
  (insert "  switch (e) {\n")
  
  (mapcar
   (flambda (elt)
     (insert (format "  case %s_%s_%s: return \"%s\";\n"
		     name (nth 1 sch) elt elt)))
   (nth 2 sch))

  (insert (format "  default: return \"<invalid %s_%s>\";\n"
		  name (nth 1 sch)))

  (insert "  }\n")
  (insert "}\n\n"))


(defun schema-generate-string-to-enum (name sch)
  (insert (format "enum %s_%s\n" name (nth 1 sch)))
  (insert (format "%s_string_to_%s (char *str)\n"
		  name (nth 1 sch) name (nth 1 sch)))
  (insert "{\n")
  
  (mapcar
   (flambda (elt)
     (insert (format "  if ( strcasecmp (str, \"%s\") == 0 )\n" elt))
     (insert (format "    return %s_%s_%s;\n" name (nth 1 sch) elt)))
		      
   (nth 2 sch))

  (insert "\n")
  (insert (format "  return %s_%s_null;\n" name (nth 1 sch)))

  (insert "}\n\n"))


(defun schema-generate-struct-accessors (name sch table common)
  (schema-generate-field-accessors common name (nth 1 sch) table)
  (schema-generate-field-accessors (nth 2 sch) name (nth 1 sch) table))


(defun schema-generate-field-accessors (fields name obname table)
  (mapcar
   (flambda (field)
     (let ((field-name (schema-field-name field)))
       (if (memq 'readable (nthcdr 2 field))
	   (progn
	     (insert (format "%s\n" (schema-type-name name (nth 1 field)
						      table)))
	     (insert (format "%s_%s_%s (%s_%s %s)\n"
			     name obname field-name
			     name obname obname))
	     (insert "{\n")
	     (insert (format "  return %s->%s;\n" obname field-name))
	     (insert "}\n\n")))

       (if (memq 'writable (nthcdr 2 field))
	   (progn
	     (insert "void\n")
	     (insert (format "%s_%s_set_%s (%s_%s %s, %s %s)\n"
			     name obname field-name
			     name obname obname
			     (schema-type-name name (nth 1 field) table)
			     field-name))
	     (insert "{\n")
	     (insert (format "  %s->%s = %s;\n"
			     obname field-name field-name))
	     (insert "}\n\n\n")))))
   fields))


(defun schema-field-name (field)
  (substring (symbol-name (car field))
	     0
	     (string-match ":" (symbol-name (car field)))))


(defun schema-generate-enum-to-string-prototype (name sch)
  (insert "extern const char * ")
  (insert (format "%s_%s_to_string (enum %s_%s);\n\n" 
		  name (nth 1 sch) name (nth 1 sch))))


(defun schema-generate-string-to-enum-prototype (name sch)
  (insert (format "extern %s_%s " name (nth 1 sch)))
  (insert (format "%s_string_to_%s (char *);\n\n" name (nth 1 sch))))


(defun schema-generate-internal-prototypes (name schema table common)
  (schema-walk
   schema
   (flambda (sch common)
     (cond
      ((memq (car sch) '(class struct))
       (schema-generate-struct-accessor-prototypes name sch table common
						   'internal))))))


(defun schema-generate-external-prototypes (name schema table common)
  (schema-walk
   schema
   (flambda (sch common)
     (cond
      ((eq (car sch) 'enum)
       (schema-generate-enum-to-string-prototype name sch)
       (schema-generate-string-to-enum-prototype name sch))
      
      ((memq (car sch) '(class struct))
       (schema-generate-struct-accessor-prototypes name sch table common
						   'external))))))


(defun schema-generate-struct-accessor-prototypes (name sch table common scope)
  (schema-generate-field-accessor-prototypes common name (nth 1 sch)
					     table scope)
  (schema-generate-field-accessor-prototypes (nth 2 sch) name (nth 1 sch)
					     table scope))


(defun schema-generate-field-accessor-prototypes (fields name obname table
							 scope)
  (mapcar
   (flambda (field)
     (let ((field-name (schema-field-name field)))
       (if (or (and (eq scope 'internal)
		    (not (memq 'public (nthcdr 2 field))))
	       (and (eq scope 'external)
		    (memq 'public (nthcdr 2 field))))

	   (if (memq 'readable (nthcdr 2 field))
	       (progn
		 (insert "extern ")
		 (insert (format "%s " (schema-type-name name (nth 1 field)
							 table)))
		 (insert (format "%s_%s_%s (%s_%s);\n\n"
				 name obname field-name
				 name obname)))))

       (if (eq scope 'internal)
	   (if (memq 'writable (nthcdr 2 field))
	       (progn

		 (insert "extern ")
		 (insert "void ")
		 (insert (format "%s_%s_set_%s (%s_%s, %s);\n\n"
				 name obname field-name
				 name obname
				 (schema-type-name name (nth 1 field)
						   table))))))))
   fields))


(provide 'schema)
