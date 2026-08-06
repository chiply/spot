;;; spot-test.el --- Tests for spot -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charlie Holland

;;; Commentary:

;; ERT tests for spot.

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'ht)
(require 'spot-util)
(require 'spot-search)
(require 'spot-mode-line)
(require 'spot-marginalia)
(require 'spot-var)
(require 'spot-auth)
(require 'spot-generic-query)


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

(ert-deftest spot-test-parse-command/quoted-field-with-separator ()
  "A \" -- \" inside a double-quoted field is part of the query."
  (let ((result (spot--parse-command
                 "album:\"Foo -- Live\" artist:\"Bar\" -- --type=track")))
    (should (equal (car result) "album:\"Foo -- Live\" artist:\"Bar\""))
    (should (equal (cadr result) '(("type" . "track"))))))

(ert-deftest spot-test-parse-command/quoted-field-no-args ()
  "A quoted field with an internal \" -- \" but no real args separator."
  (let ((result (spot--parse-command "album:\"Foo -- Live\"")))
    (should (equal (car result) "album:\"Foo -- Live\""))
    (should-not (cadr result))))

(ert-deftest spot-test-parse-command/quoted-field-with-spaces ()
  "Spaces inside a quoted field are preserved in the query."
  (let ((result (spot--parse-command
                 "artist:\"Pink Floyd\" -- --type=track")))
    (should (equal (car result) "artist:\"Pink Floyd\""))
    (should (equal (cadr result) '(("type" . "track"))))))


;;; spot--build-search-q-params

(ert-deftest spot-test-build-search-q-params/default-types-when-no-args ()
  "The default type list is included when no args are given."
  (let ((q (spot--build-search-q-params '("radiohead" nil))))
    (should (string-match-p "q=radiohead" q))
    (should (string-match-p
             "&type=album,artist,playlist,track,show,episode,audiobook"
             q))))

(ert-deftest spot-test-build-search-q-params/user-type-replaces-default ()
  "A user-supplied type arg replaces the default type list."
  (let ((q (spot--build-search-q-params
            '("foo" (("type" . "track"))))))
    (should-not (string-match-p "type=album," q))
    (should (string-match-p "&type=track" q))))

(ert-deftest spot-test-build-search-q-params/non-type-args-keep-default ()
  "Non-type args don't suppress the default type list."
  (let ((q (spot--build-search-q-params
            '("foo" (("market" . "US"))))))
    (should (string-match-p "&type=album," q))
    (should (string-match-p "&market=US" q))))


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


;;; spot--truncate-name

(ert-deftest spot-test-truncate-name/under-limit ()
  "Names shorter than the limit pass through unchanged."
  (let ((spot-candidate-max-width 20))
    (should (equal (spot--truncate-name "Short name") "Short name"))))

(ert-deftest spot-test-truncate-name/over-limit ()
  "Names longer than the limit are truncated with an ellipsis."
  (let* ((spot-candidate-max-width 10)
         (result (spot--truncate-name "A much longer name that overflows")))
    (should (<= (string-width result) 10))
    (should (string-suffix-p "…" result))))

(ert-deftest spot-test-truncate-name/nil-disables ()
  "Setting the limit to nil returns the name unchanged."
  (let ((spot-candidate-max-width nil)
        (long (make-string 200 ?a)))
    (should (equal (spot--truncate-name long) long))))

(ert-deftest spot-test-propertize-items/truncates-long-names ()
  "Long candidate names are truncated; `multi-data' keeps the full name."
  (let* ((spot-candidate-max-width 10)
         (full-name (make-string 50 ?x))
         (table (ht ('name full-name) ('type "track")))
         (cands (spot--propertize-items (list table)))
         (cand (car cands)))
    (should (<= (string-width cand) 10))
    (should (equal (ht-get (get-text-property 0 'multi-data cand) 'name)
                   full-name))))


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
  "Album annotation includes artist, release date, and `#'-prefixed track count."
  (let* ((data (ht ('name "Kid A")
                   ('artists (list (ht ('name "Radiohead"))))
                   ('release_date "2000-10-02")
                   ('total_tracks 11)))
         (ann (substring-no-properties
               (spot--annotate-album (spot-test--cand data)))))
    (should (string-match-p "Radiohead" ann))
    (should (string-match-p "2000-10-02" ann))
    (should (string-match-p "#11" ann))
    (should-not (string-match-p " <- " ann))
    (should-not (string-match-p " || " ann))))

(ert-deftest spot-test-annotate-artist/contains-fields ()
  "Artist annotation prefixes popularity with `★' and followers with `♥'."
  (let* ((data (ht ('name "Radiohead")
                   ('popularity 87)
                   ('followers (ht ('total 2175423)))))
         (ann (substring-no-properties
               (spot--annotate-artist (spot-test--cand data)))))
    (should (string-match-p "★87" ann))
    (should (string-match-p "♥2\\.2M" ann))))

(ert-deftest spot-test-annotate-track/contains-fields ()
  "Track annotation includes `#'-number, artist, M:SS duration, album, type, and date."
  (let* ((data (ht ('name "Everything In Its Right Place")
                   ('track_number 1)
                   ('duration_ms 251000)
                   ('artists (list (ht ('name "Radiohead"))))
                   ('album (ht ('name "Kid A")
                               ('album_type "album")
                               ('release_date "2000-10-02")))))
         (ann (substring-no-properties
               (spot--annotate-track (spot-test--cand data)))))
    (should (string-match-p "#1" ann))
    (should (string-match-p "Radiohead" ann))
    (should (string-match-p "Kid A" ann))
    (should (string-match-p "4:11" ann))
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

(ert-deftest spot-test-format-duration/mm-ss ()
  "Duration formatter renders milliseconds as M:SS."
  (should (equal (spot--format-duration 251000) "4:11"))
  (should (equal (spot--format-duration 5000) "0:05"))
  (should (equal (spot--format-duration 3599000) "59:59")))

(ert-deftest spot-test-format-count/thresholds ()
  "Count formatter humanizes large numbers, leaves small ones bare."
  (should (equal (spot--format-count nil) "?"))
  (should (equal (spot--format-count 0) "0"))
  (should (equal (spot--format-count 42) "42"))
  (should (equal (spot--format-count 9999) "9999"))
  (should (equal (spot--format-count 10000) "10K"))
  (should (equal (spot--format-count 2175423) "2.2M"))
  (should (equal (spot--format-count 1500000000) "1.5B")))


;;; Token freshness

(ert-deftest spot-test-token-stale-p/nil-token-is-stale ()
  "A missing access token is stale."
  (let ((spot-access-token nil)
        (spot--token-expires-at nil))
    (should (spot--token-stale-p))))

(ert-deftest spot-test-token-stale-p/fresh-token-is-not-stale ()
  "A token far from expiry is not stale."
  (let ((spot-access-token "tok")
        (spot--token-expires-at (+ (float-time) 3600)))
    (should-not (spot--token-stale-p))))

(ert-deftest spot-test-token-stale-p/near-expiry-is-stale ()
  "A token inside the refresh margin is stale."
  (let ((spot-access-token "tok")
        (spot-token-refresh-margin 300)
        (spot--token-expires-at (+ (float-time) 10)))
    (should (spot--token-stale-p))))

(ert-deftest spot-test-token-stale-p/unknown-expiry-is-not-stale ()
  "A manually set token without expiry info is trusted until a 401."
  (let ((spot-access-token "tok")
        (spot--token-expires-at nil))
    (should-not (spot--token-stale-p))))

(ert-deftest spot-test-ensure-fresh-token/no-refresh-token-is-noop ()
  "Without a refresh token no refresh is attempted."
  (let ((spot-access-token nil)
        (spot--token-expires-at nil)
        (spot-refresh-token nil)
        (called nil))
    (cl-letf (((symbol-function 'spot-refresh-synchronously)
               (lambda () (setq called t))))
      (spot--ensure-fresh-token))
    (should-not called)))

(ert-deftest spot-test-ensure-fresh-token/stale-token-refreshes ()
  "A stale token triggers a synchronous refresh."
  (let ((spot-access-token nil)
        (spot--token-expires-at nil)
        (spot-refresh-token "refresh")
        (called nil))
    (cl-letf (((symbol-function 'spot-refresh-synchronously)
               (lambda () (setq called t))))
      (spot--ensure-fresh-token))
    (should called)))

(ert-deftest spot-test-ensure-fresh-token/fresh-token-is-noop ()
  "A fresh token does not trigger a refresh."
  (let ((spot-access-token "tok")
        (spot--token-expires-at (+ (float-time) 3600))
        (spot-refresh-token "refresh")
        (called nil))
    (cl-letf (((symbol-function 'spot-refresh-synchronously)
               (lambda () (setq called t))))
      (spot--ensure-fresh-token))
    (should-not called)))

(ert-deftest spot-test-refresh-synchronously/stores-token-and-expiry ()
  "A successful refresh stores the token and its expiry time."
  (let ((spot-access-token nil)
        (spot--token-expires-at nil)
        (spot-refresh-token "refresh"))
    (cl-letf (((symbol-function 'spot-request)
               (lambda (&rest _)
                 '((access_token . "new-token") (expires_in . 3600)))))
      (should (equal (spot-refresh-synchronously) "new-token")))
    (should (equal spot-access-token "new-token"))
    (should (> spot--token-expires-at (float-time)))))

(ert-deftest spot-test-refresh-synchronously/failure-returns-nil ()
  "A failed refresh returns nil and leaves the token untouched."
  (let ((spot-access-token "old")
        (spot--token-expires-at 42)
        (spot-refresh-token "refresh"))
    (cl-letf (((symbol-function 'spot-request)
               (lambda (&rest _) nil)))
      (should-not (spot-refresh-synchronously)))
    (should (equal spot-access-token "old"))
    (should (= spot--token-expires-at 42))))

(ert-deftest spot-test-refresh-synchronously/error-messages-and-returns-nil ()
  "A refresh whose request signals reports the error and returns nil."
  (let ((spot-access-token "old")
        (spot--token-expires-at 42)
        (spot-refresh-token "refresh")
        captured)
    (cl-letf (((symbol-function 'spot-request)
               (lambda (&rest _) (error "boom")))
              ((symbol-function 'message)
               (lambda (fmt &rest args)
                 (setq captured (apply #'format fmt args)))))
      (should-not (spot-refresh-synchronously)))
    (should (string-match-p "token refresh failed" captured))
    (should (string-match-p "boom" captured))
    (should (equal spot-access-token "old"))
    (should (= spot--token-expires-at 42))))

(ert-deftest spot-test-request/ensures-fresh-token-for-bearer-auth ()
  "Bearer requests ensure freshness; explicit-auth requests do not."
  (let ((ensure-calls 0))
    (cl-letf (((symbol-function 'spot--ensure-fresh-token)
               (lambda () (cl-incf ensure-calls)))
              ((symbol-function 'url-retrieve-synchronously)
               (lambda (&rest _)
                 (with-current-buffer
                     (generate-new-buffer " *spot-test-response*")
                   (spot-test--fake-response 200 "{}")
                   (current-buffer)))))
      (spot-request :method "GET" :url "https://example.invalid" :q-params "")
      (should (= ensure-calls 1))
      (spot-request :method "GET" :url "https://example.invalid" :q-params ""
                    :extra-headers '(("Authorization" . "Basic zzz")))
      (should (= ensure-calls 1)))))


;;; spot--report-response-error

(defmacro spot-test--with-captured-message (var &rest body)
  "Execute BODY with `message' stubbed; bind its formatted output to VAR."
  (declare (indent 1))
  `(let (,var)
     (cl-letf (((symbol-function 'message)
                (lambda (fmt &rest args)
                  (setq ,var (apply #'format fmt args)))))
       ,@body)))

(defun spot-test--fake-response (status body)
  "Populate current buffer to mimic a `url-retrieve' response buffer.
STATUS is the HTTP status integer, BODY is the response body
string.  Sets `url-http-end-of-headers' and
`url-http-response-status' buffer-locally, matching how url.el
stores them in real response buffers."
  (insert (format "HTTP/1.1 %d Status\nContent-Type: application/json\n\n"
                  status))
  (setq-local url-http-end-of-headers (1- (point)))
  (insert body)
  (setq-local url-http-response-status status))

(ert-deftest spot-test-report-response-error/4xx-messages-error ()
  "A non-2xx response with Spotify error shape is reported via `message'."
  (spot-test--with-captured-message captured
    (with-temp-buffer
      (spot-test--fake-response
       400 "{\"error\":{\"status\":400,\"message\":\"Invalid limit\"}}")
      (spot--report-response-error))
    (should (string-match-p "400" captured))
    (should (string-match-p "Invalid limit" captured))))

(ert-deftest spot-test-report-response-error/401-marks-token-stale ()
  "A 401 on a Bearer request zeroes the recorded expiry to force a refresh."
  (let ((spot--token-expires-at (+ (float-time) 3600)))
    (spot-test--with-captured-message captured
      (with-temp-buffer
        (spot-test--fake-response
         401 "{\"error\":{\"status\":401,\"message\":\"The access token expired\"}}")
        (spot--report-response-error t))
      (should (string-match-p "401" captured)))
    (should (= spot--token-expires-at 0))))

(ert-deftest spot-test-report-response-error/non-bearer-401-keeps-expiry ()
  "A 401 on a non-Bearer request leaves the recorded expiry alone."
  (let* ((expires-at (+ (float-time) 3600))
         (spot--token-expires-at expires-at))
    (spot-test--with-captured-message captured
      (with-temp-buffer
        (spot-test--fake-response
         401 "{\"error\":{\"status\":401,\"message\":\"Invalid client\"}}")
        (spot--report-response-error))
      (should (string-match-p "401" captured)))
    (should (= spot--token-expires-at expires-at))))

(ert-deftest spot-test-report-response-error/2xx-is-silent ()
  "A 2xx response does not emit any message."
  (spot-test--with-captured-message captured
    (with-temp-buffer
      (spot-test--fake-response 200 "")
      (spot--report-response-error))
    (should-not captured)))

(ert-deftest spot-test-report-response-error/non-json-body-falls-back ()
  "A non-JSON error body falls back to a generic \"request failed\" message."
  (spot-test--with-captured-message captured
    (with-temp-buffer
      (spot-test--fake-response 500 "<html>oops</html>")
      (spot--report-response-error))
    (should (string-match-p "500" captured))
    (should (string-match-p "request failed" captured))))

(provide 'spot-test)

;;; spot-test.el ends here
