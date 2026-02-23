;;; spot-auth.el --- OAuth2 authentication for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

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

(provide 'spot-auth)

;;; spot-auth.el ends here
