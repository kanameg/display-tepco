;; -*- Emacs-Lisp -*-

;; display-tepco.el ---

;; Copyright (C) 2011 YOSHIDA Kaname
;; Author: YOSHDIA Kaname <kaname.g@gmail.com>

;; (require 'display-tepco)
;; (display-tepco)

(require 'url)
(require 'json)

(defvar display-tepco-version "0.1")

(defgroup display-tepco nil
  "display-tepco"
  :group 'emacs)

(defcustom display-tepco-interval 600
  "*access interval 10min"
  :type 'integer
  :group 'display-tepco)

(defconst display-tepco-url "http://tepco-usage-api.appspot.com/latest.json")

(defvar display-tepco-timer nil)
(defvar display-tepco-string nil)

(defun display-tepco-get ()
  (url-retrieve display-tepco-url #'display-tepco-sentinel))

(defun display-tepco-sentinel (status)
  (let ((response (buffer-string)) (json-key-type 'string))
    (setq display-tepco-string
	  (display-tepco-update-string
	   ;; json -> alist
	   (json-read-from-string
	    (substring response
		       (+ (string-match "\r?\n\r?\n" response)
			  (length (match-string 0 response)))
		       (1- (point-max))))))))

(defun display-tepco-update-string (json-alist)
  (let ((capacity (cdr (assoc "capacity" json-alist)))
	(usage (cdr (assoc "usage" json-alist)))
	(hour (cdr (assoc "hour" json-alist))))
    (format "(%dËükW %.1f%%%% @%d:00)"
	    usage (* (/ (float usage) (float capacity)) 100)
	    hour)))


(defun display-tepco-action (action)
  (funcall action))

(defun display-tepco-start (&optional action)
  (unless action
    (setq action #'display-tepco-get))
  (unless display-tepco-timer
    (setq display-tepco-timer
	  (run-at-time "0 sec"
		       display-tepco-interval
		       #'display-tepco-action action)))
  (add-to-list 'global-mode-string '(:eval display-tepco-string)))

(defun display-tepco-stop ()
  (interactive)
  (while display-tepco-timer
    (cancel-timer display-tepco-timer)
    (setq display-tepco-timer nil))
  (setq global-mode-string
	(delete '(:eval display-tepco-string) global-mode-string)))

(defun display-tepco ()
  (interactive)
  (save-excursion
    (display-tepco-start)))

(provide 'display-tepco)
;; end
