#!/usr/bin/env bash
# =============================================================================
# Terraform Project Initializer
# テンプレートから新規Terraformプロジェクトを作成する対話式スクリプト
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/../templates"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ヘルパー関数
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✖${NC} $1" >&2; }

# テンプレート一覧を取得
get_templates() {
    find "${TEMPLATE_DIR}" -maxdepth 1 -type d ! -name templates | sort | while read -r dir; do
        basename "$dir"
    done
}

# メイン処理
main() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Terraform Project Initializer                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # テンプレート選択
    info "利用可能なテンプレート:"
    echo ""

    templates=($(get_templates))
    for i in "${!templates[@]}"; do
        echo "  $((i+1))) ${templates[$i]}"
    done
    echo ""

    read -rp "テンプレート番号を選択 [1-${#templates[@]}]: " template_num

    if [[ ! "$template_num" =~ ^[0-9]+$ ]] || [ "$template_num" -lt 1 ] || [ "$template_num" -gt "${#templates[@]}" ]; then
        error "無効な選択です"
        exit 1
    fi

    TEMPLATE_NAME="${templates[$((template_num-1))]}"
    success "選択: ${TEMPLATE_NAME}"
    echo ""

    # プロジェクト名
    read -rp "プロジェクト名 (例: my-app): " PROJECT_NAME
    if [[ -z "$PROJECT_NAME" ]]; then
        error "プロジェクト名は必須です"
        exit 1
    fi

    # 環境
    read -rp "環境 [dev/stg/prod] (デフォルト: dev): " ENVIRONMENT
    ENVIRONMENT="${ENVIRONMENT:-dev}"

    # リージョン（クラウドプロバイダーに応じて）
    case "$TEMPLATE_NAME" in
        aws-*)
            read -rp "AWSリージョン (デフォルト: ap-northeast-1): " REGION
            REGION="${REGION:-ap-northeast-1}"
            REGION_PLACEHOLDER="AWS_REGION"
            ;;
        gcp-*)
            read -rp "GCPリージョン (デフォルト: asia-northeast1): " REGION
            REGION="${REGION:-asia-northeast1}"
            REGION_PLACEHOLDER="GCP_REGION"
            ;;
        azure-*)
            read -rp "Azureリージョン (デフォルト: japaneast): " REGION
            REGION="${REGION:-japaneast}"
            REGION_PLACEHOLDER="AZURE_REGION"
            ;;
        *)
            REGION=""
            REGION_PLACEHOLDER=""
            ;;
    esac

    # Terraformバージョン
    read -rp "Terraformバージョン (デフォルト: 1.5.0): " TERRAFORM_VERSION
    TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.5.0}"

    # 出力先
    read -rp "出力ディレクトリ (デフォルト: ./${PROJECT_NAME}): " OUTPUT_DIR
    OUTPUT_DIR="${OUTPUT_DIR:-./${PROJECT_NAME}}"

    echo ""
    info "設定内容:"
    echo "  テンプレート:      ${TEMPLATE_NAME}"
    echo "  プロジェクト名:    ${PROJECT_NAME}"
    echo "  環境:              ${ENVIRONMENT}"
    [[ -n "$REGION" ]] && echo "  リージョン:        ${REGION}"
    echo "  Terraformバージョン: ${TERRAFORM_VERSION}"
    echo "  出力先:            ${OUTPUT_DIR}"
    echo ""

    read -rp "この設定で作成しますか？ [Y/n]: " confirm
    if [[ "${confirm,,}" == "n" ]]; then
        warn "キャンセルしました"
        exit 0
    fi

    # ディレクトリ作成
    if [[ -d "$OUTPUT_DIR" ]]; then
        error "ディレクトリ ${OUTPUT_DIR} は既に存在します"
        exit 1
    fi

    mkdir -p "$OUTPUT_DIR"

    # テンプレートをコピー
    cp -r "${TEMPLATE_DIR}/${TEMPLATE_NAME}/." "$OUTPUT_DIR/"

    # プレースホルダーを置換
    find "$OUTPUT_DIR" -type f \( -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "*.go" -o -name "go.mod" \) | while read -r file; do
        sed -i.bak \
            -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
            -e "s/{{ENVIRONMENT}}/${ENVIRONMENT}/g" \
            -e "s/{{TERRAFORM_VERSION}}/${TERRAFORM_VERSION}/g" \
            "$file"

        # リージョン置換（プロバイダーに応じて）
        if [[ -n "$REGION_PLACEHOLDER" ]]; then
            sed -i.bak "s/{{${REGION_PLACEHOLDER}}}/${REGION}/g" "$file"
        fi

        # バックアップファイル削除
        rm -f "${file}.bak"
    done

    # terraform.tfvars を生成（AWSプロジェクトの場合）
    if [[ "$TEMPLATE_NAME" == aws-* ]]; then
        cat > "${OUTPUT_DIR}/terraform.tfvars" <<EOF
# ${PROJECT_NAME} - ${ENVIRONMENT} Environment Variables
project_name = "${PROJECT_NAME}"
environment  = "${ENVIRONMENT}"
aws_region   = "${REGION}"
EOF
        success "terraform.tfvars を生成しました"
    fi

    # .gitignore を作成
    cat > "${OUTPUT_DIR}/.gitignore" <<'EOF'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars
!*.tfvars.example
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# IDE
.idea/
*.swp
*.swo
.vscode/

# OS
.DS_Store
EOF
    success ".gitignore を生成しました"

    # terraform.tfvars.example を作成
    if [[ -f "${OUTPUT_DIR}/terraform.tfvars" ]]; then
        sed 's/= ".*"/= ""/' "${OUTPUT_DIR}/terraform.tfvars" > "${OUTPUT_DIR}/terraform.tfvars.example"
        success "terraform.tfvars.example を生成しました"
    fi

    echo ""
    success "プロジェクトを作成しました: ${OUTPUT_DIR}"
    echo ""
    info "次のステップ:"
    echo "  cd ${OUTPUT_DIR}"
    echo "  terraform init"
    echo "  terraform plan"
    echo ""
}

main "$@"
