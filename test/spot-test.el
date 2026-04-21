;;; spot-test.el --- Tests for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;;; Commentary:

;; ERT tests for spot.

;;; Code:

(require 'ert)
(require 'ht)
(require 'spot-util)
(require 'spot-search)
(require 'spot-mode-line)
(require 'spot-marginalia)
(require 'spot-var)
(require 'spot-auth)


;;; spot--alist-get-chain

(ert-deftest spot-test-alist-get-chain/single-key ()
  "Look up a single key in a flat alist."
  (let ((alist '((name . "test"))))
    (should (equal (spot--alist-get-chain '(name) alist) "test"))))

(ert-deftest spot-test-alist-get-chain/nested-keys ()
  "Look up nested keys in an alist."
  (let ((alist '((outer (inner . "value")))))
    (should (equal (spot--alist-get-chain '(outer inner) alist) "value"))))

(ert-deftest spot-test-alist-get-chain/missing-key ()
  "Return nil for a missing key."
  (let ((alist '((name . "test"))))
    (should-not (spot--alist-get-chain '(missing) alist))))

(ert-deftest spot-test-alist-get-chain/empty-symbols ()
  "Return nil when symbols list is empty."
  (let ((alist '((name . "test"))))
    (should-not (spot--alist-get-chain '() alist))))


;;; spot--alist-to-ht

(ert-deftest spot-test-alist-to-ht/flat-alist ()
  "Convert a flat alist to a hash table."
  (let ((result (spot--alist-to-ht '((name . "test") (type . "track")))))
    (should (hash-table-p result))
    (should (equal (ht-get result 'name) "test"))
    (should (equal (ht-get result 'type) "track"))))

(ert-deftest spot-test-alist-to-ht/nested-alist ()
  "Convert a nested alist to nested hash tables."
  (let ((result (spot--alist-to-ht '((album (name . "OK Computer"))))))
    (should (hash-table-p result))
    (should (hash-table-p (ht-get result 'album)))
    (should (equal (ht-get (ht-get result 'album) 'name) "OK Computer"))))

(ert-deftest spot-test-alist-to-ht/vector ()
  "Convert a vector of alists."
  (let ((result (spot--alist-to-ht [((name . "a")) ((name . "b"))])))
    (should (listp result))
    (should (= (length result) 2))
    (should (equal (ht-get (nth 0 result) 'name) "a"))
    (should (equal (ht-get (nth 1 result) 'name) "b"))))

(ert-deftest spot-test-alist-to-ht/primitive ()
  "Return primitive values as-is."
  (should (equal (spot--alist-to-ht "hello") "hello"))
  (should (equal (spot--alist-to-ht 42) 42))
  (should (equal (spot--alist-to-ht nil) nil)))


;;; spot--parse-command

(ert-deftest spot-test-parse-command/simple-query ()
  "Parse a simple query with no arguments."
  (let ((result (spot--parse-command "radiohead")))
    (should (equal (car result) "radiohead"))
    (should-not (cadr result))))

(ert-deftest spot-test-parse-command/query-with-args ()
  "Parse a query with arguments."
  (let ((result (spot--parse-command "radiohead -- --type=track")))
    (should (equal (car result) "radiohead"))
    (should (equal (cadr result) '(("type" . "track"))))))

(ert-deftest spot-test-parse-command/multiple-args ()
  "Parse a query with multiple arguments."
  (let ((result (spot--parse-command "jazz -- --type=track --market=US")))
    (should (equal (car result) "jazz"))
    (should (= (length (cadr result)) 2))))


;;; spot--filter and spot--type-equals

(ert-deftest spot-test-type-equals/match ()
  "Return non-nil when type matches."
  (let* ((table (ht ('type "track") ('name "Creep")))
         (cand (propertize "Creep" 'multi-data table)))
    (should (spot--type-equals cand "track"))))

(ert-deftest spot-test-type-equals/no-match ()
  "Return nil when type does not match."
  (let* ((table (ht ('type "album") ('name "The Bends")))
         (cand (propertize "The Bends" 'multi-data table)))
    (should-not (spot--type-equals cand "track"))))

(ert-deftest spot-test-filter/basic ()
  "Filter candidates by type."
  (let* ((track-table (ht ('type "track") ('name "Creep")))
         (album-table (ht ('type "album") ('name "The Bends")))
         (track (propertize "Creep" 'multi-data track-table))
         (album (propertize "The Bends" 'multi-data album-table))
         (candidates (list track album)))
    (should (= (length (spot--filter candidates "track")) 1))
    (should (= (length (spot--filter candidates "album")) 1))
    (should (= (length (spot--filter candidates "artist")) 0))))


;;; spot-mode-line-string

(ert-deftest spot-test-mode-line-string/no-track ()
  "Return \"*\" when nothing is playing."
  (let ((spot--modeline-track nil)
        (spot--modeline-artist nil)
        (spot--modeline-album nil)
        (spot--modeline-release-date nil)
        (spot--modeline-repeat-state nil)
        (spot--modeline-shuffle-state nil)
        (spot--modeline-smart-shuffle nil))
    (should (equal (substring-no-properties (spot-mode-line-string)) "*"))))

(ert-deftest spot-test-mode-line-string/playing ()
  "Return track info when a track is playing."
  (let ((spot--modeline-track "Creep")
        (spot--modeline-artist "Radiohead")
        (spot--modeline-album "Pablo Honey")
        (spot--modeline-release-date "1993-02-22")
        (spot--modeline-repeat-state "off")
        (spot--modeline-shuffle-state :json-false)
        (spot--modeline-smart-shuffle nil))
    (let ((result (substring-no-properties (spot-mode-line-string))))
      (should (string-match-p "Creep" result))
      (should (string-match-p "Radiohead" result))
      (should (string-match-p "Pablo Honey" result)))))

(ert-deftest spot-test-mode-line-string/with-shuffle ()
  "Include shuffle indicator when shuffle is on."
  (let ((spot--modeline-track "Creep")
        (spot--modeline-artist "Radiohead")
        (spot--modeline-album "Pablo Honey")
        (spot--modeline-release-date nil)
        (spot--modeline-repeat-state "off")
        (spot--modeline-shuffle-state t)
        (spot--modeline-smart-shuffle nil))
    (let ((result (substring-no-properties (spot-mode-line-string))))
      (should (string-match-p "shuffle" result)))))


;;; Variable initialization

(ert-deftest spot-test-var/default-credentials ()
  "Credentials default to nil."
  (should-not (default-value 'spot-client-id))
  (should-not (default-value 'spot-client-secret)))

(ert-deftest spot-test-var/request-timeout ()
  "Request timeout has a sensible default."
  (should (numberp spot--request-timeout))
  (should (> spot--request-timeout 0)))


;;; spot--round-to-two-decimals

(ert-deftest spot-test-round-to-two-decimals ()
  "Round numbers to two decimal places."
  (should (= (spot--round-to-two-decimals 3.14159) 3.14))
  (should (= (spot--round-to-two-decimals 1.0) 1.0))
  (should (= (spot--round-to-two-decimals 2.567) 2.57)))


;;; spot-mode

(ert-deftest spot-test-mode/enable-registers-embark ()
  "Enabling spot-mode registers embark keymaps."
  (require 'spot)
  (unwind-protect
      (progn
        (spot-mode 1)
        (should (assq 'album embark-keymap-alist))
        (should (assq 'track embark-keymap-alist)))
    (spot-mode -1)))

(ert-deftest spot-test-mode/disable-unregisters-embark ()
  "Disabling spot-mode removes embark keymaps."
  (require 'spot)
  (spot-mode 1)
  (spot-mode -1)
  (should-not (assq 'album embark-keymap-alist))
  (should-not (assq 'track embark-keymap-alist)))

(ert-deftest spot-test-mode/enable-registers-marginalia ()
  "Enabling spot-mode registers marginalia annotators."
  (require 'spot)
  (unwind-protect
      (progn
        (spot-mode 1)
        (should (assq 'album marginalia-annotators))
        (should (assq 'track marginalia-annotators)))
    (spot-mode -1)))


;;; spot--refresh-timer

(ert-deftest spot-test-refresh-timer/enable-starts-timer ()
  "Enabling spot-mode starts the refresh timer."
  (require 'spot)
  (let ((spot-refresh-token nil)) ; avoid triggering an actual refresh
    (unwind-protect
        (progn
          (spot-mode 1)
          (should (timerp spot--refresh-timer)))
      (spot-mode -1))))

(ert-deftest spot-test-refresh-timer/disable-stops-timer ()
  "Disabling spot-mode stops the refresh timer."
  (require 'spot)
  (let ((spot-refresh-token nil))
    (spot-mode 1)
    (spot-mode -1)
    (should-not spot--refresh-timer)))

(ert-deftest spot-test-refresh-timer/nil-interval-skips-timer ()
  "Setting `spot-refresh-interval' to nil disables the refresh timer."
  (require 'spot)
  (let ((spot-refresh-interval nil)
        (spot-refresh-token nil))
    (unwind-protect
        (progn
          (spot-mode 1)
          (should-not spot--refresh-timer))
      (spot-mode -1))))


;;; Annotators

(defun spot-test--cand (data)
  "Return a propertized candidate carrying DATA as `multi-data'."
  (propertize (or (ht-get data 'name) "cand") 'multi-data data))

(ert-deftest spot-test-annotate-album/contains-fields ()
  "Album annotation includes artist, release date, and track count."
  (let* ((data (ht ('name "Kid A")
                   ('artists (list (ht ('name "Radiohead"))))
                   ('release_date "2000-10-02")
                   ('total_tracks 11)))
         (ann (substring-no-properties
               (spot--annotate-album (spot-test--cand data)))))
    (should (string-match-p "Radiohead" ann))
    (should (string-match-p "2000-10-02" ann))
    (should (string-match-p "11" ann))
    (should-not (string-match-p " <- " ann))
    (should-not (string-match-p " || " ann))))

(ert-deftest spot-test-annotate-track/contains-fields ()
  "Track annotation includes number, artist, duration, album, type, and date."
  (let* ((data (ht ('name "Everything In Its Right Place")
                   ('track_number 1)
                   ('duration_ms 251000)
                   ('artists (list (ht ('name "Radiohead"))))
                   ('album (ht ('name "Kid A")
                               ('album_type "album")
                               ('release_date "2000-10-02")))))
         (ann (substring-no-properties
               (spot--annotate-track (spot-test--cand data)))))
    (should (string-match-p "Radiohead" ann))
    (should (string-match-p "Kid A" ann))
    (should (string-match-p "4.18" ann))
    (should (string-match-p "album" ann))
    (should (string-match-p "2000-10-02" ann))))

(ert-deftest spot-test-annotate-audiobook/handles-empty-narrators ()
  "Audiobook annotation survives empty narrator and author lists."
  (let* ((data (ht ('name "Book")
                   ('publisher "Publisher")
                   ('narrators '())
                   ('authors '())
                   ('description "line1\nline2")))
         (ann (substring-no-properties
               (spot--annotate-audiobook (spot-test--cand data)))))
    (should (string-match-p "Publisher" ann))
    (should (string-match-p "line1 line2" ann))
    (should-not (string-match-p "\n" ann))))

(ert-deftest spot-test-annotation-field/nil-returns-question-mark ()
  "Missing values render as \"?\"."
  (should (equal (spot--annotation-field nil) "?")))

(ert-deftest spot-test-format-duration/nil-returns-question-mark ()
  "Duration formatter tolerates a nil input."
  (should (equal (spot--format-duration nil) "?")))

(ert-deftest spot-test-format-duration/minutes ()
  "Duration formatter returns minutes rounded to two decimals."
  (should (equal (spot--format-duration 251000) "4.18")))

(provide 'spot-test)

;;; spot-test.el ends here
