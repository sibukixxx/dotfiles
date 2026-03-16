# 機能ギャップ分析

現行システムに不足している機能と、次期システムで実装すべき要件の一覧。

---

## 機能ギャップ一覧

### A. 機能が存在しない（新規開発必須）

| No | 業務分類 | 必要機能 | 詳細 | 実装優先度 |
|----|---------|---------|------|-----------|
| F-1 | 調査票配布/作成 | 調査票フォーマット編集 | 調査項目の追加・削除に対応するWeb入力フォーム管理機能 | 高 |
| F-2 | 調査票提出 | 未記入バリデーション | 各ページに必須チェックを定義し未記入での提出を制御 | 高 |
| F-3 | 調査票提出 | 重複調査票の差異表示 | 受領済み調査票との差分をハイライト表示 | 中 |
| F-4 | 調査票提出 | 石油事業者側修正・取下げ | 申請取下げ・内容修正機能＋変更履歴記録 | 高 |
| F-5 | 登録データ確認 | ローデータ出力 | 個票DB・集計DBのローデータをCSV/Excel出力 | 高 |
| F-6 | 登録データ確認 | 直接修正機能 | 画面上でデータを直接編集（再取込不要） | 高 |
| F-7 | 登録データ確認 | 修正履歴保管 | 変更履歴の自動記録と表示 | 中 |
| F-8 | 登録データ確認 | 強制登録機能 | バランスチェックエラー時に運用者判断で強制登録 | 中 |
| F-9 | 統計集計 | 統計間クロスチェック | 複数調査票間の数値突合（旧Accessで実施していた機能） | 高 |
| F-10 | 公開準備 | 日付自動計算 | 「○○ヵ月ぶり」等の情報を過去データから自動算出 | 中 |
| F-11 | 公開準備 | 原稿HTML自動化 | テンプレートベースの公開用HTML原稿自動生成 | 中 |
| F-12 | 随時作業 | 年間補正 | 訂正前後データの差異比較・履歴保持 | 中 |
| F-13 | 緊急時 | 提出状況管理 | リアルタイムの提出状況ダッシュボード | 高 |

### B. 機能はあるが不十分（改善必須）

| No | 業務分類 | 必要機能 | 現状の問題 | 改善内容 |
|----|---------|---------|-----------|---------|
| F-14 | 調査票配布 | 差し込み印刷 | VBAで独自実装 | システム標準機能として実装 |
| F-15 | 調査票受領確認 | 提出状況確認 | 企業名が表示されない | 企業名・事業所名の表示追加 |
| F-16 | 登録データ確認 | 月末在庫量比較 | 値の乖離表示がない | 前月値との比較・乖離量を表示 |
| F-17 | 登録データ確認 | 疑義照会 | 一部調査票のみ対応、情報量不十分 | 全調査票対応・詳細情報表示 |
| F-18 | 統計集計 | 帳票作成 | 旧システムマクロ依存、1帳票のみ | 全帳票を次期システムから出力 |
| F-19 | 随時作業 | マスタデータ登録 | 画面が見づらく、コード出力できない | UI刷新・コード一覧出力対応 |
| F-20 | 緊急時 | システム停止対策 | 障害時に状況把握不能 | 監視・アラート・復旧手順整備 |

---

## 画面設計の3分類

次期システムの画面は以下の3分類で整理し、それぞれに適した要件を定義する：

### Type 1: データ編集画面
- 対象例: 調査票修正画面、フォーマット編集画面
- 要件: 項目単位でのインライン編集操作
- 記載方法: 当該画面で実施する「操作」を具体的に記載

### Type 2: データ参照画面
- 対象例: 報告状況確認画面、疑義照会画面
- 要件: 必要項目の漏れなき表示、ローデータ出力
- 記載方法: 「操作」に加え、表示項目・入出力情報を具体的に記載

### Type 3: 機能実行画面
- 対象例: 集計実行画面
- 要件: 操作する機能を満たしていること、迷いなく操作可能なこと
- 記載方法: 当該画面で実施する「操作」を記載

---

## React (TypeScript) での実装パターン例

### 調査票Web入力フォーム

```typescript
// 調査票の動的フォーム構成
interface SurveyField {
  id: string;
  label: string;
  type: 'number' | 'text' | 'select';
  required: boolean;
  validationRules?: ValidationRule[];
  options?: { value: string; label: string }[];
}

interface SurveyPage {
  pageId: string;
  title: string;
  fields: SurveyField[];
}

interface SurveyFormConfig {
  surveyType: 'demand_supply' | 'import' | 'emergency';
  pages: SurveyPage[];
  version: string;
}
```

### バリデーションチェック

```typescript
interface ValidationRule {
  type: 'required' | 'range' | 'cross_check' | 'balance';
  params?: Record<string, unknown>;
  errorMessage: string;
}

// ページ送り時のバリデーション
const validatePage = (page: SurveyPage, data: Record<string, unknown>): ValidationError[] => {
  const errors: ValidationError[] = [];
  for (const field of page.fields) {
    if (field.required && !data[field.id]) {
      errors.push({ fieldId: field.id, message: `${field.label}は必須項目です` });
    }
    // カスタムバリデーション
    field.validationRules?.forEach(rule => {
      const result = executeValidation(rule, data[field.id], data);
      if (!result.valid) errors.push({ fieldId: field.id, message: rule.errorMessage });
    });
  }
  return errors;
};
```

### Python (FastAPI) バックエンド例

```python
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

app = FastAPI(title="統計調査システム API")

# 調査票提出エンドポイント
@app.post("/api/surveys/{survey_type}/submit")
async def submit_survey(
    survey_type: str,
    submission: SurveySubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # バリデーション
    errors = validate_survey(survey_type, submission.data)
    if errors:
        raise HTTPException(status_code=422, detail=errors)

    # 重複チェック
    existing = check_duplicate(db, current_user.company_id, survey_type, submission.period)
    if existing:
        return {"status": "duplicate", "diff": compute_diff(existing, submission)}

    # 登録
    record = save_submission(db, submission, current_user)
    
    # 変更履歴記録
    log_change(db, record.id, "submit", current_user.id)
    
    return {"status": "success", "submission_id": record.id}


# 疑義照会エンドポイント
@app.get("/api/surveys/{survey_type}/inquiries")
async def get_inquiries(
    survey_type: str,
    period: str,
    cross_check: bool = False,
    db: Session = Depends(get_db),
):
    inquiries = fetch_inquiries(db, survey_type, period)
    if cross_check:
        # 統計間クロスチェック
        cross_results = perform_cross_check(db, period)
        inquiries.extend(cross_results)
    return inquiries
```
