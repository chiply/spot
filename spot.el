;;; spot.el --- Spotify client -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;; Author: Charlie Holland <mister.chiply@gmail.com>
;; Maintainer: Charlie Holland <mister.chiply@gmail.com>
;; URL: https://github.com/chiply/spot
;; x-release-please-start-version
;; Version: 0.1.0
;; x-release-please-end
;; Package-Requires: ((emacs "29.1") (ht "2.3") (dash "2.19") (consult "1.0") (marginalia "1.0") (embark "0.23"))
;; Keywords: multimedia

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
;; To get started:
;; 1. Set `spot-client-id' and `spot-client-secret' to your Spotify
;;    application credentials
;; 2. Run M-x `spot-authorize' to authenticate
;; 3. Use M-x `spot-consult-search' to search Spotify

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

(provide 'spot)

;;; spot.el ends here
