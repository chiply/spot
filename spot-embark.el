;;; spot-embark.el --- Embark actions for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;;; Commentary:

;; Embark keymaps and actions for Spotify search results.

;;; Code:

(require 'embark)
(require 'ht)
(require 'json)

(require 'spot-mode-line)
(require 'spot-consult)
(require 'spot-var)
(require 'spot-generic-query)

(defun spot-action--generic-show-data (item)
  "Display the raw data for ITEM in a dedicated buffer."
  (let ((buf (get-buffer-create "*spotify-search-result*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert (pp-to-string (get-text-property 0 'multi-data item))))
    (switch-to-buffer buf)
    (goto-char (point-min))))

(defun spot-action--list-album-tracks (item)
  "Search for tracks on the album represented by ITEM."
  (let* ((table (get-text-property 0 'multi-data item))
         (album-name (ht-get* table 'name))
         (artist-name (ht-get* (nth 0 (ht-get* table 'artists)) 'name)))
    (spot-consult-search
     (concat
      "album:" album-name
      " "
      "artist:" artist-name " -- --type=track"))))

(defun spot-action--list-artist-tracks (item)
  "Search for tracks by the artist represented by ITEM."
  (let* ((table (get-text-property 0 'multi-data item))
         (artist-name (ht-get* table 'name)))
    (spot-consult-search
     (concat "artist:" artist-name " -- --type=track"))))

(defun spot-action--list-playlist-tracks (item)
  "List tracks in the playlist represented by ITEM."
  (let* ((table (get-text-property 0 'multi-data item))
         (playlist-id (ht-get* table 'id)))
    (setq spot--selected-playlist-id playlist-id)
    (spot-consult-search-playlist-tracks)))

(defun spot-action--generic-play-uri (item)
  "Play the Spotify item represented by ITEM."
  (let* ((table (get-text-property 0 'multi-data item))
         (type (ht-get table 'type))
         (offset (cond
                  ((string= type "track") `(("uri" . ,(ht-get* table 'uri))))
                  ((string= type "playlist") '(("position" . 0)))
                  ((string= type "album") '(("position" . 0)))
                  ((string= type "artist") nil)))
         (context_uri (cond
                       ((string= type "track") (ht-get* table 'album 'uri))
                       ((string= type "playlist") (ht-get* table 'uri))
                       ((string= type "album") (ht-get* table 'uri))
                       ((string= type "artist") (ht-get* table 'uri))))
         (json (list))
         (_ (when context_uri (push (cons 'context_uri context_uri) json)))
         (_ (when offset (push (cons 'offset offset) json)))
         (json (json-encode json)))
    (spot-request-async
     :method "PUT"
     :url spot-player-play-url
     :q-params (spot--base-q-params)
     :callback (lambda (_) (run-with-timer 2.0 nil #'spot--update-modeline-lighters))
     :data json)))

(defun spot-action--add-track-to-playlist (item)
  "Add the track ITEM to a user-selected playlist."
  (let* ((playlist (or spot--playlist-selected
                       (progn
                         (setq spot--playlist-selected
                               (car (spot-consult-search-current-user-playlists)))
                         spot--playlist-selected)))
         (playlist-id (ht-get* (get-text-property 0 'multi-data playlist) 'id))
         (track-uri (or
                     (ht-get* (get-text-property 0 'multi-data item) 'uri)
                     (ht-get* (get-text-property 0 'multi-data item) 'item 'uri)))
         (json (format "{\"uris\":[\"%s\"]}" track-uri))
         (url (format
               "https://api.spotify.com/v1/playlists/%s/tracks"
               playlist-id)))
    (spot-request-async
     :method "POST"
     :url url
     :q-params (spot--base-q-params)
     :data json)))

;;; Keymaps

(defvar-keymap spot-embark-artist-keymap
  :parent embark-general-map
  :doc "Keymap for Spotify artist actions.")

(defvar-keymap spot-embark-album-keymap
  :parent embark-general-map
  :doc "Keymap for Spotify album actions.")

(defvar-keymap spot-embark-playlist-keymap
  :parent embark-general-map
  :doc "Keymap for Spotify playlist actions.")

(defvar-keymap spot-embark-track-keymap
  :parent embark-general-map
  :doc "Keymap for Spotify track actions.")

(defvar-keymap spot-embark-show-keymap
  :parent embark-general-map
  :doc "Keymap for Spotify show actions.")

(defvar-keymap spot-embark-episode-keymap
  :parent embark-general-map
  :doc "Keymap for Spotify episode actions.")

(defvar-keymap spot-embark-audiobook-keymap
  :parent embark-general-map
  :doc "Keymap for Spotify audiobook actions.")

(defvar-keymap spot-embark-current-user-playlists-keymap
  :parent embark-general-map
  :doc "Keymap for current user playlist actions.")

(defvar-keymap spot-embark-playlist-tracks-keymap
  :parent embark-general-map
  :doc "Keymap for playlist track actions.")

;;; Keymap registry

(defvar spot--embark-keymap-entries
  '((album . spot-embark-album-keymap)
    (artist . spot-embark-artist-keymap)
    (playlist . spot-embark-playlist-keymap)
    (track . spot-embark-track-keymap)
    (show . spot-embark-show-keymap)
    (episode . spot-embark-episode-keymap)
    (audiobook . spot-embark-audiobook-keymap)
    (current-user-playlists . spot-embark-current-user-playlists-keymap)
    (playlist-tracks . spot-embark-playlist-tracks-keymap))
  "Alist of embark keymap entries registered by spot.")

(defun spot--setup-embark ()
  "Register spot keymaps with embark."
  (dolist (entry spot--embark-keymap-entries)
    (add-to-list 'embark-keymap-alist entry)))

(defun spot--teardown-embark ()
  "Remove spot keymaps from embark."
  (dolist (entry spot--embark-keymap-entries)
    (setq embark-keymap-alist (delete entry embark-keymap-alist))))

;;; Key bindings

(dolist (map (list spot-embark-artist-keymap spot-embark-album-keymap
                  spot-embark-playlist-keymap spot-embark-track-keymap
                  spot-embark-show-keymap spot-embark-episode-keymap
                  spot-embark-audiobook-keymap
                  spot-embark-current-user-playlists-keymap
                  spot-embark-playlist-tracks-keymap))
  (define-key map "s" #'spot-action--generic-show-data)
  (define-key map "P" #'spot-action--generic-play-uri))

(define-key spot-embark-track-keymap "+" #'spot-action--add-track-to-playlist)
(define-key spot-embark-album-keymap "t" #'spot-action--list-album-tracks)
(define-key spot-embark-artist-keymap "t" #'spot-action--list-artist-tracks)
(define-key spot-embark-playlist-keymap "t" #'spot-action--list-playlist-tracks)

(provide 'spot-embark)

;;; spot-embark.el ends here
