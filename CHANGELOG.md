# Changelog

## [0.1.6](https://github.com/chiply/spot/compare/v0.1.5...v0.1.6) (2026-08-07)


### Bug Fixes

* refresh access token on demand to prevent 401s at startup and after sleep ([#10](https://github.com/chiply/spot/issues/10)) ([b867df1](https://github.com/chiply/spot/commit/b867df160483bead1f516190618f4b1a1aac5172))

## [0.1.5](https://github.com/chiply/spot/compare/v0.1.4...v0.1.5) (2026-04-24)


### Bug Fixes

* escape and url-encode embark field values; respect user --type= ([#7](https://github.com/chiply/spot/issues/7)) ([b53ab9c](https://github.com/chiply/spot/commit/b53ab9c4160dc29e87c75b395fd36bf38f4a90cf))

## [0.1.4](https://github.com/chiply/spot/compare/v0.1.3...v0.1.4) (2026-04-21)


### Features

* auto-refresh access token when spot-mode is enabled ([1f88808](https://github.com/chiply/spot/commit/1f88808277a41cc5c44b451dd8c87381ea4a0792))
* **marginalia:** prefix ambiguous numeric fields with symbols ([a508ee9](https://github.com/chiply/spot/commit/a508ee947c9c3692827de1ac8cc9cda2ced5b383))
* **marginalia:** use marginalia--fields for aligned, coloured annotations ([27b86c7](https://github.com/chiply/spot/commit/27b86c7be89057976b4bb5205f41998c4d2c319e))


### Bug Fixes

* surface Spotify API errors instead of silently returning nothing ([ef074fd](https://github.com/chiply/spot/commit/ef074fd3c4b6f30395c8e16f11f30de0f4bd6e98))
* truncate very wide candidates so annotations don't render off-screen ([2e947f8](https://github.com/chiply/spot/commit/2e947f82dee37e5139ea4949fe9f2932e834afc5))

## [0.1.3](https://github.com/chiply/spot/compare/v0.1.2...v0.1.3) (2026-02-24)


### Bug Fixes

* revert to block-style release-please version markers ([d6bdf03](https://github.com/chiply/spot/commit/d6bdf03a3a1206a3eb968c84a0b0d69069f9a88e))

## [0.1.2](https://github.com/chiply/spot/compare/v0.1.1...v0.1.2) (2026-02-23)


### Bug Fixes

* eliminate double API call, nil-safe annotations, error handling ([de6361a](https://github.com/chiply/spot/commit/de6361a9f2967be0233c4796c0fea415dc8ba28b))
* guard modeline updates against nil item in API response ([5e79f8d](https://github.com/chiply/spot/commit/5e79f8d564bf224363a6594e9fdb1249c97e45be))
* use Bearer auth header, fix mapconcat args, fix playlist URL ([dacb1b6](https://github.com/chiply/spot/commit/dacb1b608c2323655b0a1c062c52ff81cc5e2893))

## [0.1.1](https://github.com/chiply/spot/compare/v0.1.0...v0.1.1) (2026-02-23)


### Features

* add spot-mode, README, and MELPA readiness fixes ([730e7c0](https://github.com/chiply/spot/commit/730e7c0b8b933c9c5c446cfb89f86c3346b1b4d7))
* initial release of spot ([963b535](https://github.com/chiply/spot/commit/963b53512811de0d2f5b7ad4360669f0d5c984bf))

## Changelog
