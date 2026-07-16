# PriceTicker

<p align="center">
  <img src="PriceTicker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="128" alt="PriceTicker 图标">
</p>

<p align="center">
  一款轻量、原生的 macOS 菜单栏加密货币行情工具。<br>
  用可拖动悬浮标签关注价格，在菜单栏快速查看 BTC 走势。
</p>

<p align="center">
  <a href="README_EN.md">English</a> ·
  <a href="https://github.com/0x2a94b5/PriceTicker/releases">下载</a> ·
  <a href="CONTRIBUTING.md">参与贡献</a>
</p>

<p align="center">
  <a href="https://github.com/0x2a94b5/PriceTicker/actions/workflows/ci.yml"><img src="https://github.com/0x2a94b5/PriceTicker/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/0x2a94b5/PriceTicker/releases"><img src="https://img.shields.io/github/v/release/0x2a94b5/PriceTicker?display_name=tag" alt="Release"></a>
  <img src="https://img.shields.io/badge/macOS-12%2B-blue" alt="macOS 12+">
  <img src="https://img.shields.io/badge/Swift-5.7-orange" alt="Swift 5.7">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/0x2a94b5/PriceTicker" alt="MIT License"></a>
</p>

## 功能

- **菜单栏 BTC 走势图**：展示 BTC/USDT 近 24 小时走势，每 5 分钟更新。
- **悬浮价格标签**：支持 Binance 现货和 U 本位永续合约交易对，标签可拖动并始终置顶。
- **涨跌幅榜单**：展示合约市场涨幅和跌幅前 5 名，可切换独立悬浮面板。
- **自适应行情轮询**：正常情况下每 5 秒更新自选行情，网络异常时自动退避。
- **网络状态提示**：菜单栏状态点区分在线、离线和等待状态。
- **HTTP 代理**：可在设置中配置代理，无需重新编译。
- **本地持久化**：自选列表、悬浮窗位置和代理设置均保存在本机。
- **零第三方运行时依赖**：使用 Swift、SwiftUI、AppKit 和 Combine 构建。

## 系统要求

- macOS 12 Monterey 或更高版本
- 从源码构建需要 Xcode 14 或更高版本

## 安装

### 下载 Release

1. 前往 [Releases](https://github.com/0x2a94b5/PriceTicker/releases) 下载最新的 `PriceTicker.app.zip`。
2. 解压后将 `PriceTicker.app` 拖入“应用程序”目录。
3. 启动应用，菜单栏将显示行情图标。

当前公开构建尚未进行 Apple 公证。首次启动时可能需要在 Finder 中右键应用并选择“打开”。请只从本仓库 Release 下载，并核对随 Release 提供的 SHA-256 文件。

### 从源码构建

```bash
git clone https://github.com/0x2a94b5/PriceTicker.git
cd PriceTicker
./scripts/bootstrap.sh
```

脚本会校验并准备固定版本的 XcodeGen、重新生成 Xcode 工程，然后执行 Debug 构建。产物位于 `build/Debug/PriceTicker.app`。

也可以直接打开已提交的工程：

```bash
open PriceTicker.xcodeproj
```

## 使用方法

1. 点击菜单栏走势图标打开主面板。
2. “Top 5”默认展示合约市场涨幅榜和跌幅榜。
3. 切换到自选列表，输入如 `BTCUSDT`、`ETHUSDT` 的交易对并添加。
4. 拖动悬浮价格标签调整位置，应用会自动保存。
5. 点击独立榜单悬浮窗可切换涨幅榜和跌幅榜。
6. 点击底部齿轮按钮配置 HTTP 代理。

## 数据与隐私

PriceTicker 直接请求 Binance 公共 REST API，不需要 API Key，不上传自选列表，也不收集遥测数据。自选列表、窗口位置和代理配置保存在本机 `UserDefaults` 中。详见 [隐私说明](PRIVACY.md)。

> [!IMPORTANT]
> PriceTicker 仅用于行情展示，不构成投资建议。项目与 Binance 无隶属、授权或背书关系。第三方 API 的可用性、限流规则和数据准确性由其服务提供方负责。

## 项目结构

```text
App        应用生命周期、菜单栏和弹窗
Windows    AppKit 悬浮面板及控制器
Services   行情请求、轮询退避和网络状态
Models     自选交易对、价格及代理配置
Views      SwiftUI 界面
```

设计说明见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)，开发指南见 [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)。

## 参与贡献

欢迎提交 Issue 和 Pull Request。开始前请阅读：

- [贡献指南](CONTRIBUTING.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [安全策略](SECURITY.md)
- [支持说明](SUPPORT.md)

维护者发布前还应核对 [GitHub 开源发布清单](docs/GITHUB_OPEN_SOURCE_CHECKLIST.md)。

## 路线图

- 增加更多核心逻辑测试
- 优化无障碍与本地化体验
- 完善签名、公证和可复现发布流程

具体计划和建议请通过 [Issues](https://github.com/0x2a94b5/PriceTicker/issues) 讨论。

## 开源许可

PriceTicker 使用 [MIT License](LICENSE) 开源。
