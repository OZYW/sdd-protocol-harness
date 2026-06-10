# Dry Run 001 操作手册

## 目标

在一个新 Claude Code session 中验证 SDD Protocol Harness 是否能完整运行一个 loop：

```
/sdd-start build a function that reverses a string
-> E1 Capture -> E2 Generate Spec -> E2R Review -> E3 Human Gate
-> E4 Compile Tasks -> E5 Implement -> E6 Verify -> E7 Feedback
-> Loop Complete
```

---

## 前置条件

- 当前分支 `claude/sdd-harness-dev` 已包含完整 harness 文件
- 你有另一个 terminal 窗口或标签页可用
- 已安装 Claude Code CLI (`claude` 命令可用)

---

## Step 1: 准备测试目录

```bash
# 创建一个干净的测试目录
mkdir -p ~/sdd-test-project
cd ~/sdd-test-project

# 初始化 git（Claude Code 推荐）
git init

# 复制 harness 的项目级文件（注意：在当前 worktree 目录中）
cp -r /Users/wei/Documents/SDD_Protocol/.claude/worktrees/hungry-cerf-ae3e69/harness/.sdd ./
cp -r /Users/wei/Documents/SDD_Protocol/.claude/worktrees/hungry-cerf-ae3e69/harness/.claude ./

# 验证文件存在
ls -la .sdd/state/current_loop.yaml
ls -la .claude/SDD_PROTOCOL.md
```

**预期输出**：
```
.sdd/state/current_loop.yaml
.claude/SDD_PROTOCOL.md
```

---

## Step 2: 安装 Skill

```bash
# 创建 skill 目录（如果不存在）
mkdir -p ~/.claude/skills

# 复制 skill 文件（注意：在当前 worktree 目录中）
cp -r /Users/wei/Documents/SDD_Protocol/.claude/worktrees/hungry-cerf-ae3e69/harness/skill ~/.claude/skills/sdd-protocol

# 验证安装
ls ~/.claude/skills/sdd-protocol/SKILL.md
ls ~/.claude/skills/sdd-protocol/references/intake_agent.md
```

**预期输出**：
```
/Users/wei/.claude/skills/sdd-protocol/SKILL.md
/Users/wei/.claude/skills/sdd-protocol/references/intake_agent.md
```

---

## Step 3: 启动新 Session

```bash
# 在测试目录中启动 Claude Code
claude
```

**关键**：必须是**新 session**（不是当前对话的延续）。

---

## Step 4: 触发 SDD Loop

在新 session 中输入：

```
/sdd-start build a Python function that takes a string and returns its reverse
```

---

## Step 5: 观察预期行为（阶段检查清单）

### E1 Capture — Intake Agent

**Claude 应该**：
- 识别 `/sdd-start` 命令
- 读取 `.sdd/state/current_loop.yaml`
- 发现 `status: idle`，创建新 loop
- 调用 Agent 工具（Intake Agent）
- 生成 `idea_brief.yaml`

**你验证**：
```bash
# 在另一个 terminal 中检查
ls ~/sdd-test-project/.sdd/artifacts/loops/L001/idea_brief.yaml
```

**预期**：文件存在，内容包含你的原始需求

---

### E2 Generate Spec — Spec Agent

**Claude 应该**：
- 自动推进到 E2
- 调用 Agent 工具（Spec Agent）
- 读取 `idea_brief.yaml`
- 生成 `sdd_spec.yaml`

**你验证**：
```bash
ls ~/sdd-test-project/.sdd/artifacts/loops/L001/sdd_spec.yaml
```

**预期**：文件存在，包含：
- `product_intent`: 反转字符串的功能
- `goals`: 至少一个可验证的目标
- `functional_behavior`: B-001 等条目
- `acceptance_criteria`: A-001 等条目

---

### E2R Review — Spec Review Agent（F1 修正验证点）

**Claude 应该**：
- **这是独立的 Agent 调用**（关键验证点）
- 新 Agent 读取 `sdd_spec.yaml` 直接文件
- 输出 review result（pass / needs_revision）

**你验证**：
- 观察 Claude 是否调用了两次 Agent（一次 Spec，一次 Review）
- 如果 Review Agent 说 "我直接读了文件" → F1 修正生效
- 如果 Review Agent 说 "你刚才告诉了我 spec 的内容" → F1 未生效

---

### E3 Human Gate（关键验证点）

**Claude 应该**：
- **停止执行**
- 呈现对话式 Human Gate，不是文件列表
- 包含：Current state / What needs decision / What we built / Choices

**你应该看到类似**：
```
--- SDD Protocol — Human Gate HG-001 ---

Current state:
  I've captured your idea and turned it into a structured plan.

What needs your decision:
  Does this plan match what you had in mind?

What we built:
  - A Python function that takes a string and returns its reverse
  - The function handles edge cases (empty string, single character)
  - Includes basic tests to verify correctness

Recommended option:
  Approve — this is the smallest useful version.

Your choices:
  [Approve] [Revise — tell me what to change] [Reject]

(You do not need to review files. Just tell me if this matches what you want.)
```

**你验证**：
- Claude **没有**让你看 `sdd_spec.yaml` 文件
- 格式是对话式的
- 有明确的 [Approve] [Revise] [Reject] 选项

---

### E4 Compile Tasks — Task Compiler Agent

**你说**：`Approve`

**Claude 应该**：
- 记录 `approved` 到 `human_gate.yaml`
- 推进到 E4
- 调用 Task Compiler Agent
- 生成 `task_plan.yaml`

**你验证**：
```bash
ls ~/sdd-test-project/.sdd/artifacts/loops/L001/task_plan.yaml
ls ~/sdd-test-project/.sdd/artifacts/loops/L001/human_gate.yaml
```

---

### E5 Implement — Implementation Agent

**Claude 应该**：
- 读取 `task_plan.yaml`
- 按任务逐个实现
- 写代码到项目目录

**你验证**：
```bash
ls ~/sdd-test-project/*.py  # 应该有 Python 文件生成
```

---

### E6 Verify — Verification Agent

**Claude 应该**：
- 运行测试或验证代码
- 收集证据
- 生成 `evidence_pack.yaml`

**你验证**：
```bash
ls ~/sdd-test-project/.sdd/artifacts/loops/L001/evidence_pack.yaml
```

---

### E7 Feedback — 用户接受

**Claude 应该**：
- 呈现证据摘要
- 问你：是否接受这个结果？

**你说**：`Yes, looks good`

**Claude 应该**：
- 记录反馈
- 设置 `status: completed`
- Loop 结束

**你验证**：
```bash
cat ~/sdd-test-project/.sdd/state/current_loop.yaml
```

**预期**：
```yaml
loop_id: "L001"
status: completed
current_phase: null
```

---

## 诊断：如果行为不符合预期

### 问题 1: Claude 不识别 `/sdd-start`

**症状**：Claude 说 "I don't know what /sdd-start means"

**检查**：
```bash
# Skill 是否安装正确？
ls ~/.claude/skills/sdd-protocol/SKILL.md

# 文件内容是否可读？
cat ~/.claude/skills/sdd-protocol/SKILL.md | head -10
```

**解决**：
- 确认 skill 复制到了正确的 `~/.claude/skills/` 目录
- 重启 Claude Code session

---

### 问题 2: Claude 没有读取 `current_loop.yaml`

**症状**：Claude 直接开始写代码，没有生成 `idea_brief.yaml`

**检查**：
```bash
# 项目级文件是否存在？
ls ~/sdd-test-project/.sdd/state/current_loop.yaml
ls ~/sdd-test-project/.claude/SDD_PROTOCOL.md
```

**可能原因**：
- Claude Code 没有自动读取 `CLAUDE.md` 或 `.claude/SDD_PROTOCOL.md`
- 需要在新 session 中手动让 Claude 读取这些文件

**解决**：
```
Please read .claude/SDD_PROTOCOL.md and follow the SDD Protocol rules in this project.
```

---

### 问题 3: Human Gate 让你审查文件

**症状**：Claude 说 "Please review sdd_spec.yaml and let me know..."

**检查**：
- 对比 `human_gate_format.md` 的 "Bad (File Review)" 示例

**解决**：
- 这是协议漂移。告诉 Claude：
  ```
  Stop. According to SDD Protocol Rule 3, the Human Gate must be conversational. Do not ask me to review files. Summarize the spec in plain language and ask me to confirm intent.
  ```

---

### 问题 4: Spec Review 不是独立 Agent 调用

**症状**：Spec Agent 生成 spec 后，同一个上下文直接说 "Now I'll review it..."

**检查**：
- 观察是否有两次独立的 `Agent` 工具调用

**解决**：
- 这是 F1 修正未生效。告诉 Claude：
  ```
  According to Rule 9, Spec Review Agent must be an independent Agent tool call. Please call Agent tool with the Spec Review Agent role in a fresh context.
  ```

---

## 结果记录

Dry Run 完成后，请记录：

1. **Loop 是否完整走完 E1-E7？**
2. **Human Gate 是否对话式？**
3. **Spec Review 是否独立 Agent 调用？**
4. **是否有任何阶段被跳过？**
5. **遇到什么问题？**

把结果告诉我，我会更新 Evidence Pack 和 Protocol Fitness Audit。
