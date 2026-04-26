# セットアップレシピ・コンフリクト回避

## 推奨組み合わせ別セットアップ手順

### レシピ 1: ミニマル（個人・中小リポ）

**目的**: 副作用最小で 30–50% トークン削減を狙う。

```bash
# 1. RTK 導入
brew install rtk-ai/tap/rtk   # or: cargo install rtk-cli
rtk init -g                   # グローバルフックを設定

# 2. 効果確認
# Claude Code セッションで `/cost` を比較
```

**コンフリクト**: なし（透過プロキシ）。
**ロールバック**: `rtk uninstall` だけで完全撤去。

---

### レシピ 2: モノレポ向け（個人・OSS）

**目的**: 大規模コードベースで Claude が無関係ファイルを読まないようにする。

```bash
# 1. RTK（前提として）
rtk init -g

# 2. Code Review Graph を MCP として追加
pip install code-review-graph
code-review-graph install   # MCP 設定を自動注入

# 3. 効果確認
# 同じレビュータスクを before/after で実行し、
# 読み込まれたファイル数とトークン数を比較
```

**コンフリクト**: Token Savior、Claude Context との **同時運用は非推奨**（同じレイヤーで競合）。

---

### レシピ 3: チーム・本番運用

**目的**: チームで共有するセマンティック検索を提供しつつ、CLI ノイズも抑える。

```bash
# 1. RTK（個人マシンに）
rtk init -g

# 2. Claude Context（チームで共有）
# Zilliz Cloud アカウント or 自前 Milvus を準備
npm install -g @zilliz/claude-context-mcp
# .mcp.json でプロジェクトに登録（チーム共有可）
```

**コンフリクト**:
- Code Review Graph・Token Savior と二重運用しない
- 埋め込み API（OpenAI 等）コストが発生するため `/cost` で監視

---

### レシピ 4: 長時間セッション・compaction 対策

**目的**: 1日中続くタスクで context 圧縮による文脈消失を防ぐ。

```bash
# 1. RTK
rtk init -g

# 2. Context Mode
git clone https://github.com/mksglu/context-mode.git
cd context-mode && npm install && npm test
# プラグイン登録（README 手順）

# 3. .gitignore に SQLite を追加
echo ".context-mode.sqlite" >> .gitignore
```

**コンフリクト**: なし。RTK と直交。

---

### レシピ 5: 新規プロジェクト初期化チェックリスト

**目的**: nadimtuhin の手法を参考に、最初から低トークンな構造を作る。

```
.claude/
├── QUICK_START.md           # 開発コマンド集（~100 tokens）
│   - 起動: pnpm dev
│   - テスト: pnpm test
│   - ビルド: pnpm build
├── ARCHITECTURE_MAP.md      # 構造マップ（~150 tokens）
│   - controllers: src/api/
│   - models: src/db/
│   - フロー: route → controller → service → repository
└── COMMON_MISTAKES.md       # 1時間以上溶かしたバグのみ（~350 tokens）
    - 「環境変数 X を設定し忘れると Y になる」など
CLAUDE.md                    # テスト方針・型・デプロイ規約（~450 tokens）
```

**ルール**:
- `COMMON_MISTAKES.md` には **1時間以上溶かした** バグだけ書く（軽微なものを書くと bloat）
- 各ファイルは **トークン数を計測** して上限を意識する（tiktoken 等）
- 既存リポジトリへの後付けは差分ベースで（既存 CLAUDE.md と統合）

---

## コンフリクトマトリクス

| ↓ A と →B を併用 | RTK | Claude Context | Code Review Graph | Token Savior | Context Mode | Token Optimizer MCP | nadimtuhin |
|---|---|---|---|---|---|---|---|
| RTK | – | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Claude Context | ✅ | – | ❌ | ❌ | ✅ | ✅ | ✅ |
| Code Review Graph | ✅ | ❌ | – | ❌ | ✅ | ✅ | ✅ |
| Token Savior | ✅ | ❌ | ❌ | – | ✅ | ✅ | ✅ |
| Context Mode | ✅ | ✅ | ✅ | ✅ | – | ⚠️ | ✅ |
| Token Optimizer MCP | ✅ | ✅ | ✅ | ✅ | ⚠️ | – | ✅ |
| nadimtuhin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | – |

凡例:
- ✅ 併用可
- ❌ 同レイヤーで競合、効果が打ち消し合うか冗長
- ⚠️ 動作はするが SQLite キャッシュが二重になる、要検討

---

## 既存 CLAUDE.md との統合判断

| ツール | 既存 CLAUDE.md と重複 | 推奨アクション |
|--------|----------------------|-----------------|
| Caveman | あり（"Tone and style"） | **入れない**。CLAUDE.md ルールで十分 |
| Claude Token Efficient | あり（簡潔ルール） | **入れない**。profile を CLAUDE.md にマージするなら可 |
| nadimtuhin | あり（CLAUDE.md / 構造化） | **手法のみ参考**。新規リポでは適用、既存リポは差分のみ |
| その他（外部ツール系） | なし | 直交するので併用判断は機能性で行う |

---

## 撤去・ロールバック手順

すべてのツールについて、撤去手順を導入時にメモしておく。最低限：

1. **設定の場所** （`.mcp.json`、`.claude/settings.json`、グローバル設定）
2. **キャッシュ・DB の場所** （SQLite ファイルの位置）
3. **アンインストールコマンド**
4. **元の挙動に戻す確認手順**（before/after で `/cost` 等を比較）
