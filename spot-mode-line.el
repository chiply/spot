;;; spot-mode-line.el --- Mode-line display for spot -*- lexical-binding: t; -*-

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

;; Mode-line lighter showing the currently playing Spotify track.

;;; Code:

(require 'dash)
(require 'ht)

(require 'spot-generic-query)
(require 'spot-util)

(defface spot-mode-line
  '((t :foreground "#1db954"))
  "Face for the Spotify mode-line lighter.
The default color is the official Spotify green."
  :group 'spot)

(defvar spot--modeline-track nil
  "Currently playing track name.")

(defvar spot--modeline-artist nil
  "Currently playing artist name.")

(defvar spot--modeline-album nil
  "Currently playing album name.")

(defvar spot--modeline-repeat-state nil
  "Current repeat state (\"off\", \"track\", or \"context\").")

(defvar spot--modeline-release-date nil
  "Release date of the currently playing album.")

(defvar spot--modeline-shuffle-state nil
  "Current shuffle state.")

(defvar spot--modeline-smart-shuffle nil
  "Current smart shuffle state.")

(defvar spot--timer-started nil
  "Non-nil when the mode-line update timer has been started.")

(defvar spot--update-timers '()
  "List of active update timers.")

(defvar spot--update-interval 30
  "Interval in seconds between mode-line update checks.")

(defun spot--update-modeline-lighters (&optional current)
  "Fetch currently playing track and update mode-line variables.
If CURRENT is provided, use it instead of fetching from the API."
  (let ((current (or current (spot--alist-to-ht (spot--currently-playing)))))
    (if (and current (hash-table-p (ht-get current 'item)))
        (progn
          (setq spot--modeline-track
                (ht-get* current 'item 'name))
          (setq spot--modeline-artist
                (when-let* ((artists (ht-get* current 'item 'artists))
                            (first (nth 0 artists)))
                  (ht-get first 'name)))
          (setq spot--modeline-album
                (ht-get* current 'item 'album 'name))
          (setq spot--modeline-repeat-state
                (ht-get* current 'repeat_state))
          (setq spot--modeline-release-date
                (ht-get* current 'item 'album 'release_date))
          (setq spot--modeline-shuffle-state
                (ht-get* current 'shuffle_state))
          (setq spot--modeline-smart-shuffle
                (ht-get* current 'smart_shuffle)))
      (setq spot--modeline-track nil)
      (setq spot--modeline-artist nil)
      (setq spot--modeline-album nil)
      (setq spot--modeline-repeat-state nil)
      (setq spot--modeline-release-date nil)
      (setq spot--modeline-shuffle-state nil)
      (setq spot--modeline-smart-shuffle nil))))

(defun spot--check-for-modeline-update ()
  "Check for track change and schedule next update."
  (let ((current (spot--alist-to-ht (spot--currently-playing))))
    (spot--update-modeline-lighters current)
    (when-let* ((progress (and current (ht-get current 'progress_ms)))
                (item (ht-get current 'item))
                (duration (ht-get item 'duration_ms))
                (remaining (- duration progress))
                (delay (max 0 remaining)))
      (mapc #'cancel-timer spot--update-timers)
      (push
       (run-with-timer
        (+ (/ delay 1000.0) 1.0) nil
        #'spot--update-modeline-lighters nil)
       spot--update-timers))))

(defvar spot--periodic-timer nil
  "The periodic timer for mode-line updates.")

(defun spot--start-update-timer ()
  "Start the periodic mode-line update timer."
  (unless spot--timer-started
    (setq spot--periodic-timer
          (run-with-timer
           0 spot--update-interval
           #'spot--check-for-modeline-update))
    (setq spot--timer-started t)))

(defun spot--stop-update-timer ()
  "Stop the periodic mode-line update timer."
  (when spot--periodic-timer
    (cancel-timer spot--periodic-timer)
    (setq spot--periodic-timer nil))
  (mapc #'cancel-timer spot--update-timers)
  (setq spot--update-timers nil)
  (setq spot--timer-started nil))

(defun spot-mode-line-string ()
  "Return the mode-line string for the currently playing track."
  (let* ((lighters `(,spot--modeline-track
                     ,spot--modeline-artist
                     ,spot--modeline-album
                     ,spot--modeline-release-date
                     ,(cond
                       ((equal spot--modeline-repeat-state "off") nil)
                       ((equal spot--modeline-repeat-state nil) nil)
                       (t "repeat"))
                     ,(or
                       (cond
                        ((equal :json-false spot--modeline-smart-shuffle) nil)
                        ((equal t spot--modeline-smart-shuffle) "smart shuffle")
                        ((equal nil spot--modeline-smart-shuffle) nil))
                       (cond
                        ((equal :json-false spot--modeline-shuffle-state) nil)
                        ((equal t spot--modeline-shuffle-state) "shuffle")
                        ((equal nil spot--modeline-shuffle-state) nil)))))
         (lighters (remove nil lighters)))
    (propertize
     (if lighters (mapconcat #'identity lighters " * ") "*")
     'face 'spot-mode-line)))

(provide 'spot-mode-line)

;;; spot-mode-line.el ends here
