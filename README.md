# spot

[![CI](https://github.com/chiply/spot/actions/workflows/ci.yml/badge.svg)](https://github.com/chiply/spot/actions/workflows/ci.yml)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A Spotify client for Emacs built on [consult](https://github.com/minad/consult), [embark](https://github.com/oantolin/embark), and [marginalia](https://github.com/minad/marginalia).

spot integrates Spotify into the standard Emacs completion ecosystem. Search results appear as consult multi-sources with marginalia annotations and embark actions — the same workflow you use for buffers, files, and grep.

## Features

- **Multi-source search** — Search albums, artists, tracks, playlists, shows, episodes, and audiobooks simultaneously with narrowing keys
- **Embark actions** — Play, inspect data, list album/artist tracks, add tracks to playlists
- **Marginalia annotations** — See artist, duration, release date, popularity, and other metadata inline
- **Player controls** — Play, pause, next, previous via Spotify Connect (works with any device)
- **Mode-line** — Currently playing track displayed in the mode-line
- **Playlist management** — Browse your playlists and add tracks to them

## Installation

### With elpaca (use-package)

```elisp
(use-package spot
  :ensure (:host github :repo "chiply/spot")
  :config
  (spot-mode 1))
```

### With straight.el (use-package)

```elisp
(use-package spot
  :straight (:host github :repo "chiply/spot")
  :config
  (spot-mode 1))
```

### Manual

Clone the repository and add it to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/spot")
(require 'spot)
(spot-mode 1)
```

## Configuration

### Spotify credentials

Register a Spotify application at <https://developer.spotify.com/dashboard> and set your credentials:

```elisp
(setq spot-client-id "your-client-id"
      spot-client-secret "your-client-secret")
```

Set the redirect URI in your Spotify application to `https://spotify.com`.

### Enable spot

`spot-mode` is a global minor mode that registers embark keymaps, marginalia annotators, and starts the mode-line update timer:

```elisp
(spot-mode 1)
```

### Mode-line

Add the spot lighter to your mode-line:

```elisp
(setq-default mode-line-format
              (append mode-line-format '((:eval (spot-mode-line-string)))))
```

The mode-line face can be customized:

```elisp
(set-face-attribute 'spot-mode-line nil :foreground "#1db954")
```

## Usage

### Authorize

Run `M-x spot-authorize`. This opens the Spotify authorization page in your browser. After granting access, copy the code from the redirect URL and paste it into the minibuffer prompt.

To refresh an expired token: `M-x spot-refresh`.

### Search

`M-x spot-consult-search` opens a multi-source search. Type to search, then use narrowing keys to filter by type:

| Key | Source |
|-----|--------|
| `a` | Albums |
| `A` | Artists |
| `p` | Playlists |
| `t` | Tracks |
| `s` | Shows |
| `e` | Episodes |
| `b` | Audiobooks |

### Embark actions

Press `embark-act` (default `C-.`) on any search result:

| Key | Action |
|-----|--------|
| `P` | Play item |
| `s` | Show raw data |
| `t` | List tracks (on albums, artists, playlists) |
| `+` | Add track to playlist (on tracks) |

### Player controls

- `M-x spot-player-play`
- `M-x spot-player-pause`
- `M-x spot-player-next`
- `M-x spot-player-previous`

### Playlists

- `M-x spot-consult-search-current-user-playlists` — browse your playlists
- `M-x spot-consult-search-playlist-tracks` — browse tracks in a playlist
- `M-x spot-add-current-track-to-playlist` — add the currently playing track to a playlist

## Comparison with alternatives

| | spot | [consult-spotify](https://codeberg.org/jao/espotify) | [smudge](https://github.com/danielfm/smudge) |
|---|---|---|---|
| Completion framework | consult multi-source | consult (single-source per type) | tabulated-list buffers |
| Embark actions | Yes | Yes | No |
| Marginalia annotations | Yes (7 content types) | Yes | No |
| Playback method | Spotify Connect API | D-Bus (Linux only) | AppleScript / D-Bus / Connect |
| Mode-line | Yes | No | Yes |
| Playlist management | Yes | No | Yes |
| Search scope | All 7 Spotify types | 4 types (album, artist, track, playlist) | Track and playlist |
| Minimum Emacs | 29.1 | 26.1 | 27.1 |

**spot** focuses on deep integration with the consult/embark/marginalia ecosystem. It provides a unified multi-source search where all content types are searched simultaneously (rather than separate commands per type), with rich embark actions and marginalia annotations for every result. Playback uses the Spotify Connect API, so it works across platforms and controls any active device.

## Dependencies

- Emacs 29.1+
- [consult](https://github.com/minad/consult) 1.0+
- [embark](https://github.com/oantolin/embark) 0.23+
- [marginalia](https://github.com/minad/marginalia) 1.0+
- [ht](https://github.com/Wilfred/ht.el) 2.3+
- [dash](https://github.com/magnars/dash.el) 2.19+

## Note on consult internals

spot uses `consult--multi` and `consult--dynamic-collection` to build its multi-source async search. These are the established extension points for consult-based packages and are used by many packages in the consult ecosystem (consult-dir, consult-gh, consult-flycheck, etc.). The minimum consult version is pinned to 1.0 to ensure API stability.

## License

GPL-3.0-or-later
