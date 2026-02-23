;;; spot-marginalia.el --- Annotation functions for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;;; Commentary:

;; Marginalia annotation functions for Spotify search result categories.

;;; Code:

(require 'ht)
(require 'marginalia)

(defun spot--annotation-field (value)
  "Format VALUE as a string for marginalia annotations.
Returns \"?\" for nil values, converts numbers with `number-to-string',
and passes strings through unchanged."
  (cond
   ((null value) "?")
   ((numberp value) (number-to-string value))
   ((stringp value) value)
   (t (format "%s" value))))

(defun spot--round-to-two-decimals (num)
  "Round NUM to two decimal places."
  (/ (round (* num 100)) 100.0))

(defun spot--annotate-album (album)
  "Annotate ALBUM with name, artist, release date, and track count."
  (let ((data (get-text-property 0 'multi-data album)))
    (concat
     " <- "
     (mapconcat
      #'spot--annotation-field
      `(,(ht-get* data 'name)
        ,(ht-get* (nth 0 (or (ht-get* data 'artists) '(nil))) 'name)
        ,(ht-get* data 'release_date)
        ,(ht-get* data 'total_tracks))
      " || "))))

(defun spot--annotate-artist (artist)
  "Annotate ARTIST with name, popularity, and follower count."
  (let ((data (get-text-property 0 'multi-data artist)))
    (concat
     " <- "
     (mapconcat
      #'spot--annotation-field
      `(,(ht-get* data 'name)
        ,(ht-get* data 'popularity)
        ,(ht-get* data 'followers 'total))
      " || "))))

(defun spot--annotate-track (track)
  "Annotate TRACK with name, number, artist, duration, album, and date."
  (let* ((data (get-text-property 0 'multi-data track))
         (duration-ms (ht-get* data 'duration_ms)))
    (concat
     " <- "
     (mapconcat
      #'spot--annotation-field
      `(,(ht-get* data 'name)
        ,(ht-get* data 'track_number)
        ,(ht-get* (nth 0 (or (ht-get* data 'artists) '(nil))) 'name)
        ,(when duration-ms
           (number-to-string (spot--round-to-two-decimals (/ duration-ms 60000.0))))
        ,(ht-get* data 'album 'name)
        ,(ht-get* data 'album 'album_type)
        ,(ht-get* data 'album 'release_date))
      " || "))))

(defun spot--annotate-playlist (playlist)
  "Annotate PLAYLIST with name and track count."
  (let ((data (get-text-property 0 'multi-data playlist)))
    (concat
     " <- "
     (mapconcat
      #'spot--annotation-field
      `(,(ht-get* data 'name)
        ,(ht-get* data 'tracks 'total))
      " || "))))

(defun spot--annotate-show (show)
  "Annotate SHOW with name, publisher, media type, episode count, and description."
  (let ((data (get-text-property 0 'multi-data show)))
    (concat
     " <- "
     (mapconcat
      #'spot--annotation-field
      `(,(ht-get* data 'name)
        ,(ht-get* data 'publisher)
        ,(ht-get* data 'media_type)
        ,(ht-get* data 'total_episodes)
        ,(ht-get* data 'description))
      " || "))))

(defun spot--annotate-episode (episode)
  "Annotate EPISODE with name, release date, description, and duration."
  (let* ((data (get-text-property 0 'multi-data episode))
         (duration-ms (ht-get* data 'duration_ms)))
    (concat
     " <- "
     (mapconcat
      #'spot--annotation-field
      `(,(ht-get* data 'name)
        ,(ht-get* data 'release_date)
        ,(ht-get* data 'description)
        ,(when duration-ms
           (number-to-string (spot--round-to-two-decimals (/ duration-ms 60000.0)))))
      " || "))))

(defun spot--annotate-audiobook (audiobook)
  "Annotate AUDIOBOOK with name, publisher, narrator, author, and description."
  (let* ((data (get-text-property 0 'multi-data audiobook))
         (desc (ht-get* data 'description)))
    (concat
     " <- "
     (mapconcat
      #'spot--annotation-field
      `(,(ht-get* data 'name)
        ,(ht-get* data 'publisher)
        ,(ht-get* (nth 0 (or (ht-get* data 'narrators) '(nil))) 'name)
        ,(ht-get* (nth 0 (or (ht-get* data 'authors) '(nil))) 'name)
        ,(when desc (string-replace "\n" " " desc)))
      " || "))))

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
