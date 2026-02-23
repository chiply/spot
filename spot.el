;;; spot.el --- Spotify client -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;; Author: Charlie Holland <mister.chiply@gmail.com>
;; Maintainer: Charlie Holland <mister.chiply@gmail.com>
;; URL: https://github.com/chiply/spot
;; Version: 0.1.2 ;; x-release-please-version
;; Package-Requires: ((emacs "29.1") (ht "2.3") (dash "2.19") (consult "1.0") (marginalia "1.0") (embark "0.23"))
;; Keywords: multimedia
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

;; spot is a Spotify client for Emacs built on top of consult, embark,
;; and marginalia.  It provides a multi-source search interface for
;; browsing and playing Spotify content directly from Emacs.
;;
;; Features:
;; - Consult-based multi-source search (albums, artists, tracks, etc.)
;; - Embark actions for playing, inspecting, and managing Spotify items
;; - Marginalia annotations showing rich metadata in completion
;; - Mode-line display of currently playing track
;; - Player controls (play, pause, next, previous)
;;
;; Quick start:
;; 1. Set `spot-client-id' and `spot-client-secret' to your Spotify
;;    application credentials
;; 2. Enable `spot-mode' to register embark/marginalia integrations
;; 3. Run M-x `spot-authorize' to authenticate
;; 4. Use M-x `spot-consult-search' to search Spotify
;;
;; Note on consult internals:
;; This package uses `consult--multi' and `consult--dynamic-collection'
;; to build multi-source async search.  These are the established
;; extension points for consult-based packages and are used by many
;; packages in the consult ecosystem (consult-dir, consult-gh,
;; consult-flycheck, etc.).  The minimum consult version is pinned to
;; 1.0 to ensure these APIs are available.

;;; Code:

(require 'spot-var)
(require 'spot-util)
(require 'spot-auth)
(require 'spot-search)
(require 'spot-consult)
(require 'spot-marginalia)
(require 'spot-embark)
(require 'spot-generic-action)
(require 'spot-generic-query)
(require 'spot-mode-line)

(declare-function spot--setup-embark "spot-embark")
(declare-function spot--teardown-embark "spot-embark")
(declare-function spot--setup-marginalia "spot-marginalia")
(declare-function spot--teardown-marginalia "spot-marginalia")
(declare-function spot--start-update-timer "spot-mode-line")
(declare-function spot--stop-update-timer "spot-mode-line")

;;;###autoload
(define-minor-mode spot-mode
  "Global minor mode for the spot Spotify client.
Registers embark keymaps, marginalia annotators, and starts the
mode-line update timer when enabled.  Cleanly removes all
integrations when disabled."
  :global t
  :group 'spot
  (if spot-mode
      (progn
        (spot--setup-embark)
        (spot--setup-marginalia)
        (spot--start-update-timer))
    (spot--teardown-embark)
    (spot--teardown-marginalia)
    (spot--stop-update-timer)))

(provide 'spot)

;;; spot.el ends here
