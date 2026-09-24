---
description: "Claude Code 設定（skills / commands / agents / hooks / rules）の棚卸し。使用実績と有効性を調べて削除・統合候補を提案する。四半期〜半年に1回"
argument-hint: "[--days <N>]  既定 180"
allowed-tools: ["Read", "Glob", "Grep", "Bash(ls:*)", "Bash(find:*)", "Bash(grep:*)", "Bash(jq:*)", "Bash(wc:*)", "Bash(claude --version)", "Bash(git log:*)"]
---

# /config-audit - Claude Code 設定の棚卸し

使わない設定が残り続けるとコンテキストを圧迫し、本体の更新で非推奨になったものが動かないまま残る。
手許の作業ログをもとに分析し、削除・統合・更新の候補を提案する。**このコマンド自身は何も削除しない**。

## 対象

グローバル設定の正は、この dotfiles リポジトリ内の `.claude/`（`~/.claude/` の管理対象ファイルから symlink）。

| 種別 | 場所 |
|------|------|
| skills | `~/.claude/skills/*/SKILL.md` |
| commands | `~/.claude/commands/*.md` |
| agents | `~/.claude/agents/**/*.md` |
| hooks | `~/.claude/hooks/*` と `~/.claude/settings.json` の `hooks` |
| rules | `~/.claude/rules/**/*.md` |
| CLAUDE.md | `~/.claude/CLAUDE.md` |

## 手順

1. **利用実績を集める**（既定 180 日、`--days` で変更）
   - `~/.claude/history.jsonl` から `/コマンド名` の出現回数を数える
   - `~/.claude/projects/*/` のセッションログから `Skill(...)` と `subagent_type` の出現回数を数える
   - 出現ゼロのものを「未使用候補」として列挙する
2. **壊れているものを探す**
   - `settings.json` の `hooks[].command` が指すファイルが存在し実行権限があるか
   - `hooks` が参照するコマンド（bun / jq 等）が PATH にあるか
   - commands / agents の frontmatter が現在の Claude Code の書式（`claude --version` を確認）に合っているか
   - `.skill` の zip 残骸や `*.bak` など、参照されないファイル
3. **重複・冗長を探す**
   - ビルトイン機能（`/code-review`、`/simplify`、memory 等）で置き換えられる自作 command / agent
   - 内容が重なる skill 同士、rule と CLAUDE.md の重複記述
   - CLAUDE.md の中で「今のプロジェクトでは一度も効いていない」章
4. **レポートを出す**

## レポートの形式

```markdown
## 設定棚卸しレポート（<日付>、直近 <N> 日）

### 削除候補（未使用 + 代替あり）
| 種別 | 名前 | 最終利用 | 代替 |

### 修正候補（壊れている / 非推奨）
| 種別 | 名前 | 問題 | 対処 |

### 統合候補（重複）
| 対象 A | 対象 B | 提案 |

### 現状維持（使用実績あり）
- ...
```

## 注意

- プロジェクト専用 skill をグローバルに混ぜない（逆も同じ）。所属が違うものは移動候補として挙げる
- ユーザー判断で「触らない」と決めたもの（memory に記録あり）は候補から外す
- レポート提示後、ユーザーが選んだ項目だけ削除・修正する
