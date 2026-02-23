;;; spot-util.el --- Utility functions for spot -*- lexical-binding: t; -*-

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

;; Helper functions for alist/hash-table conversion, propertizing,
;; and filtering.

;;; Code:

(require 'ht)
(require 'dash)

(defun spot--alist-get-chain (symbols alist)
  "Look up the value for the chain of SYMBOLS in ALIST.
Recursively follows the chain of keys to retrieve nested values
from an association list."
  (if symbols
      (spot--alist-get-chain (cdr symbols)
                             (assoc (car symbols) alist))
    (cdr alist)))

(defun spot--alist-to-ht (alist)
  "Convert ALIST (a JSON-parsed object) to a hash table.
Handles nested alists and arrays recursively."
  (cond
   ((and (consp alist) (consp (car alist)))
    (ht-from-alist
     (mapcar (lambda (pair)
               (cons (car pair)
                     (spot--alist-to-ht (cdr pair))))
             alist)))
   ((vectorp alist)
    (mapcar #'spot--alist-to-ht alist))
   (t alist)))

(defun spot--propertize-items (tables)
  "Propertize a list of hash TABLES for display in completion.
Each table is expected to have `name' and `type' keys."
  (-map
   (lambda (table)
     (propertize
      (ht-get table 'name)
      'category (intern (ht-get table 'type))
      'multi-data table))
   tables))

(defun spot--type-equals (cand type)
  "Return non-nil if candidate CAND has Spotify type TYPE."
  (string= (ht-get (get-text-property 0 'multi-data cand) 'type) type))

(defun spot--filter (candidates type)
  "Filter CANDIDATES to those matching Spotify TYPE."
  (-filter (lambda (cand) (spot--type-equals cand type)) candidates))

(provide 'spot-util)

;;; spot-util.el ends here
