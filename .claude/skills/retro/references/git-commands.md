# Retro: Git コマンドリファレンス

## デフォルトブランチ検出

```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "main"
```

## データ収集コマンド（並列実行推奨）

### origin フェッチ＆ユーザー特定

```bash
git fetch origin <default> --quiet
git config user.name
git config user.email
```

### 1. 全コミット（タイムスタンプ、サブジェクト、ハッシュ、著者、変更統計）

```bash
git log origin/<default> --since="<window>" --format="%H|%aN|%ae|%ai|%s" --shortstat
```

### 2. テスト vs 本番 LOC 内訳

```bash
git log origin/<default> --since="<window>" --format="COMMIT:%H|%aN" --numstat
```

### 3. セッション検出用タイムスタンプ

```bash
git log origin/<default> --since="<window>" --format="%at|%aN|%ai|%s" | sort -n
```

### 4. ホットスポット分析

```bash
git log origin/<default> --since="<window>" --format="" --name-only | grep -v '^$' | sort | uniq -c | sort -rn
```

### 5. PR番号抽出

```bash
git log origin/<default> --since="<window>" --format="%s" | grep -oE '#[0-9]+' | sed 's/^#//' | sort -n | uniq | sed 's/^/#/'
```

### 6. 著者別ファイルホットスポット

```bash
git log origin/<default> --since="<window>" --format="AUTHOR:%aN" --name-only
```

### 7. 著者別コミット数

```bash
git shortlog origin/<default> --since="<window>" -sn --no-merges
```

### 8. ストリーク追跡

```bash
# チームストリーク
git log origin/<default> --format="%ad" --date=format:"%Y-%m-%d" | sort -u

# 個人ストリーク
git log origin/<default> --author="<user_name>" --format="%ad" --date=format:"%Y-%m-%d" | sort -u
```

## メトリクス算出テーブル

| メトリクス | 値 |
|-----------|---|
| main へのコミット | N |
| コントリビューター | N |
| マージ済みPR | N |
| 追加行数 | N |
| 削除行数 | N |
| 差引LOC | N |
| テストLOC（追加） | N |
| テストLOC比率 | N% |
| アクティブ日数 | N |
| 検出セッション | N |
| セッション時間あたりLOC | N |

## 著者別リーダーボード

```
Contributor         Commits   +/-          Top area
You (name)               32   +2400/-300   src/
alice                    12   +800/-150    app/services/
```
