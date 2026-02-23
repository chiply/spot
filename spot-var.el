;;; spot-var.el --- Variables and configuration for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;;; Commentary:

;; User-facing configuration variables and API endpoint URLs for spot.

;;; Code:

(require 'url-util)

(defgroup spot nil
  "Spotify client for Emacs."
  :group 'multimedia
  :prefix "spot-")

(defcustom spot-client-id nil
  "Spotify application client ID.
Obtain from https://developer.spotify.com/dashboard."
  :type '(choice (const :tag "Not set" nil) string)
  :group 'spot)

(defcustom spot-client-secret nil
  "Spotify application client secret.
Obtain from https://developer.spotify.com/dashboard."
  :type '(choice (const :tag "Not set" nil) string)
  :group 'spot)

(defvar spot--playlist-selected nil
  "Currently selected playlist for add-to-playlist operations.")

(defvar spot--selected-playlist-id nil
  "ID of the currently selected playlist.")

(defvar spot-access-token nil
  "Current Spotify OAuth2 access token.")

(defvar spot-refresh-token nil
  "Current Spotify OAuth2 refresh token.")

(defvar spot-wait-time 1.0
  "Seconds to wait between changing track and fetching currently-playing.
There are synchronicity issues when displaying currently-playing
after a player action, even when using a callback function.")

;; API endpoint URLs

(defvar spot-token-url "https://accounts.spotify.com/api/token"
  "Spotify token endpoint URL.")

(defvar spot-search-url "https://api.spotify.com/v1/search"
  "Spotify search endpoint URL.")

(defvar spot-player-url "https://api.spotify.com/v1/me/player"
  "Spotify player endpoint URL.")

(defvar spot-player-play-url (concat spot-player-url "/play")
  "Spotify player play endpoint URL.")

(defvar spot-currently-playing-url (concat spot-player-url "/currently-playing")
  "Spotify currently-playing endpoint URL.")

(defvar spot-categories-url "https://api.spotify.com/v1/browse/categories"
  "Spotify categories endpoint URL.")

(defvar spot-browse-url "https://api.spotify.com/v1/browse"
  "Spotify browse endpoint URL.")

(defvar spot-playlist-url "https://api.spotify.com/v1/playlists"
  "Spotify playlists endpoint URL.")

(defvar spot-new-releases-url "https://api.spotify.com/v1/browse/new-releases"
  "Spotify new releases endpoint URL.")

(defvar spot-albums-url "https://api.spotify.com/v1/albums"
  "Spotify albums endpoint URL.")

(defvar spot-artist-url "https://api.spotify.com/v1/artists"
  "Spotify artists endpoint URL.")

(defvar spot-recommendations-url "https://api.spotify.com/v1/recommendations"
  "Spotify recommendations endpoint URL.")

(defvar spot-me-url "https://api.spotify.com/v1/me"
  "Spotify current user endpoint URL.")

(defvar spot-users-url "https://api.spotify.com/v1/users"
  "Spotify users endpoint URL.")

(defvar spot-following-url "https://api.spotify.com/v1/me/following"
  "Spotify following endpoint URL.")

(defvar spot-tracks-url "https://api.spotify.com/v1/tracks/"
  "Spotify tracks endpoint URL.")

(defvar spot-recently-played-url
  "https://api.spotify.com/v1/me/player/recently-played"
  "Spotify recently played endpoint URL.")

(defvar spot--request-timeout 10
  "Timeout in seconds for Spotify API requests.")

(defvar spot--redirect-uri (url-hexify-string "https://spotify.com")
  "URL-encoded redirect URI for OAuth2 flow.")

;; Derived values computed lazily from defcustoms

(defun spot--id-secret ()
  "Return the client-id:client-secret string."
  (concat spot-client-id ":" spot-client-secret))

(defun spot--b64-id-secret ()
  "Return the base64-encoded client-id:client-secret string."
  (base64-encode-string (spot--id-secret) t))

(defun spot--auth-url-full ()
  "Return the full Spotify authorization URL."
  (url-encode-url
   (concat
    "https://accounts.spotify.com/en/authorize"
    "?response_type=code&client_id=" spot-client-id
    "&redirect_uri=" spot--redirect-uri
    "&scope=" (concat "streaming "
                      "user-read-email "
                      "user-read-private "
                      "user-read-playback-state "
                      "user-library-modify "
                      "user-library-read "
                      "user-modify-playback-state "
                      "user-follow-read "
                      "playlist-modify-public "
                      "playlist-modify-private "
                      "user-read-recently-played")
    "&show_dialog=" "true")))

(defun spot--base-q-params ()
  "Return an empty query parameter string.
Authentication is handled via the Authorization header in
`spot-request' and `spot-request-async'."
  "")

(defun spot--auth-headers ()
  "Return an alist with the Bearer authorization header."
  `(("Authorization" . ,(concat "Bearer " spot-access-token))))

(provide 'spot-var)

;;; spot-var.el ends here
