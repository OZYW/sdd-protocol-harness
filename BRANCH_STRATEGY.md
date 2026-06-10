# Branch Strategy: Claude Code Harness

## Current State

```
main                           claude/sdd-harness-dev
de84c82                        27f6c0a
(original protocol docs)       (Claude Code harness + Dry Run 001 + fixes)
        \                            /
         \______ independent _______/
```

- `main`: SDD Protocol 泛化文档（specs, templates, experiments/000-self-bootstrap）
- `claude/sdd-harness-dev`: Claude Code 专用 harness 实现（harness/ directory）

## Why Not Merge?

| 维度 | main | claude/sdd-harness-dev |
|------|------|----------------------|
| **目标** | 协议设计文档 | 协议工具实现 |
| **受众** | 协议研究者、多平台适配者 | Claude Code 用户 |
| **产物** | Markdown specs, templates | Skill files, YAML schemas, role prompts |
| **验证方式** | 文档审查、逻辑推演 | 端到端 Dry Run |
| **生命周期** | 长期稳定 | 快速迭代 |

两个分支是**同一协议的不同表现形式**，不是主从关系。

## Git 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 分支被意外删除 | 低 | 高 | 已推送到远程（如果有 remote）或本地有 reflog |
| main 更新导致 divergence | 中 | 低 | 可用 `git cherry-pick` 单向同步 |
| 其他开发者困惑 | 中 | 中 | 本文档说明策略 |
| 长期维护负担 | 中 | 中 | 协议稳定后可考虑提取为独立 repo |

**结论**：不合并是安全的，且是正确的设计决策。

## Future Paths

### 路径 A：协议稳定后独立仓库（推荐）

当 harness 验证成熟后：
```
# 提取 harness/ 为独立仓库
# 原 repo 的 main 继续维护泛化协议
# 新 repo（如 sdd-protocol-claude）维护 harness + skill
```

### 路径 B：main 添加引用

```
# 在 main 的 README 中添加：
"Claude Code 实现见分支 claude/sdd-harness-dev"
# 不合并代码，只合并引用
```

### 路径 C：未来合并

当 harness 证明可跨平台复用时，提取平台无关部分回 main。
