;;; spot-marginalia.el --- Annotation functions for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;;; Commentary:

;; Marginalia annotation functions for Spotify search result categories.

;;; Code:

(require 'ht)
(require 'marginalia)

(defun spot--round-to-two-decimals (num)
  "Round NUM to two decimal places."
  (/ (round (* num 100)) 100.0))

(defun spot--annotate-album (album)
  "Annotate ALBUM with name, artist, release date, and track count."
  (concat
   " <- "
   (mapconcat
    #'identity
    `(,(ht-get* (get-text-property 0 'multi-data album) 'name)
      ,(ht-get* (nth 0 (ht-get* (get-text-property 0 'multi-data album) 'artists)) 'name)
      ,(ht-get* (get-text-property 0 'multi-data album) 'release_date)
      ,(number-to-string (ht-get* (get-text-property 0 'multi-data album) 'total_tracks)))
    " || ")))

(defun spot--annotate-artist (artist)
  "Annotate ARTIST with name, popularity, and follower count."
  (concat
   " <- "
   (mapconcat
    #'identity
    `(,(ht-get* (get-text-property 0 'multi-data artist) 'name)
      ,(number-to-string (ht-get* (get-text-property 0 'multi-data artist) 'popularity))
      ,(number-to-string (ht-get* (get-text-property 0 'multi-data artist) 'followers 'total)))
    " || ")))

(defun spot--annotate-track (track)
  "Annotate TRACK with name, number, artist, duration, album, and date."
  (concat
   " <- "
   (mapconcat
    #'identity
    `(,(ht-get* (get-text-property 0 'multi-data track) 'name)
      ,(number-to-string (ht-get* (get-text-property 0 'multi-data track) 'track_number))
      ,(ht-get* (nth 0 (ht-get* (get-text-property 0 'multi-data track) 'artists)) 'name)
      ,(number-to-string (spot--round-to-two-decimals
                          (/
                           (ht-get* (get-text-property 0 'multi-data track) 'duration_ms)
                           60000.0)))
      ,(ht-get* (get-text-property 0 'multi-data track) 'album 'name)
      ,(ht-get* (get-text-property 0 'multi-data track) 'album 'album_type)
      ,(ht-get* (get-text-property 0 'multi-data track) 'album 'release_date))
    " || ")))

(defun spot--annotate-playlist (playlist)
  "Annotate PLAYLIST with name and track count."
  (concat
   " <- "
   (mapconcat
    #'identity
    `(,(ht-get* (get-text-property 0 'multi-data playlist) 'name)
      ,(number-to-string (ht-get* (get-text-property 0 'multi-data playlist) 'tracks 'total)))
    " || ")))

(defun spot--annotate-show (show)
  "Annotate SHOW with name, publisher, media type, episode count, and description."
  (concat
   " <- "
   (mapconcat
    #'identity
    `(,(ht-get* (get-text-property 0 'multi-data show) 'name)
      ,(ht-get* (get-text-property 0 'multi-data show) 'publisher)
      ,(ht-get* (get-text-property 0 'multi-data show) 'media_type)
      ,(number-to-string (ht-get* (get-text-property 0 'multi-data show) 'total_episodes))
      ,(ht-get* (get-text-property 0 'multi-data show) 'description))
    " || ")))

(defun spot--annotate-episode (episode)
  "Annotate EPISODE with name, release date, description, and duration."
  (concat
   " <- "
   (mapconcat
    #'identity
    `(,(ht-get* (get-text-property 0 'multi-data episode) 'name)
      ,(ht-get* (get-text-property 0 'multi-data episode) 'release_date)
      ,(ht-get* (get-text-property 0 'multi-data episode) 'description)
      ,(number-to-string (spot--round-to-two-decimals
                          (/
                           (ht-get* (get-text-property 0 'multi-data episode) 'duration_ms)
                           60000.0))))
    " || ")))

(defun spot--annotate-audiobook (audiobook)
  "Annotate AUDIOBOOK with name, publisher, narrator, author, and description."
  (concat
   " <- "
   (mapconcat
    #'identity
    `(,(ht-get* (get-text-property 0 'multi-data audiobook) 'name)
      ,(ht-get* (get-text-property 0 'multi-data audiobook) 'publisher)
      ,(ht-get* (nth 0 (ht-get* (get-text-property 0 'multi-data audiobook) 'narrators)) 'name)
      ,(ht-get* (nth 0 (ht-get* (get-text-property 0 'multi-data audiobook) 'authors)) 'name)
      ,(string-replace "\n" " " (ht-get* (get-text-property 0 'multi-data audiobook) 'description)))
    " || ")))

;;; Register annotators

(defvar spot--marginalia-annotator-entries
  '((album spot--annotate-album none)
    (artist spot--annotate-artist none)
    (playlist spot--annotate-playlist none)
    (track spot--annotate-track none)
    (show spot--annotate-show none)
    (episode spot--annotate-episode none)
    (audiobook spot--annotate-audiobook none))
  "List of marginalia annotator entries registered by spot.")

(defun spot--setup-marginalia ()
  "Register spot annotators with marginalia."
  (dolist (entry spot--marginalia-annotator-entries)
    (add-to-list 'marginalia-annotators entry)))

(defun spot--teardown-marginalia ()
  "Remove spot annotators from marginalia."
  (dolist (entry spot--marginalia-annotator-entries)
    (setq marginalia-annotators (delete entry marginalia-annotators))))

(provide 'spot-marginalia)

;;; spot-marginalia.el ends here
