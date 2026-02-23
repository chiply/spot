;;; spot-consult.el --- Consult multi-source search for spot -*- lexical-binding: t; -*-

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

;; Consult-based multi-source search interface for Spotify.

;;; Code:

(require 'consult)
(require 'dash)

(require 'spot-util)
(require 'spot-search)
(require 'spot-var)
(require 'spot-generic-query)

;;; Completion functions

(defun spot--consult-completion-function-consult-album (query)
  "Return album candidates for QUERY."
  (spot--search-cached-and-locked query spot--mutex spot--cache)
  spot--candidates-album)

(defun spot--consult-completion-function-consult-artist (query)
  "Return artist candidates for QUERY."
  (spot--search-cached-and-locked query spot--mutex spot--cache)
  spot--candidates-artist)

(defun spot--consult-completion-function-consult-playlist (query)
  "Return playlist candidates for QUERY."
  (spot--search-cached-and-locked query spot--mutex spot--cache)
  spot--candidates-playlist)

(defun spot--consult-completion-function-consult-track (query)
  "Return track candidates for QUERY."
  (spot--search-cached-and-locked query spot--mutex spot--cache)
  spot--candidates-track)

(defun spot--consult-completion-function-consult-show (query)
  "Return show candidates for QUERY."
  (spot--search-cached-and-locked query spot--mutex spot--cache)
  spot--candidates-show)

(defun spot--consult-completion-function-consult-episode (query)
  "Return episode candidates for QUERY."
  (spot--search-cached-and-locked query spot--mutex spot--cache)
  spot--candidates-episode)

(defun spot--consult-completion-function-consult-audiobook (query)
  "Return audiobook candidates for QUERY."
  (spot--search-cached-and-locked query spot--mutex spot--cache)
  spot--candidates-audiobook)

;;; History variables

(defvar spot--history-source-album nil
  "History for album source.")

(defvar spot--history-source-artist nil
  "History for artist source.")

(defvar spot--history-source-playlist nil
  "History for playlist source.")

(defvar spot--history-source-track nil
  "History for track source.")

(defvar spot--history-source-show nil
  "History for show source.")

(defvar spot--history-source-episode nil
  "History for episode source.")

(defvar spot--history-source-audiobook nil
  "History for audiobook source.")

;;; Sources

(defvar spot--consult-source-album
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-album
             :min-input 1)
    :name "Album"
    :narrow ?a
    :category album
    :history spot--history-source-album)
  "Consult source for Spotify albums.")

(defvar spot--consult-source-artist
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-artist
             :min-input 1)
    :name "Artist"
    :narrow ?A
    :category artist
    :history spot--history-source-artist)
  "Consult source for Spotify artists.")

(defvar spot--consult-source-playlist
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-playlist
             :min-input 1)
    :name "Playlist"
    :narrow ?p
    :category playlist
    :history spot--history-source-playlist)
  "Consult source for Spotify playlists.")

(defvar spot--consult-source-track
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-track
             :min-input 1)
    :name "Track"
    :narrow ?t
    :category track
    :history spot--history-source-track)
  "Consult source for Spotify tracks.")

(defvar spot--consult-source-show
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-show
             :min-input 1)
    :name "Show"
    :narrow ?s
    :category show
    :history spot--history-source-show)
  "Consult source for Spotify shows.")

(defvar spot--consult-source-episode
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-episode
             :min-input 1)
    :name "Episode"
    :narrow ?e
    :category episode
    :history spot--history-source-episode)
  "Consult source for Spotify episodes.")

(defvar spot--consult-source-audiobook
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-audiobook
             :min-input 1)
    :name "Audiobook"
    :narrow ?b
    :category audiobook
    :history spot--history-source-audiobook)
  "Consult source for Spotify audiobooks.")

(defvar spot--search-sources
  '(spot--consult-source-album spot--consult-source-artist
    spot--consult-source-playlist spot--consult-source-track
    spot--consult-source-show spot--consult-source-episode
    spot--consult-source-audiobook)
  "List of consult sources for Spotify search.")

;;; Multi-search

(defvar spot--consult-search-search-history nil
  "History for the main Spotify search command.")

;;;###autoload
(defun spot-consult-search (&optional initial)
  "Search Spotify with consult multi-source completion.
Optional INITIAL provides initial input."
  (interactive)
  (consult--multi
   spot--search-sources
   :history '(:input spot--consult-search-search-history)
   :initial initial))

;;; Current user playlists

(defun spot--consult-completion-function-consult-current-user-playlists (_query)
  "Return the current user's playlists.
QUERY argument is ignored as all playlists are returned."
  (spot--propertize-items
   (ht-get*
    (spot--alist-to-ht
     (spot-request
      :method "GET"
      :url (format "%s/playlists" spot-me-url)
      :q-params (spot--base-q-params)
      :parse-json t))
    'items)))

(defvar spot--history-source-current-user-playlists nil
  "History for current user playlists source.")

(defvar spot--consult-source-current-user-playlists
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-consult-current-user-playlists
             :min-input 0)
    :name "Current User Playlists"
    :narrow ?b
    :category current-user-playlists
    :history spot--history-source-current-user-playlists)
  "Consult source for current user's playlists.")

(defvar spot--consult-search-current-user-playlists-history nil
  "History for current user playlists search.")

;;;###autoload
(defun spot-consult-search-current-user-playlists ()
  "Browse the current user's Spotify playlists.
Lists all playlists; use SPC and comma to filter the output."
  (interactive)
  (consult--multi
   '(spot--consult-source-current-user-playlists)
   :history '(:input spot--consult-search-current-user-playlists-history)))

;;; Playlist tracks

(defun spot--consult-completion-function-playlist-tracks (_query)
  "Return tracks for the selected playlist.
QUERY argument is ignored as all tracks are returned."
  (spot--propertize-items
   (-map
    (lambda (x) (ht-get* x 'track))
    (ht-get*
     (spot--alist-to-ht
      (spot-request
       :method "GET"
       :url (format "%s/%s/tracks" spot-playlist-url spot--selected-playlist-id)
       :q-params (spot--base-q-params)
       :parse-json t))
     'items))))

(defvar spot--history-source-playlist-tracks nil
  "History for playlist tracks source.")

(defvar spot--consult-source-playlists-tracks
  `(:async ,(consult--dynamic-collection
             #'spot--consult-completion-function-playlist-tracks
             :min-input 0)
    :name "Playlist Tracks"
    :narrow ?b
    :category playlist-tracks
    :history spot--history-source-playlist-tracks)
  "Consult source for tracks in a playlist.")

(defvar spot--consult-search-playlist-tracks-history nil
  "History for playlist tracks search.")

;;;###autoload
(defun spot-consult-search-playlist-tracks ()
  "Browse tracks in the selected Spotify playlist.
Lists all tracks; use SPC and comma to filter the output."
  (interactive)
  (consult--multi
   '(spot--consult-source-playlists-tracks)
   :history '(:input spot--consult-search-playlist-tracks-history)))

(provide 'spot-consult)

;;; spot-consult.el ends here
