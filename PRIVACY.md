# 隐私说明 / Privacy

更新日期：2026-07-16

PriceTicker 是本地运行的开源 macOS 应用，不提供用户账户，不集成广告或分析 SDK，也不收集遥测数据。

## 本地保存的数据

以下数据通过 macOS `UserDefaults` 保存在本机：

- 自选交易对
- 悬浮窗口位置
- HTTP 代理开关、主机和端口

卸载应用未必会自动删除这些偏好设置。用户可自行清理应用偏好数据。

## 网络请求

应用会向 Binance 公共 REST API 请求交易对价格、24 小时涨跌幅和 K 线数据。请求不需要 Binance API Key。启用自定义 HTTP 代理后，相关请求会经过用户指定的代理服务器；代理运营方可能按其自身政策处理网络元数据。

本项目不控制 Binance 或代理服务的隐私实践。使用前请查看相应第三方政策。

## English summary

PriceTicker has no accounts, ads, analytics SDKs, or telemetry. Watchlists, floating-window positions, and proxy settings are stored locally in macOS `UserDefaults`. The app requests public market data from Binance. When a custom HTTP proxy is enabled, requests pass through the user-selected proxy and may be subject to that provider's privacy policy.
