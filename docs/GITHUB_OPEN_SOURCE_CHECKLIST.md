# GitHub 开源发布清单

本文记录无法仅通过仓库文件完成的 GitHub 设置。仓库维护者应在首次正式 Release 前逐项核对。

## 仓库基础设置

- [x] 仓库可见性为 Public。
- [x] 默认分支为 `main`。
- [x] 已配置项目描述和 `macos`、`swift`、`swiftui`、`cryptocurrency` 等 Topics。
- [ ] 上传一张不含个人行情或代理信息的 Social preview 图片。
- [ ] 确认 Issues 已启用；是否启用 Discussions 根据社区规模决定。

## `main` 分支规则

建议在 **Settings → Rules → Rulesets** 为 `main` 创建规则：

- [ ] 禁止删除和强制推送。
- [ ] 合并前必须通过 Pull Request。
- [ ] 必须通过 `Build and test` 状态检查。
- [ ] 必须解决所有 Review conversations。
- [ ] 管理员是否允许绕过规则需明确记录。

个人维护阶段可暂不强制“一名批准者”，避免维护者自己的 PR 无法合并；增加协作者后应启用至少一次 Review。

## 安全设置

在 **Settings → Security → Advanced Security** 核对：

- [ ] Dependabot alerts。
- [ ] Secret scanning。
- [ ] Push protection。
- [ ] Code scanning（若 GitHub 对当前 Swift/macOS 项目提供适用方案）。
- [ ] Private vulnerability reporting，确保 `SECURITY.md` 中的私下报告链接可用。

Actions 的默认 `GITHUB_TOKEN` 权限建议保持只读。仅 Release workflow 在文件中显式申请 `contents: write`。

## 首次发布

1. 合并并推送本次开源准备改动，等待 CI 通过。
2. 确认 `PriceTicker/Info.plist` 的版本与准备创建的标签一致。
3. 创建并推送语义化版本标签，例如：

   ```bash
   git tag -a v1.0.0 -m "PriceTicker v1.0.0"
   git push origin v1.0.0
   ```

4. Release workflow 会构建通用架构应用，上传 `PriceTicker.app.zip` 和 SHA-256 校验文件，并生成 Release notes。
5. 下载 Release 资产，在一台未安装开发证书的 Mac 上完成冒烟测试。

## 签名与公证

当前自动发布的是未签名、未公证构建，README 已明确披露。准备提供更低摩擦的安装体验时，应使用专用 Developer ID Application 证书和 App Store Connect API Key，通过 GitHub Environments 管理发布权限，并为工作流增加签名、公证和 stapling。不得把证书或凭据提交到仓库。

## English summary

Before the first release, configure a `main` ruleset, require CI, block force pushes and deletions, enable the applicable GitHub security features, and verify private vulnerability reporting. The current release workflow intentionally produces an unsigned and unnotarized universal app; signing credentials must be stored outside the repository and protected with a GitHub Environment.
