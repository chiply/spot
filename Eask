; -*- lexical-binding: t -*-

(package "spot"
; x-release-please-start-version
         "0.1.0"
; x-release-please-end
         "Spotify client")

(website-url "https://github.com/chiply/spot")
(keywords "multimedia")

(package-file "spot.el")
(files "*.el")

(script "test" "eask test ert test/spot-test.el")

(source "gnu")
(source "melpa")

(depends-on "emacs" "29.1")
(depends-on "ht" "2.3")
(depends-on "dash" "2.19")
(depends-on "consult" "1.0")
(depends-on "marginalia" "1.0")
(depends-on "embark" "0.23")

(development
 (depends-on "package-lint")
 (depends-on "elisp-lint")
 (depends-on "relint"))
