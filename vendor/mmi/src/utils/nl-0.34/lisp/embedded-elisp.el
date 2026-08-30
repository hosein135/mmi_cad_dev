(defun embedded-elisp-process-file (file &optional silent)
  (interactive "fFile name to process: ")
  (let ((embedded-elisp-source-file (file-name-nondirectory file))
	(embedded-elisp-source-directory (or (file-name-directory file)
					     (expand-file-name "./")))
	(embedded-elisp-output-file nil))
    (set-buffer (get-buffer-create "*embedded-elisp-output*"))
    (let ((default-directory embedded-elisp-source-directory))
      (widen) (erase-buffer)
      (insert-file-contents file)
      (embedded-elisp-process-buffer t)
      (if embedded-elisp-output-file
	  (write-region (point-min) (point-max) embedded-elisp-output-file
			nil silent))
      (kill-buffer (current-buffer)))))


(defun embedded-elisp-get-following-lines ()
  (let ((result nil)
	(start (point-min))
	(line 1))
    (goto-char (point-min))
    (while (search-forward "#(" nil t)
      (forward-char -1)
      (forward-sexp)
      (setq line (+ line (count-lines start (point)) -1)
	    start (point)
	    result (cons line result)))
    (nreverse result)))
	    

(defun embedded-elisp-process-buffer (&optional embedded-elisp-update)
  (let ((embedded-elisp-beg 0)
	(embedded-elisp-end 0)
	(embedded-elisp-expression nil)
	(embedded-elisp-result nil)
	embedded-elisp-following-lines)
    (save-excursion
      (save-restriction
	(widen)
	(setq embedded-elisp-following-lines
	      (embedded-elisp-get-following-lines))
	(goto-char (point-min))
	(while (search-forward "#(" nil t)
	  (setq embedded-elisp-beg (match-beginning 0))
	  (forward-char -1)

	  (setq embedded-elisp-following-line
		(car embedded-elisp-following-lines)

		embedded-elisp-following-lines
		(cdr embedded-elisp-following-lines)

		embedded-elisp-expression (read (current-buffer))

		embedded-elisp-end (point)

		embedded-elisp-result (eval embedded-elisp-expression))

	  (and embedded-elisp-update
	       (progn
		 (delete-region embedded-elisp-beg embedded-elisp-end)
		 (goto-char embedded-elisp-beg)
		 (insert embedded-elisp-result))))))))


(defun embedded-elisp-do-batch ()
  (let ((files command-line-args-left))
    (while files
      (embedded-elisp-process-file (car files) 'silent)
      (setq files (cdr files)))))
