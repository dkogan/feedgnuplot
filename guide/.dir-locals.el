;; Very similar logic appears in
;;   https://www.github.com/dkogan/gnuplotlib
;;   https://www.github.com/dkogan/feedgnuplot
;; 
;; I need some advices to be able to generate all the images. I'm not using the org
;; exporter to produce the html, but relying on github's limited org parser to
;; display everything. github's parser doesn't do the org export, so I must
;; pre-generate all the figures with (org-babel-execute-buffer) (C-c C-v C-b).

;; This requires advices to:

;; - Generate unique image filenames
;; - Communicate those filenames to feedgnuplot
;; - Display code that produces an interactive plot (so that the readers can
;;   cut/paste the snippets), but run code that writes to the image that ends up in
;;   the documentation
(( org-mode . ((eval .
  (progn
            (setq org-confirm-babel-evaluate nil)
            (org-babel-do-load-languages
             'org-babel-load-languages
              '((shell   . t)))
  ;; This sets a default :file tag, set to a unique filename. I want each demo to
  ;; produce an image, but I don't care what it is called. I omit the :file tag
  ;; completely, and this advice takes care of it
  (defun dima-info-local-get-property
      (params what)
    (condition-case nil
        (cdr (assq what params))
      (error "")))
  (defun dima-org-babel-is-feedgnuplot
      (params)
    (and
     (or (not (assq :file params))
         (string-match "^guide-[0-9]+\\.svg$" (cdr (assq :file params))))
     (string-match "\\<both\\>" (dima-info-local-get-property params :exports) )
     (string-match "\\<file\\>" (dima-info-local-get-property params :results ))))
  (defun dima-org-babel-sh-unique-plot-filename
      (f &optional arg info params)

    (let ((info-local (or info (org-babel-get-src-block-info t))))
      (if (and info-local
               (string= (car info-local) "sh")
               (dima-org-babel-is-feedgnuplot (caddr info-local)))
          ;; We're looking at a feedgnuplot block. Add a default :file
          (funcall f arg info
                   (cons (cons ':file
                               (format "guide-%d.svg"
                                       (condition-case nil
                                           (setq dima-unique-plot-number (1+ dima-unique-plot-number))
                                         (error (setq dima-unique-plot-number 0)))))
                         params))
        ;; Not feedgnuplot. Just do the normal thing
        (funcall f arg info params))))

  (unless
      (advice-member-p
       #'dima-org-babel-sh-unique-plot-filename
       #'org-babel-execute-src-block)
    (advice-add
     #'org-babel-execute-src-block
     :around #'dima-org-babel-sh-unique-plot-filename))
  ;; If I'm regenerating ALL the plots, I start counting the plots from 0
  (defun dima-reset-unique-plot-number
      (&rest args)
      (setq dima-unique-plot-number 0))
  (unless
      (advice-member-p
       #'dima-reset-unique-plot-number
       #'org-babel-execute-buffer)
    (advice-add
     #'org-babel-execute-buffer
     :before #'dima-reset-unique-plot-number))
  ;; I'm using github to display guide.org, so I'm not using the "normal" org
  ;; exporter. I want the demo text to not contain --hardcopy, but clearly I
  ;; need --hardcopy when generating the plots. I add the --hardcopy to the
  ;; command before running it
  (defun dima-org-babel-sh-set-demo-output (f body params)
    (when (dima-org-babel-is-feedgnuplot params)
      (with-temp-buffer
        (insert body)
        (end-of-buffer)
        (insert (format " --terminal 'svg noenhanced solid size 800,600 font \",14\"' --hardcopy %s" (cdr (assq :file params))))
        (setq body (buffer-substring-no-properties (point-min) (point-max)))))
    (funcall f body params))
  (unless
      (advice-member-p
       #'dima-org-babel-sh-set-demo-output
       #'org-babel-execute:sh)
    (advice-add
     #'org-babel-execute:sh
     :around #'dima-org-babel-sh-set-demo-output))
  )))))
