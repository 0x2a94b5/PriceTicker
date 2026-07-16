# 参与贡献 / Contributing

感谢你愿意改进 PriceTicker。本文以中文说明贡献流程，英文贡献者可参考每节的 English summary，或在 Issue 中使用英文交流。

## 开始之前

- 使用 [Issues](https://github.com/0x2a94b5/PriceTicker/issues) 搜索是否已有相同问题。
- Bug 请提供 macOS、Xcode 或应用版本、复现步骤、预期行为和实际行为。
- 较大的功能或架构调整请先创建 Feature Request，确认方向后再编码。
- 安全漏洞不要提交公开 Issue，请按 [SECURITY.md](SECURITY.md) 私下报告。

_English: Search existing issues first. Discuss large changes before implementation, and report vulnerabilities privately._

## 本地开发

环境要求：macOS 12+、Xcode 14+。首次构建运行：

```bash
git clone https://github.com/0x2a94b5/PriceTicker.git
cd PriceTicker
./scripts/bootstrap.sh
```

运行完整校验：

```bash
xcodebuild \
  -project PriceTicker.xcodeproj \
  -scheme PriceTicker \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## 提交流程

1. Fork 仓库并从最新 `main` 创建分支，例如 `feature/add-alert` 或 `fix/proxy-validation`。
2. 保持改动聚焦，不要把格式化、重构和功能修改混在同一个 PR。
3. 新增或修复可测试逻辑时同步补充测试。
4. 如果修改 `project.yml`，必须重新生成并一并提交 `PriceTicker.xcodeproj`。
5. 在本地通过构建和测试后再提交 Pull Request。
6. 填写 PR 模板，说明影响范围、验证方式、风险和回滚方案。

提交信息应简短明确，可以使用中文或英文，例如：

```text
修复代理端口校验

- 拒绝超出有效范围的端口
- 补充代理配置单元测试
```

_English: Fork the repository, branch from `main`, keep changes focused, add tests, and complete the pull request template._

## 代码约定

- 遵循现有 Swift 和 SwiftUI 风格，优先保持类型职责单一。
- UI 状态更新必须回到主线程。
- 网络请求统一通过 `NetworkSession.shared`，并处理 HTTP 状态码和失败退避。
- 不提交 API Key、代理凭据、个人配置、构建目录或发布产物。
- 避免无理由引入第三方依赖；确有需要时在 PR 中说明许可、体积和维护风险。
- 用户可见行为变化需要同步更新 README 或 CHANGELOG。

## Pull Request 检查清单

- [ ] 改动与 Issue 或 PR 描述一致
- [ ] 已完成本地构建和相关测试
- [ ] 未包含敏感信息及无关文件
- [ ] 已更新必要的文档和 CHANGELOG
- [ ] 已说明兼容性、风险和回滚方式

提交贡献即表示你同意按本项目 [MIT License](LICENSE) 授权你的贡献，并遵守 [行为准则](CODE_OF_CONDUCT.md)。
