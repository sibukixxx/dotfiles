---
paths: **/*_test.go
---

# General Patterns

- **Domain models**: use `model_test` package (external test package)
- **Other tests**: same package as implementation
- **Test naming**: Japanese test case names for clarity
- **Test structure**: Table-driven tests with `cmp.Diff` for assertions
- **Parallel execution**: Use `t.Parallel()` for all non-I/O bound tests
- **Error validation**: Use `wantErr bool` and `errMsg string` fields
- **Coverage target**: 20% minimum, 30% for critical business logic

# テストコードコーディング規約

このドキュメントでは、本プロジェクトにおけるテストコードの記述に関する規約を定義する。テストの一貫性、可読性、保守性を向上させるため、以下の規約を遵守する。

---

## **1. テストの基本原則**

### **1.1. 目的の明確化**

- 各テストケースは、何を検証しているのかを明確にするため、名前やコメントで意図を記述する。
- テストケース名は**日本語**で具体的に記述し、何を検証しているかを明確にする。

### **1.2. 独立性の確保**

- 各テストケースは他のテストケースに依存しないように設計する。
- テストの実行順序に関係なく、常に同じ結果が得られるようにする。

### **1.3. 網羅性の追求**

- 正常系だけでなく、異常系、境界値、特殊なパターンも考慮したテストケースを作成する。
- 特に更新処理（Upsert など）では、様々な状態遷移を網羅するように努める。
- 記述順序は「**正常系 → 特殊パターン → 境界値 → エラー**」を基本とする。

---

## **2. テスト開発のワークフロー**

### **2.1. テスト設計**

- 実装に着手する前に、仕様書やタスク定義に基づき、**1.3. 網羅性の追求**で定義した観点（正常系・異常系・境界値・特殊パターン）から具体的なテストケースを洗い出す。
- 類似のテストファイルを参照し、既存のテストパターンを理解・活用する。
- テストデータは、再現性を確保するために可能な限り固定値を使用する。

### **2.2. 実装**

テスト駆動開発（TDD）のサイクルに沿った実装手順：

- **最初のテスト**: まず失敗するテストを書く（コンパイルエラーも OK）
- **仮実装**: テストを通すためにベタ書きでも OK（例：`return 42`）
- **三角測量**: 2 つ目、3 つ目のテストケースで一般化する
- **リファクタリング**: テストが通った後で整理する
- **TODO リスト更新**: 実装中に思いついたことはすぐリストに追加
- **1 つずつ**: 複数のテストを同時に書かない

実装時の注意点：

- テストケースは一つずつ実装し、その都度 `go test` を実行して意図通りに動作（または失敗）することを確認する。
- 失敗したテストは、次のテストケースを実装する前に修正する。

### **2.3. ドキュメント更新**

- テスト実装中に新しいテストパターンやヘルパー関数が生まれた場合は、関連ドキュメント（`docs/testing_*.md`）を更新する。
- テスト結果から得られた知見や、残課題、改善点などもドキュメントに記録し、チーム全体の知識レベルを維持する。

---

## **3. 実装規約とテクニック**

### **3.1. 使用するべきライブラリとテストヘルパー**

- `testing`
- `go.uber.org/mock/gomock`
- `github.com/google/go-cmp/cmp`
- `github.com/medtech-inc/toscana/api/test`
  - `test.StartTestDB`
- `github.com/medtech-inc/toscana/api/test/util`
  - `util.AnyPtr`
  - `util.NewCmpMatcher`
  - `util.AssertErrorHint`
- `github.com/medtech-inc/toscana/api/test/factory`

### **3.2. テスト構造**

**テスト構造の選択**

- **テーブル駆動テスト**: ユースケース層など、多様な入力と条件分岐を検証するテストに適している。テストケース構造体には `name`, `args`, `setup`, `want`, `wantErr` などを定義する。
- **サブテスト形式**: 永続層など、各テストケースの独立性が高く、一連の操作を記述する方が分かりやすいテストに適している。`t.Run` を用いて各ケースを記述する。

**並列実行 (`t.Parallel`)**

- `t.Parallel()` を呼び出してテストを並列実行することを**必須**とする。

### **3.3. 命名規則**

**テストパッケージ**

1. **ドメインモデルのテスト**

   - ドメインモデル（`internal/domain` 配下のエンティティ、値オブジェクトなど）のテストコードは、`model_test` パッケージを使用する。

2. **ドメインモデル以外のテスト**

   - ユースケース、インフラストラクチャ、ハンドラーなど、ドメインモデル以外のテストコードは、テスト対象と**同じパッケージ**に配置する (`_test` サフィックスは付けない)。

### **3.4. テストデータの準備**

**テストデータファクトリ**

- `test/factory` パッケージに、モデル構造を返す小さな関数群（ファクトリ）を用意している。これにより、テストごとに一貫性のあるデータを容易に作成できる。必要に応じてフィールドをオーバーライドして使用する。

**テストヘルパー関数**

- ポインタ型を簡単に生成する `test/util.AnyPtr` や、昇順の UUID を生成する `test.UUIDN` などのヘルパーを活用する。

**時刻の比較**

- テスト内で `time.Now()` を直接使用すると、実行タイミングによって結果が変わり再現性が損なわれるため、テスト関数の先頭で基準時刻を定義し、それを基点とした相対時間を使用する。

### **3.5. モックの利用**

**モック使用のプロジェクト固有ルール**

- 動的に変化する値（ID、時刻など）の比較には `gomock.Any()` や `util.NewCmpMatcher` を適切に使用する。
- モックの戻り値は、テストケース内で明示的に作成したオブジェクトを使用し、変数経由での設定は避ける（可読性のため）。
- モックの期待値設定は、実際のコード実行順序に合わせて記述する。これにより、テストの可読性とデバッグの容易性が向上する。

**モック引数の比較 (`util.NewCmpMatcher`)**

- `gomock` の期待値設定で、複雑な構造体の引数を `go-cmp` を使って比較したい場合は、`test/util` パッケージの `NewCmpMatcher` ヘルパーを使用する。

### **3.6. アサーションと比較**

**結果の検証**

- `github.com/google/go-cmp/cmp` パッケージの `cmp.Diff` を使用して、実行結果 (`got`) と期待される結果 (`want`) を比較する。

**比較オプション (`cmpopts`) の活用**

- 動的に変化するフィールド（ID、作成日時など）や比較対象外としたいフィールドを除外するために `cmpopts` パッケージを活用する。

**エラーメッセージの部分一致検証**

- 特定のエラーメッセージ（部分一致）を期待する場合は、`errMsg string` フィールドを追加し、`strings.Contains` などで検証する。

**エラーヒント（ユーザー向けメッセージ）の検証**

- `errors.WithHint` で設定されたユーザー向けメッセージを検証する場合は、`wantHint string` フィールドを使用し、`util.AssertErrorHint` ヘルパー関数で検証する。
- **フィールド名は `wantHint` に統一**する（`errMsg`, `hintMsg` は使用しない）。

```go
// テストケース構造体
tests := []struct {
    name     string
    args     args
    want     *model.SomeModel
    wantErr  bool
    wantHint string // ユーザー向けヒントメッセージ（errors.FlattenHints で検証）
    prepare  func(*mockContainer)
}{
    {
        name:     "異常系: 権限がない場合はエラー",
        wantErr:  true,
        wantHint: msg.SomePermissionDenied,
        prepare: func(m *mockContainer) {
            // ...
        },
    },
}

// 検証時
if (err != nil) != tt.wantErr {
    t.Errorf("Execute() error = %v, wantErr %v", err, tt.wantErr)
    return
}
util.AssertErrorHint(t, err, tt.wantHint)
```

### **3.7. バリデーションテスト**

**バリデーターの使用**

- `service.NewValidatorService()` を使用してバリデーションを実行。

---

## **4. テストカバレッジ**

**カバレッジ目標**

- ユニットテストのカバレッジは 20% 以上を目指す。
- 重要なビジネスロジックは 30% カバレッジを目指す。

---

この規約は、プロジェクトの品質を維持し、効率的な開発を支援するために重要である。新しい規約を追加したり変更したりする場合は、チーム全体で合意を得た上で更新する。
