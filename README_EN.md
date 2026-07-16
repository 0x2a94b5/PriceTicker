# PriceTicker

[简体中文](README.md)

PriceTicker is a lightweight native macOS menu bar app for monitoring cryptocurrency prices through draggable floating tags. It uses Binance public REST APIs and requires no API key.

## Highlights

- A 24-hour BTC/USDT sparkline in the menu bar
- Draggable, always-on-top price tags for Binance Spot and USD-M Futures symbols
- Top-five futures gainers and losers
- Five-second watchlist polling with adaptive backoff
- Runtime HTTP proxy configuration
- Local persistence for watchlists, window positions, and settings
- Pure Swift, SwiftUI, AppKit, and Combine with no third-party runtime dependencies

## Requirements

- macOS 12 Monterey or later
- Xcode 14 or later when building from source

## Install

Download `PriceTicker.app.zip` from [GitHub Releases](https://github.com/0x2a94b5/PriceTicker/releases), unzip it, and move the app to `/Applications`.

Public builds are not currently notarized by Apple. On first launch, you may need to right-click the app in Finder and choose **Open**. Only download release assets from this repository and verify the provided SHA-256 checksum.

To build from source:

```bash
git clone https://github.com/0x2a94b5/PriceTicker.git
cd PriceTicker
./scripts/bootstrap.sh
```

## Privacy and disclaimer

PriceTicker does not require API credentials, collect telemetry, or upload your watchlist. Local preferences are stored in `UserDefaults`. See [PRIVACY.md](PRIVACY.md) for details.

PriceTicker is provided for informational purposes only and is not financial advice. This project is not affiliated with, authorized by, or endorsed by Binance.

## Contributing

Issues and pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md) before contributing.

## License

Licensed under the [MIT License](LICENSE).
