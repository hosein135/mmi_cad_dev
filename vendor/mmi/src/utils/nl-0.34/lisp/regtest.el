;;; Except for the COUNT argument to find-repeated-string and
;;; find-repeated-regexp, all arguments are Lisp strings.
;;;
;;; (assert CONDITION)
;;;    Causes the test to fail if CONDITION (a TCL expression) is not true.
;;;
;;; (run-command COMMAND LOG_STRING?)
;;;    Run a random TCL command.  LOG_STRING, if present, is the entry
;;;    made in the .log file for this command.  If LOG_STRING is not
;;;    supplied, the actual TCL command is placed in the .log file.
;;;    COMMAND can be a Lisp expression.  The purpose of the function
;;;    is to allow TCL commands to be formed at runtime.
;;;
;;; (checkpoint)
;;;    Sets the starting point for all find-* and dont-find-* commands.
;;;
;;; All the find- and dont-find- commands search the output starting from the
;;; most recent checkpoint and ending at the end of the output of the most
;;; recent TCL command.
;;;
;;; (find-string STRING+)
;;;    Search for a list of strings (in order).  Test fails if any of
;;;    the strings is not found.
;;;
;;; (find-regexp REGEXP+)
;;;    Same as find-string, except it looks for regular expressions.
;;;
;;; (dont-find-string STRING+)
;;;    Search for any of the listed strings (in any order).  The test
;;;    fails if any string is found.
;;;
;;; (dont-find-regexp REGEXP+)
;;;    Same as dont-find-string, except it looks for regular expressions.
;;;
;;; (find-repeated-string COUNT STRING+)
;;;    Search for a list of strings (in order) COUNT times.  Each
;;;    iteration of the search begins in the output where the previous
;;;    iteration ended (i.e. at the end of the last string found in
;;;    the previous iteration).  Test fails if any of the strings is
;;;    not found in any of the iterations.  (find-string STRING+) is
;;;    equivalent to (find-repeated-strings 1 STRING+).
;;;
;;; (find-repeated-regexp COUNT REGEXP+)
;;;    Similar to find-repeated-strings, but for regular expressions.
;;;    Test fails if any of the regular expressions is not found in
;;;    any of the iterations.  (find-regexp REGEXP+) is equivalent to
;;;    (find-repeated-regexp 1 REGEXP+).
;;;
;;; (find-string-after REGEXP STRING)
;;;    Look for an occurrence of STRING following the first occurrence
;;;    of REGEXP.  Test fails if either REGEXP or STRING is not found.
;;;
;;; (find-regexp-after REGEXP1 REGEXP2)
;;;    Same as (find-regexp REGEXP1 REGEXP2).
;;;
;;; (dont-find-string-after REGEXP STRING)
;;;    Look for an occurrence of STRING following the first occurrence
;;;    of REGEXP.  Test fails if STRING is found.
;;;
;;; (dont-find-regexp-after REGEXP1 REGEXP2)
;;;    Look for an occurrence of REGEXP2 following the first
;;;    occurrence of REGEXP1.  Test fails if REGEXP2 is found.
;;;


(defvar regtest-timeout 10.0)
(defvar regtest-output-buffer nil)
(defvar regtest-process nil)
(defvar regtest-prompt "% ")
(defvar regtest-wait-times nil)
(defvar regtest-include-wait-times nil)
(defvar regtest-dont-catch-errors nil)
(defvar regtest-dont-remove-tmp-dir nil)


(defun regtest-start-process ()
  (setq regtest-wait-times nil)
  (and (get-buffer "*regtest-output*")
       (kill-buffer (get-buffer "*regtest-output*")))
  (setq regtest-output-buffer (get-buffer-create "*regtest-output*"))
  (let ((cbuf (current-buffer)))
    (unwind-protect
	(progn
	  (set-buffer regtest-output-buffer)
	  (widen) (erase-buffer)

	  (setq regtest-process
		(apply 'start-process-shell-command "program"
		       regtest-output-buffer
		       regtest-program nil))

	  (set-process-sentinel regtest-process 'regtest-sentinel)
	  (sit-for 0.1 0 nil)
	  (regtest-wait-for-prompt 0))
      (set-buffer cbuf))))


(defun regtest-sentinel (process change)
  (save-window-excursion
    (set-buffer regtest-output-buffer)
    (move-marker (process-mark regtest-process) (point-max)))
  (throw 'failure 
	 (list 'FATALED
	       (concat "Process received: " (substring change 0 -1)))))


(defun regtest-make-temp-dir ()
  (let ((dir-name (concat temporary-file-directory
			  (make-temp-name "regtest-"))))
    (make-directory dir-name)
    (setq regtest-temp-dir-list (cons dir-name regtest-temp-dir-list))
    dir-name))


(defun regtest-run-command (command &optional log-string)
  (if (not (eq (process-status regtest-process) 'run))
      (throw 'failure (list 'FAILED "Process stopped running.")))
  (let ((cbuf (current-buffer)))
    (set-buffer regtest-output-buffer)

    (goto-char (point-max))
    (insert (or log-string command))
    (newline)
    (move-marker (process-mark regtest-process) (point))

    (unwind-protect
	(let ((start (point-max)))
	  (process-send-string regtest-process command)
	  (process-send-string regtest-process "\n")

	  (regtest-wait-for-prompt start)
	  (goto-char (point-max)))

      (set-buffer cbuf))))
    

(defun regtest-wait-for-prompt (start)
  (save-excursion
    (let ((done nil)
	  (i 0)
	  (total 0.0)
	  (interval 0.01)
	  (prompt-regexp (concat (regexp-quote regtest-prompt) "\\'")))
      (goto-char start)

      (accept-process-output)

      (if (re-search-forward prompt-regexp nil t)
	  (setq done t)

	(while (and (not done) (< total regtest-timeout))
	  (sit-for interval 0 t)
	  (accept-process-output)
	  (goto-char start)
	  (setq done (re-search-forward prompt-regexp nil t)
		total (+ total interval)
		interval (min 2.0 (* 2 interval)))))

      (setq regtest-wait-times (cons total regtest-wait-times))

      (if (not done)
	  (throw 'failure (list 'FAILED "Timeout waiting for prompt."))))))


(defun regtest-replace-match (regexp string newtext &optional literal global)
  "Replace first match of REGEXP in STRING with NEWTEXT.
If it does not match, nil is returned instead of the new string.
Optional arg LITERAL means to take NEWTEXT literally.
Optional arg GLOBAL means to replace all matches."
  (if global
      (let ((start 0))
	(while (string-match regexp string start)
	  (let ((from-end (- (length string) (match-end 0))))
	    (setq string (replace-match newtext t literal string))
	    (setq start (- (length string) from-end))))
	  string)
    (if (not (string-match regexp string 0))
	nil
      (replace-match newtext t literal string))))


(defun regtest-get-directive-sexpr ()
  (save-excursion
    (forward-char 1)
    (let ((string (buffer-substring (point) (progn (forward-sexp 1) (point)))))
      (setq string (regtest-replace-match "\\\n" string "\n" t t))
      (setq string (regtest-replace-match "^#" string "" t t))
      (car (read-from-string string)))))


(defun regtest-get-directive-lines ()
  (save-excursion
    (let ((start (point))
	  (end (save-excursion (forward-char 1) (forward-sexp 1) (point)))
	  result)
      (while (re-search-forward "^.*$" end t)
	(setq result (cons (buffer-substring (match-beginning 0) (match-end 0))
			   result)))
      (nreverse result))))
    

(defun regtest-log-directive-lines (lines)
  (mapcar 'regtest-log-text lines)
  (setq regtest-directive-end (- (point) (length regtest-prompt) 1)))


(defun regtest-process-directive ()
  (let* ((directive (regtest-get-directive-sexpr))
	 (lines (regtest-get-directive-lines))
	 (sexpr (cons (or (intern-soft (format "regtest-%s" (car directive)))
			  (car directive))
		      (cdr directive)))
	 (cbuf (current-buffer)))

    (forward-char 1)
    (forward-sexp 1)
    (beginning-of-line)

    (unwind-protect
	(progn
	  (set-buffer regtest-output-buffer)
	  (goto-char (point-max))
	  (regtest-log-directive-lines lines)
	  (goto-char (process-mark regtest-process))
	  (forward-char (- (length regtest-prompt)))

	  (if regtest-dont-catch-errors
	      (eval sexpr)
	    (condition-case problem
		(eval sexpr)
	      (error (throw 'failure 
			    (list 'ERROR (format "%s while evaling %s"
						 problem
						 (prin1-to-string sexpr))))))))

      (set-buffer cbuf))))


(defun regtest-log-text (string)
  (let ((cbuf (current-buffer)))
    (unwind-protect
	(progn
	  (set-buffer regtest-output-buffer)
	  (goto-char (point-max))
	  (insert string)
	  (insert "\n")
	  (insert regtest-prompt))
      (set-buffer cbuf))))


(defun regtest-log-directive-result (string)
  (goto-char regtest-directive-end)
  (insert " => ")
  (insert string))


(defun regtest-checkpoint ()
  (setq regtest-checkpoint-start (point-max)))


(defun regtest-assert (condition)
  (let ((start (point))
	(command (format "if {%s} {puts TRUE} else {puts FALSE}" condition))
	(log (format "ASSERT %s" condition)))
    (regtest-run-command command log)
    (cond
     ((search-backward "TRUE" start t)
      (regtest-log-directive-result "t"))
     ((search-backward "FALSE" start t)
      (regtest-log-directive-result "nil")
      (throw 'failure
	     (list 'FAILED (format "Failed assertion \"%s\"" condition))))
     (t
      (regtest-log-directive-result "ERROR")
      (throw 'failure
	     (list 'ERROR (format "Error in assertion \"%s\"" condition)))))))


(defun regtest-polarity-function (polarity)
  (if polarity
      'identity
    'not))


(defun regtest-find-generic (item-list count search-command polarity)
  (catch 'result
    (let (start
	  (end (process-mark regtest-process))
	  (ops (if (and (listp polarity) (car polarity))
		   (mapcar 'regtest-polarity-function polarity)
		 (regtest-polarity-function polarity)))
	  (i 0))
      (goto-char regtest-checkpoint-start)

      (while (< i count)
	(mapcar (flambda (item)
		  (let ((start (point))
			(op (if (listp ops)
				(prog1
				    (car ops)
				  (setq ops (cdr ops)))
			      ops)))
		    (if (apply op (apply search-command item end t nil) nil)
			nil
		      (regtest-log-directive-result "nil")
		      (throw 'result (list item start (marker-position end)
					   (and (eq op 'not)
						(match-beginning 0)))))))
		item-list)
	(setq i (1+ i))))

    (regtest-log-directive-result "t")
    nil))


(defun regtest-find-repeated-string (count &rest strings)
  (let ((unfound (regtest-find-generic strings count 'search-forward t)))
    (if unfound
	(throw 'failure
	       (list 'FAILED 
		     (format "Failed to find string \"%s\" in [%d,%d]" 
			     (car unfound) (nth 1 unfound) (nth 2 unfound)))))))


(defun regtest-find-repeated-regexp (count &rest regexps)
  (let ((unfound (regtest-find-generic regexps count 're-search-forward t)))
    (if unfound
	(throw 'failure 
	       (list 'FAILED
		     (format "Failed to find regexp \"%s\" in [%d,%d]"
			     (car unfound) (nth 1 unfound) (nth 2 unfound)))))))


(defun regtest-find-string (&rest strings)
  (apply 'regtest-find-repeated-string 1 strings))


(defun regtest-find-regexp (&rest regexps)
  (apply 'regtest-find-repeated-regexp 1 regexps))


(defun regtest-dont-find-string (&rest strings)
  (let ((found (regtest-find-generic strings 1 'search-forward nil)))
    (if found
	(throw 'failure
	       (list 'FAILED
		     (format "Found string \"%s\" in [%d,%d] at %d" (car found)
			     (nth 1 found) (nth 2 found) (nth 3 found)))))))


(defun regtest-dont-find-string-after (regexp string)
  (let ((found (regtest-find-generic (list regexp (regexp-quote string)) 1 
				     're-search-forward '(t nil))))
    (if found 
	(throw 'failure
	       (list 'FAILED
		     (if (nth 3 found)
			 (format "Found string \"%s\" in [%d,%d] at %d"
				 (car found) (nth 1 found) (nth 2 found)
				 (nth 3 found))
		       (format "Did not find regexp \"%s\" in [%d,%d]"
			       (car found) (nth 1 found) (nth 2 found))))))))


(defun regtest-dont-find-regexp (&rest regexps)
  (let ((found (regtest-find-generic regexps 1 're-search-forward nil)))
    (if found
	(throw 'failure
	       (list 'FAILED
		     (format "Found regexp \"%s\" in [%d,%d] at %d" (car found)
			     (nth 1 found) (nth 2 found) (nth 3 found)))))))


(defun regtest-dont-find-regexp-after (regexp1 regexp2)
  (let ((found (regtest-find-generic (list regexp1 regexp2) 1
				     're-search-forward '(t nil))))
    (if found
	(throw 'failure
	       (list 'FAILED
		     (if (nth 3 found)
			 (format "Found regexp \"%s\" in [%d,%d] at %d"
				 (car found) (nth 1 found) (nth 2 found)
				 (nth 3 found))
		       (format "Did not find regexp \"%s\" in [%d,%d]"
			       (car found) (nth 1 found) (nth 2 found))))))))


(defun regtest-issue-command ()
  (let ((command (buffer-substring (point)
				   (save-excursion (end-of-line) (point)))))
    (regtest-run-command command)))


(defun regtest-run-test-in-buffer ()
  (let (result)
    (unwind-protect
      (progn
	(goto-char (point-min))
	(setq result
	      (catch 'failure
		(regtest-start-process)

		(while (not (looking-at "[ \t\n]*\\'"))
		  (cond

		   ((looking-at "#[ \t\n]*(")
		    (regtest-process-directive))

		   ((looking-at "#")
		    ;; random comment -- log it
		    (regtest-log-text (buffer-substring (point) (save-excursion
								  (end-of-line)
								  (point)))))

		   ((looking-at "[ \t]*$")
		    ;; blank line -- log it
		    (regtest-log-text ""))

		   (t
		    ;; must be a command
		    (regtest-issue-command)))

		  (if (> (forward-line 1) 0)
		      (goto-char (point-max))))

		(cons 'PASSED nil))))

      (set-process-sentinel regtest-process nil)

      (save-window-excursion
	(set-buffer regtest-output-buffer)
	(move-marker (process-mark regtest-process) (point-max)))

      (delete-process regtest-process)

      (save-window-excursion
	(set-buffer regtest-output-buffer)
	(write-region (point-min) (point-max) regtest-log-file nil 'silent)
	(setq buffer-modified-p nil)))

    (kill-buffer regtest-output-buffer)

    result))


(defun regtest-run-test (file)
  (if (not (string= (substring regtest-root -1) "/"))
      (setq regtest-root (concat regtest-root "/")))

  (setq regtest-dont-remove-tmp-dir nil)

  (let ((path (concat regtest-root file))
	(dir (file-name-directory file))
	(regtest-temp-dir-list nil)
	(regtest-log-file (concat (file-name-sans-extension file) ".log"))
	status)

    (make-directory dir t)

    (unwind-protect
	(progn
	  (set-buffer (find-file-noselect path t))
	  (setq status (regtest-run-test-in-buffer))
	  (kill-buffer (current-buffer))
	  (setq result (cons (car status) 
			     (cons (substring file 2)
				   (if regtest-include-wait-times
				       (nconc
					(cdr status) 
					(list (nreverse regtest-wait-times)))
				     (cdr status)))))
	  (setq result-string (concat (prin1-to-string result) "\n"))
	  (message "%s" (concat (symbol-name (car result))
				"\t" (nth 1 result)
				(if (nth 2 result)
				    (format "\t%s" (nth 2 result))
				  "")))
	  (write-region result-string nil
			regtest-result-file t 'silent))
      (if regtest-dont-remove-tmp-dir
	  nil
	(mapcar (flambda (dir)
		  (call-process "rm" nil nil nil "-r" dir))
		regtest-temp-dir-list)))))


(defun regtest-batch ()
  (let* ((args command-line-args-left)
	 (regtest-program (expand-file-name (car args)))
	 (regtest-root (expand-file-name (nth 1 args)))
	 (regtest-result-file (concat default-directory "test.out")))

    (mapcar 'regtest-run-test (nthcdr 2 args))

    (setq command-line-args-left nil)))
    


(defun regtest-run-single-test (program root file)
  (let* ((regtest-program program)
	 (regtest-root root)
	 (regtest-result-file (concat default-directory "test.out")))

    (regtest-run-test file)))
