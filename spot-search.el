;;; spot-search.el --- Search with mutex/cache for spot -*- lexical-binding: t; -*-

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

;; Spotify search with mutex-based locking and result caching.

;;; Code:

(require 'ht)
(require 'dash)

(require 'spot-util)
(require 'spot-var)
(require 'spot-generic-query)

;; Mutex and cache

(defvar spot--mutex (make-mutex)
  "Mutex to ensure only one search request runs at a time.")

(defvar spot--cache (ht-create)
  "Cache of search results keyed by query string.")

;; Candidate lists

(defvar spot--candidates-album '()
  "Current album candidates from the most recent search.")

(defvar spot--candidates-artist '()
  "Current artist candidates from the most recent search.")

(defvar spot--candidates-playlist '()
  "Current playlist candidates from the most recent search.")

(defvar spot--candidates-track '()
  "Current track candidates from the most recent search.")

(defvar spot--candidates-show '()
  "Current show candidates from the most recent search.")

(defvar spot--candidates-episode '()
  "Current episode candidates from the most recent search.")

(defvar spot--candidates-audiobook '()
  "Current audiobook candidates from the most recent search.")

(defun spot--parse-command (input)
  "Parse INPUT into a query and optional arguments.
Returns a list of (QUERY ARGS) where ARGS is an alist.
Arguments are separated from the query by \" -- \" and are
in the form \"--key=value\"."
  (if (string-match "\\(.*?\\)\\s-+--\\s-+\\(.*\\)" input)
      (let* ((query (match-string 1 input))
             (args-str (match-string 2 input))
             (args (mapcar
                    (lambda (arg)
                      (when (string-match
                             "\\(?:--\\)?\\([^=]+\\)=\\(.*\\)" arg)
                        (cons (match-string 1 arg)
                              (match-string 2 arg))))
                    (split-string args-str))))
        (list query (delq nil args)))
    (list input nil)))

(defun spot--transform-alist-to-q-params (alist)
  "Transform ALIST into URL query parameter string."
  (let ((pairs (car alist)))
    (if pairs
        (mapconcat
         (lambda (x) (concat "&" (car x) "=" (cdr x)))
         pairs "")
      "")))

(defun spot--search-items (input)
  "Search for items on Spotify based on INPUT.
Returns a hash table of search results."
  (let* ((parsed-command (spot--parse-command input))
         (query (car parsed-command))
         (args (cdr parsed-command))
         (args (spot--transform-alist-to-q-params args))
         (q-params (concat
                    "?type=" "album," "artist,"
                    "playlist," "track," "show," "episode,"
                    "audiobook"
                    "&q=" query
                    args))
         (alist (spot-request
                 :method "GET"
                 :url spot-search-url
                 :q-params q-params
                 :parse-json t)))
    (spot--alist-to-ht alist)))

(defun spot--union-search-items (table)
  "Combine all item types from search results TABLE into a single vector."
  (vconcat
   (when (ht-get* table 'albums) (ht-get* table 'albums 'items))
   (when (ht-get* table 'artists) (ht-get* table 'artists 'items))
   (when (ht-get* table 'playlists) (ht-get* table 'playlists 'items))
   (when (ht-get* table 'tracks) (ht-get* table 'tracks 'items))
   (when (ht-get* table 'shows) (ht-get* table 'shows 'items))
   (when (ht-get* table 'episodes) (ht-get* table 'episodes 'items))
   (when (ht-get* table 'audiobooks) (ht-get* table 'audiobooks 'items))))

(defun spot--set-search-candidates (candidates)
  "Set per-type candidate lists from CANDIDATES."
  (setq spot--candidates-album (spot--filter candidates "album"))
  (setq spot--candidates-artist (spot--filter candidates "artist"))
  (setq spot--candidates-playlist (spot--filter candidates "playlist"))
  (setq spot--candidates-track (spot--filter candidates "track"))
  (setq spot--candidates-show (spot--filter candidates "show"))
  (setq spot--candidates-episode (spot--filter candidates "episode"))
  (setq spot--candidates-audiobook (spot--filter candidates "audiobook")))

(defun spot--search-cached (query cache)
  "Search for QUERY, using CACHE to avoid duplicate requests."
  (when (not (ht-get cache query))
    (let ((results (spot--propertize-items
                    (spot--union-search-items
                     (spot--search-items query)))))
      (ht-set cache query results)))
  (let ((results (ht-get cache query)))
    (spot--set-search-candidates results)))

(defun spot--search-cached-and-locked (query mutex cache)
  "Search for QUERY using MUTEX for thread safety and CACHE for results."
  (with-mutex mutex
    (spot--search-cached query cache)))

(provide 'spot-search)

;;; spot-search.el ends here
