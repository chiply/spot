;;; spot-auth.el --- OAuth2 authentication for spot -*- lexical-binding: t; -*-

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

;; OAuth2 authorization and token refresh for the Spotify API.

;;; Code:

(require 'json)
(require 'url)

(require 'spot-util)
(require 'spot-var)
(require 'spot-generic-query)

;;;###autoload
(defun spot-authorize ()
  "Obtain access and refresh tokens for a Spotify user account.
Opens the authorization URL in a browser and prompts for the
returned authorization code."
  (interactive)
  (browse-url (spot--auth-url-full))
  (let ((auth-code (read-string "Enter code from URL: ")))
    (spot-request-async
     :method "POST"
     :url spot-token-url
     :q-params (concat "?grant_type=" "authorization_code"
                       "&redirect_uri=" spot--redirect-uri
                       "&code=" auth-code)
     :callback (lambda (response)
                 (let ((json (json-read-from-string response)))
                   (setq
                    spot-access-token (spot--alist-get-chain '(access_token) json)
                    spot-refresh-token (spot--alist-get-chain '(refresh_token) json)))
                 (message "Refreshed spot access token and refresh token"))
     :extra-headers `(("Content-Type" . "application/x-www-form-urlencoded")
                      ("Content-Length" . "0")
                      ("Authorization" . ,(concat "Basic " (spot--b64-id-secret)))))))

;;;###autoload
(defun spot-refresh ()
  "Refresh the Spotify access token using the stored refresh token."
  (interactive)
  (spot-request-async
   :method "POST"
   :url spot-token-url
   :q-params (concat "?grant_type=" "refresh_token"
                     "&refresh_token=" spot-refresh-token)
   :callback (lambda (response)
               (setq
                spot-access-token
                (spot--alist-get-chain '(access_token) (json-read-from-string response)))
               (message "Refreshed spot access token"))
   :extra-headers `(("Content-Type" . "application/x-www-form-urlencoded")
                    ("Content-Length" . "0")
                    ("Authorization" . ,(concat "Basic " (spot--b64-id-secret))))))

(defvar spot--refresh-timer nil
  "The periodic timer that refreshes the Spotify access token.")

(defun spot--start-refresh-timer ()
  "Start the periodic access-token refresh timer.
Refreshes immediately if `spot-refresh-token' is set, then on
`spot-refresh-interval' thereafter.  No-op when the interval is
nil or a timer is already running."
  (when (and spot-refresh-interval (not spot--refresh-timer))
    (when spot-refresh-token
      (spot-refresh))
    (setq spot--refresh-timer
          (run-with-timer spot-refresh-interval
                          spot-refresh-interval
                          (lambda ()
                            (when spot-refresh-token
                              (spot-refresh)))))))

(defun spot--stop-refresh-timer ()
  "Stop the periodic access-token refresh timer."
  (when spot--refresh-timer
    (cancel-timer spot--refresh-timer)
    (setq spot--refresh-timer nil)))

(provide 'spot-auth)

;;; spot-auth.el ends here
