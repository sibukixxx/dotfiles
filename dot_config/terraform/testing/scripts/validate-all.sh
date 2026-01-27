#!/usr/bin/env bash
# =============================================================================
# validate-all.sh - Run all Terraform validation checks
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((SKIPPED++))
}

check_command() {
    command -v "$1" &> /dev/null
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_format() {
    log_info "Checking Terraform format..."
    if terraform fmt -check -recursive -diff "$PROJECT_ROOT"; then
        log_success "Terraform format check"
    else
        log_fail "Terraform format check - run 'terraform fmt -recursive'"
        return 1
    fi
}

validate_terraform() {
    log_info "Running Terraform validate..."

    # Find all directories with .tf files
    local tf_dirs
    tf_dirs=$(find "$PROJECT_ROOT" -name "*.tf" -type f ! -path "*/.terraform/*" | xargs -I {} dirname {} | sort -u)

    local all_valid=true
    for dir in $tf_dirs; do
        if [[ -f "$dir/providers.tf" ]] || [[ -f "$dir/main.tf" ]]; then
            log_info "  Validating: $dir"
            if (cd "$dir" && terraform init -backend=false -input=false > /dev/null 2>&1 && terraform validate); then
                echo -e "    ${GREEN}✓${NC} Valid"
            else
                echo -e "    ${RED}✗${NC} Invalid"
                all_valid=false
            fi
        fi
    done

    if $all_valid; then
        log_success "Terraform validate"
    else
        log_fail "Terraform validate"
        return 1
    fi
}

run_tflint() {
    log_info "Running TFLint..."

    if ! check_command tflint; then
        log_skip "TFLint not installed"
        return 0
    fi

    if [[ -f "$PROJECT_ROOT/.tflint.hcl" ]]; then
        tflint --init --config="$PROJECT_ROOT/.tflint.hcl" > /dev/null 2>&1 || true
    fi

    if tflint --recursive; then
        log_success "TFLint"
    else
        log_fail "TFLint"
        return 1
    fi
}

run_tfsec() {
    log_info "Running tfsec..."

    if ! check_command tfsec; then
        log_skip "tfsec not installed (brew install tfsec)"
        return 0
    fi

    if tfsec "$PROJECT_ROOT" --soft-fail; then
        log_success "tfsec security scan"
    else
        log_fail "tfsec security scan"
        return 1
    fi
}

run_checkov() {
    log_info "Running Checkov..."

    if ! check_command checkov; then
        log_skip "Checkov not installed (pipx install checkov)"
        return 0
    fi

    if checkov -d "$PROJECT_ROOT" --compact --quiet --skip-check CKV_AWS_144,CKV_AWS_145; then
        log_success "Checkov security scan"
    else
        log_fail "Checkov security scan"
        return 1
    fi
}

check_sensitive_files() {
    log_info "Checking for sensitive files..."

    local sensitive_patterns=(
        "*.tfstate"
        "*.tfstate.*"
        "*.tfvars"
        "!*.tfvars.example"
        "*.pem"
        "*.key"
        ".env"
        "credentials"
        "secrets.yaml"
        "secrets.json"
    )

    local found_issues=false

    # Check if sensitive files are tracked by git
    if check_command git && git rev-parse --git-dir > /dev/null 2>&1; then
        for pattern in "${sensitive_patterns[@]}"; do
            if [[ "$pattern" == "!"* ]]; then
                continue
            fi

            local tracked_files
            tracked_files=$(git ls-files "$pattern" 2>/dev/null || true)
            if [[ -n "$tracked_files" ]]; then
                echo -e "  ${RED}WARNING${NC}: Sensitive file tracked by git: $tracked_files"
                found_issues=true
            fi
        done
    fi

    if $found_issues; then
        log_fail "Sensitive file check"
        return 1
    else
        log_success "Sensitive file check"
    fi
}

validate_modules() {
    log_info "Validating module structure..."

    local modules_dir="$PROJECT_ROOT/modules"

    if [[ ! -d "$modules_dir" ]]; then
        log_skip "No modules directory found"
        return 0
    fi

    local all_valid=true
    for module_dir in "$modules_dir"/*/; do
        if [[ -d "$module_dir" ]]; then
            local module_name
            module_name=$(basename "$module_dir")

            # Check required files
            local required_files=("main.tf" "variables.tf" "outputs.tf")
            for required_file in "${required_files[@]}"; do
                if [[ ! -f "$module_dir/$required_file" ]]; then
                    echo -e "  ${YELLOW}WARNING${NC}: $module_name missing $required_file"
                fi
            done

            # Check for README
            if [[ ! -f "$module_dir/README.md" ]]; then
                echo -e "  ${YELLOW}INFO${NC}: $module_name missing README.md"
            fi
        fi
    done

    if $all_valid; then
        log_success "Module structure validation"
    else
        log_fail "Module structure validation"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo "=============================================="
    echo "  Terraform Validation Suite"
    echo "  Project: $PROJECT_ROOT"
    echo "=============================================="
    echo ""

    local exit_code=0

    validate_format || exit_code=1
    echo ""

    validate_terraform || exit_code=1
    echo ""

    run_tflint || exit_code=1
    echo ""

    run_tfsec || exit_code=1
    echo ""

    run_checkov || exit_code=1
    echo ""

    check_sensitive_files || exit_code=1
    echo ""

    validate_modules || exit_code=1
    echo ""

    echo "=============================================="
    echo "  Summary"
    echo "=============================================="
    echo -e "  ${GREEN}Passed${NC}:  $PASSED"
    echo -e "  ${RED}Failed${NC}:  $FAILED"
    echo -e "  ${YELLOW}Skipped${NC}: $SKIPPED"
    echo "=============================================="

    if [[ $FAILED -gt 0 ]]; then
        echo -e "\n${RED}Validation failed!${NC}"
        exit 1
    else
        echo -e "\n${GREEN}All validations passed!${NC}"
        exit 0
    fi
}

main "$@"
