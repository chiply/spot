;;; spot-generic-query.el --- HTTP request helpers for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Synchronous and asynchronous HTTP request functions for the
;; Spotify API.

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'url)

(require 'spot-util)
(require 'spot-var)

(defvar url-http-end-of-headers)
(defvar url-http-response-status)

;; Defined in spot-auth, which requires this file; the guard in
;; `spot--bearer-auth-headers' keeps standalone loads safe.
(declare-function spot--ensure-fresh-token "spot-auth")

(defun spot--bearer-auth-headers ()
  "Return Bearer auth headers, refreshing a stale token first.
The refresh keeps background pollers and interactive commands from
sending requests with an expired token, which would fail with 401."
  (when (fboundp 'spot--ensure-fresh-token)
    (spot--ensure-fresh-token))
  (spot--auth-headers))

(defun spot--report-response-error ()
  "If the current response buffer is non-2xx, `message' the error.
Must be called inside the response buffer of a `url-retrieve' or
`url-retrieve-synchronously'.  The message includes the HTTP
status and, when the body is Spotify's standard error shape
\({\"error\":{\"message\":...}\}), the server's error message."
  (when (and (boundp 'url-http-response-status)
             url-http-response-status
             (not (and (>= url-http-response-status 200)
                       (<= url-http-response-status 299))))
    (when (= url-http-response-status 401)
      ;; The token was rejected regardless of its recorded expiry;
      ;; force staleness so the next request refreshes before sending.
      (setq spot--token-expires-at 0))
    (let* ((body (decode-coding-region (+ 1 url-http-end-of-headers)
                                       (point-max) 'utf-8 t))
           (json (and (not (string= body ""))
                      (ignore-errors (json-read-from-string body))))
           (msg (spot--alist-get-chain '(error message) json)))
      (message "spot: %d %s"
               url-http-response-status
               (or msg "request failed")))))

(defun spot-retrieve-url-to-alist-synchronously (url)
  "Return alist representation of JSON response from URL."
  (with-current-buffer (url-retrieve-synchronously url nil nil spot--request-timeout)
    (spot--report-response-error)
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
                 (spot--bearer-auth-headers)))
         (url-request-method method)
         (url-request-data data)
         (url-request-extra-headers (append auth extra-headers)))
    (if parse-json
        (spot-retrieve-url-to-alist-synchronously
         (concat url q-params))
      (let ((buffer (url-retrieve-synchronously
                     (concat url q-params) nil nil spot--request-timeout)))
        (with-current-buffer buffer (spot--report-response-error))
        buffer))))

;; Async

(defun spot-retrieve-url-to-alist-asynchronously (url callback)
  "Fetch URL asynchronously and call CALLBACK with the JSON response string."
  (url-retrieve
   url
   (lambda (status)
     (if (plist-get status :error)
         (message "spot: request failed: %s" (cdr (plist-get status :error)))
       (spot--report-response-error)
       (let ((json (decode-coding-region (+ 1 url-http-end-of-headers)
                                         (point-max) 'utf-8 t)))
         (funcall callback json))))
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
                 (spot--bearer-auth-headers)))
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
