# TDD原則 詳細リファレンス

t-wada（和田卓人）氏のTDD哲学に基づく詳細ガイド。

## 目次

1. [TDDの本質](#tddの本質)
2. [テストの原則](#テストの原則)
3. [テスト名の命名規則](#テスト名の命名規則)
4. [テストダブル](#テストダブル)
5. [テストピラミッド](#テストピラミッド)
6. [言語別パターン](#言語別パターン)

---

## TDDの本質

### なぜテストを先に書くのか

- **設計を駆動する**: テストを書くことで、使いやすいAPIを設計できる
- **スコープを限定する**: 必要な機能だけを実装する
- **ドキュメントになる**: テストが仕様書の役割を果たす
- **リファクタリングを可能にする**: 安心してコードを変更できる

### 「動くコード」と「きれいなコード」

```
動作するきれいなコード（Clean code that works）
      ↑
1. まず動くコードを書く（GREEN）
2. それからきれいにする（REFACTOR）
```

## テストの原則

### FIRST原則

| 原則 | 意味 | 実践 |
|------|------|------|
| **F**ast | 高速 | テストは数ミリ秒で完了すべき |
| **I**solated | 独立 | 各テストは他に依存しない |
| **R**epeatable | 再現可能 | 何度実行しても同じ結果 |
| **S**elf-validating | 自己検証 | 手動確認不要で成否が分かる |
| **T**imely | 適時 | 実装コードの前に書く |

### 1テスト1アサーション

```
// Bad: 複数のことを検証
it('should handle user registration', () => {
  const user = register('test@example.com', 'password');
  expect(user.email).toBe('test@example.com');
  expect(user.isActive).toBe(true);
  expect(user.createdAt).toBeDefined();
  expect(sendEmail).toHaveBeenCalled();
});

// Good: 振る舞いごとに分割
describe('user registration', () => {
  it('should set email from input', () => {
    const user = register('test@example.com', 'password');
    expect(user.email).toBe('test@example.com');
  });

  it('should activate user by default', () => {
    const user = register('test@example.com', 'password');
    expect(user.isActive).toBe(true);
  });

  it('should send welcome email', () => {
    register('test@example.com', 'password');
    expect(sendEmail).toHaveBeenCalledWith('test@example.com');
  });
});
```

## テスト名の命名規則

### パターン1: should...when...

```
it('should return zero when list is empty')
it('should throw error when input is null')
it('should calculate total when items have prices')
```

### パターン2: describe + it

```
describe('Calculator', () => {
  describe('#add', () => {
    it('returns sum of two positive numbers')
    it('handles negative numbers')
    it('throws on non-numeric input')
  });
});
```

### パターン3: Given-When-Then (BDD)

```
describe('given an empty cart', () => {
  describe('when adding an item', () => {
    it('then cart contains one item')
    it('then total equals item price')
  });
});
```

## テストダブル

### 使い分け

| 種類 | 用途 | 例 |
|------|------|-----|
| Stub | 固定値を返す | `getUser = () => ({ id: 1, name: 'Test' })` |
| Mock | 呼び出しを検証 | `expect(sendEmail).toHaveBeenCalledWith(...)` |
| Spy | 本物の呼び出しを記録 | 実際の処理 + 呼び出し記録 |
| Fake | 簡易実装 | インメモリDB |

### モックを使う判断基準

```
本物を使う ← ─────────────────────── → モックを使う
                      │
                      │
    高速で決定的    │    遅い/非決定的
    副作用なし      │    副作用あり
    テスト環境で動く │    テスト環境で動かない
```

**モックすべきもの:**
- 外部API呼び出し
- データベース（統合テストは除く）
- ファイルシステム
- 現在時刻
- 乱数

**モックすべきでないもの:**
- 純粋な計算ロジック
- 同じモジュール内のヘルパー関数
- データ構造

## テストピラミッド

```
         /\
        /  \     E2Eテスト（少）
       /    \    - ユーザー視点の重要フロー
      /──────\   - 実行コスト高
     /        \  統合テスト（中）
    /          \ - コンポーネント間連携
   /────────────\- DB/API実際に使用
  /              \ユニットテスト（多）
 /                \- 関数/クラス単位
/──────────────────\- 高速・大量実行
```

### 比率の目安

- ユニットテスト: 70%
- 統合テスト: 20%
- E2Eテスト: 10%

## 言語別パターン

### Go

```go
func TestAdd(t *testing.T) {
    // Arrange
    calc := NewCalculator()

    // Act
    result := calc.Add(1, 2)

    // Assert
    if result != 3 {
        t.Errorf("Add(1, 2) = %d; want 3", result)
    }
}

// テーブル駆動テスト
func TestAdd_TableDriven(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 1, 2, 3},
        {"negative numbers", -1, -2, -3},
        {"zero", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### JavaScript/TypeScript

```typescript
describe('Calculator', () => {
  describe('add', () => {
    it('should return sum of two positive numbers', () => {
      // Arrange
      const calc = new Calculator();

      // Act
      const result = calc.add(1, 2);

      // Assert
      expect(result).toBe(3);
    });

    it.each([
      [1, 2, 3],
      [-1, -2, -3],
      [0, 0, 0],
    ])('should add %i and %i to get %i', (a, b, expected) => {
      expect(new Calculator().add(a, b)).toBe(expected);
    });
  });
});
```

### Python

```python
import pytest

class TestCalculator:
    def test_add_positive_numbers(self):
        # Arrange
        calc = Calculator()

        # Act
        result = calc.add(1, 2)

        # Assert
        assert result == 3

    @pytest.mark.parametrize("a,b,expected", [
        (1, 2, 3),
        (-1, -2, -3),
        (0, 0, 0),
    ])
    def test_add_various_inputs(self, a, b, expected):
        assert Calculator().add(a, b) == expected
```

---

## リファクタリング時のテスト戦略

1. **既存テストを全て通す**ことを最初に確認
2. リファクタリング中は**テストを変更しない**
3. 1ステップごとにテスト実行
4. テストが壊れたら**即座に戻す**
5. 新しいテストは**リファクタリング完了後**に追加
