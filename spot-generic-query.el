;;; spot-generic-query.el --- HTTP request helpers for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;;; Commentary:

;; Synchronous and asynchronous HTTP request functions for the
;; Spotify API.

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'url)

(require 'spot-var)

(defvar url-http-end-of-headers)

(defun spot-retrieve-url-to-alist-synchronously (url)
  "Return alist representation of JSON response from URL."
  (with-current-buffer (url-retrieve-synchronously url nil nil spot--request-timeout)
    (let ((json (decode-coding-region (+ 1 url-http-end-of-headers)
                                      (point-max) 'utf-8 t)))
      (when (not (string= json ""))
        (json-read-from-string json)))))

(cl-defun spot-request (&key method url q-params parse-json extra-headers data)
  "Make a synchronous Spotify API request.
METHOD is the HTTP method, URL is the endpoint, Q-PARAMS is the
query parameter string, PARSE-JSON when non-nil returns parsed
JSON as an alist, EXTRA-HEADERS is an alist of additional
headers, and DATA is the request body."
  (let* ((auth (unless (assoc "Authorization" extra-headers)
                 (spot--auth-headers)))
         (url-request-method method)
         (url-request-data data)
         (url-request-extra-headers (append auth extra-headers)))
    (if parse-json
        (spot-retrieve-url-to-alist-synchronously
         (concat url q-params))
      (url-retrieve-synchronously
       (concat url q-params) nil nil spot--request-timeout))))

;; Async

(defun spot-retrieve-url-to-alist-asynchronously (url callback)
  "Fetch URL asynchronously and call CALLBACK with the JSON response string."
  (url-retrieve
   url
   (lambda (_status)
     (let ((json (decode-coding-region (+ 1 url-http-end-of-headers)
                                       (point-max) 'utf-8 t)))
       (funcall callback json)))
   nil t t))

(defun spot--message-request-complete (&rest _args)
  "Display a message indicating that the Spotify request completed."
  (message "spot request complete"))

(cl-defun spot-request-async (&key method url q-params callback extra-headers data)
  "Make an asynchronous Spotify API request.
METHOD is the HTTP method, URL is the endpoint, Q-PARAMS is the
query parameter string, CALLBACK receives the response string,
EXTRA-HEADERS is an alist of additional headers, and DATA is the
request body."
  (let* ((auth (unless (assoc "Authorization" extra-headers)
                 (spot--auth-headers)))
         (url-request-method method)
         (url-request-data data)
         (url-request-extra-headers (append auth extra-headers)))
    (spot-retrieve-url-to-alist-asynchronously
     (concat url q-params)
     (or callback #'spot--message-request-complete))))

;; Currently playing

(defun spot--currently-playing ()
  "Fetch the currently playing track from Spotify."
  (spot-request
   :method "GET"
   :url spot-player-url
   :q-params (spot--base-q-params)
   :parse-json t))

(provide 'spot-generic-query)

;;; spot-generic-query.el ends here
