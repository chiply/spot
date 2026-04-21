;;; spot-marginalia.el --- Annotation functions for spot -*- lexical-binding: t; -*-

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

;; Marginalia annotation functions for Spotify search result categories.
;;
;; Annotations are built with `marginalia--fields' so they render as
;; aligned columns with per-field truncation and faces, matching the
;; look of marginalia's built-in annotators.

;;; Code:

(require 'ht)
(require 'marginalia)

;;; Faces

(defface spot-marginalia-artist
  '((t :inherit marginalia-type))
  "Face for artist, publisher, narrator, and author fields."
  :group 'spot)

(defface spot-marginalia-album
  '((t :inherit marginalia-value))
  "Face for album name references inside track annotations."
  :group 'spot)

(defface spot-marginalia-date
  '((t :inherit marginalia-date))
  "Face for release-date fields."
  :group 'spot)

(defface spot-marginalia-number
  '((t :inherit marginalia-number))
  "Face for numeric fields (counts, popularity, duration, track number)."
  :group 'spot)

(defface spot-marginalia-type
  '((t :inherit marginalia-type))
  "Face for type fields (album_type, media_type)."
  :group 'spot)

(defface spot-marginalia-description
  '((t :inherit marginalia-documentation))
  "Face for description fields."
  :group 'spot)

;;; Helpers

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

(defun spot--format-duration (ms)
  "Format duration MS in milliseconds as a minutes string (e.g. \"3.25\").
Return \"?\" when MS is nil."
  (if ms
      (number-to-string (spot--round-to-two-decimals (/ ms 60000.0)))
    "?"))

(defun spot--first-name (items)
  "Return the `name' of the first element in ITEMS, or nil when empty."
  (when-let* ((first (nth 0 items)))
    (ht-get first 'name)))

;;; Annotators

(defun spot--annotate-album (cand)
  "Annotate album CAND with artist, release date, and track count."
  (let ((data (get-text-property 0 'multi-data cand)))
    (marginalia--fields
     ((spot--annotation-field (spot--first-name (ht-get data 'artists)))
      :truncate 25 :face 'spot-marginalia-artist)
     ((spot--annotation-field (ht-get data 'release_date))
      :width 10 :face 'spot-marginalia-date)
     ((spot--annotation-field (ht-get data 'total_tracks))
      :width 5 :face 'spot-marginalia-number))))

(defun spot--annotate-artist (cand)
  "Annotate artist CAND with popularity and follower count."
  (let ((data (get-text-property 0 'multi-data cand)))
    (marginalia--fields
     ((spot--annotation-field (ht-get data 'popularity))
      :width 3 :face 'spot-marginalia-number)
     ((spot--annotation-field (ht-get* data 'followers 'total))
      :width 10 :face 'spot-marginalia-number))))

(defun spot--annotate-track (cand)
  "Annotate track CAND with number, artist, duration, album, type, and date."
  (let ((data (get-text-property 0 'multi-data cand)))
    (marginalia--fields
     ((spot--annotation-field (ht-get data 'track_number))
      :width 3 :face 'spot-marginalia-number)
     ((spot--annotation-field (spot--first-name (ht-get data 'artists)))
      :truncate 25 :face 'spot-marginalia-artist)
     ((spot--format-duration (ht-get data 'duration_ms))
      :width 6 :face 'spot-marginalia-number)
     ((spot--annotation-field (ht-get* data 'album 'name))
      :truncate 30 :face 'spot-marginalia-album)
     ((spot--annotation-field (ht-get* data 'album 'album_type))
      :width 8 :face 'spot-marginalia-type)
     ((spot--annotation-field (ht-get* data 'album 'release_date))
      :width 10 :face 'spot-marginalia-date))))

(defun spot--annotate-playlist (cand)
  "Annotate playlist CAND with track count."
  (let ((data (get-text-property 0 'multi-data cand)))
    (marginalia--fields
     ((spot--annotation-field (ht-get* data 'tracks 'total))
      :width 5 :face 'spot-marginalia-number))))

(defun spot--annotate-show (cand)
  "Annotate show CAND with publisher, media type, episode count, and description."
  (let ((data (get-text-property 0 'multi-data cand)))
    (marginalia--fields
     ((spot--annotation-field (ht-get data 'publisher))
      :truncate 25 :face 'spot-marginalia-artist)
     ((spot--annotation-field (ht-get data 'media_type))
      :width 8 :face 'spot-marginalia-type)
     ((spot--annotation-field (ht-get data 'total_episodes))
      :width 5 :face 'spot-marginalia-number)
     ((spot--annotation-field (ht-get data 'description))
      :truncate 60 :face 'spot-marginalia-description))))

(defun spot--annotate-episode (cand)
  "Annotate episode CAND with release date, duration, and description."
  (let ((data (get-text-property 0 'multi-data cand)))
    (marginalia--fields
     ((spot--annotation-field (ht-get data 'release_date))
      :width 10 :face 'spot-marginalia-date)
     ((spot--format-duration (ht-get data 'duration_ms))
      :width 6 :face 'spot-marginalia-number)
     ((spot--annotation-field (ht-get data 'description))
      :truncate 60 :face 'spot-marginalia-description))))

(defun spot--annotate-audiobook (cand)
  "Annotate audiobook CAND with publisher, narrator, author, and description."
  (let* ((data (get-text-property 0 'multi-data cand))
         (desc (ht-get data 'description)))
    (marginalia--fields
     ((spot--annotation-field (ht-get data 'publisher))
      :truncate 25 :face 'spot-marginalia-artist)
     ((spot--annotation-field (spot--first-name (ht-get data 'narrators)))
      :truncate 25 :face 'spot-marginalia-artist)
     ((spot--annotation-field (spot--first-name (ht-get data 'authors)))
      :truncate 25 :face 'spot-marginalia-artist)
     ((spot--annotation-field (when desc (string-replace "\n" " " desc)))
      :truncate 60 :face 'spot-marginalia-description))))

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
