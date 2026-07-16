# Changelog

All notable changes to PriceTicker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- Chinese-first project introduction with an English companion README.
- Community health files, issue forms, pull request template, and security policy.
- GitHub Actions workflows for continuous integration and tagged releases.
- Unit tests for price formatting, ticker positioning, and market endpoints.
- SHA-256 verification for the pinned XcodeGen bootstrap archive.

### Changed

- Replaced placeholder repository URLs with the public PriceTicker repository.
- Aligned the app version with semantic release tags.
- Required each automated Release to provide an explicit versioned notes file.

### Fixed

- Validated proxy inputs and made CFNetwork dictionary bridge types explicit.
- Isolated unit tests from persisted watchlists and user proxy settings.

## [1.0.0] - 2026-04-06

### Added

- Menu bar icon with live BTC 24-hour sparkline rendered as a custom NSImage.
- Network status dot on menu bar icon (green = online, red = offline/error).
- Popover UI for managing the watchlist (add/remove tickers).
- Draggable, always-on-top floating tag panels for each watched symbol, showing price and 24h percentage change.
- Real-time price updates via Binance REST API polled every 2 seconds per ticker.
- Top-5 gainers / top-5 losers leaderboard sourced from the Binance 24h ticker feed, displayed in a floating panel.
- Persistent watchlist and window positions across app restarts (UserDefaults).
- `NetworkSession` with optional HTTP/HTTPS proxy support (disabled by default).
- XcodeGen `project.yml` so the Xcode project can be fully regenerated from source.
- `scripts/bootstrap.sh` for one-command setup from a fresh clone.
- `docs/ARCHITECTURE.md` and `docs/DEVELOPMENT.md` developer documentation.

[Unreleased]: https://github.com/0x2a94b5/PriceTicker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/0x2a94b5/PriceTicker/releases/tag/v1.0.0
