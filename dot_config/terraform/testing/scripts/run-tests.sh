#!/usr/bin/env bash
# =============================================================================
# run-tests.sh - Run Terraform infrastructure tests
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
TEST_DIR="${TEST_DIR:-$PROJECT_ROOT/test}"
TEST_TIMEOUT="${TEST_TIMEOUT:-30m}"
TEST_PARALLELISM="${TEST_PARALLELISM:-2}"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    command -v "$1" &> /dev/null
}

usage() {
    cat << EOF
Usage: $(basename "$0") [options] [test-pattern]

Options:
    -d, --dir <path>        Test directory (default: ./test)
    -t, --timeout <duration> Test timeout (default: 30m)
    -p, --parallel <n>      Number of parallel tests (default: 2)
    -v, --verbose           Verbose output
    --skip-validate         Skip validation before tests
    --keep-resources        Don't destroy resources after test failure
    -h, --help              Show this help message

Test Patterns:
    TestVPC                 Run only VPC tests
    TestSubnet              Run only subnet tests
    ./...                   Run all tests (default)

Examples:
    $(basename "$0")                           # Run all tests
    $(basename "$0") TestVPC                   # Run VPC tests only
    $(basename "$0") -v -t 1h ./...            # Verbose with 1h timeout
    $(basename "$0") --skip-validate TestVPC   # Skip validation
EOF
}

# =============================================================================
# Pre-flight Checks
# =============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    if ! check_command go; then
        missing+=("go")
    fi

    if ! check_command terraform; then
        missing+=("terraform")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        echo "Please install the missing tools and try again."
        exit 1
    fi

    # Check Go version
    local go_version
    go_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
    local required_version="1.21"

    if [[ "$(printf '%s\n' "$required_version" "$go_version" | sort -V | head -n1)" != "$required_version" ]]; then
        log_warn "Go version $go_version may be too old. Recommended: $required_version+"
    fi

    log_success "Prerequisites check passed"
}

check_aws_credentials() {
    log_info "Checking AWS credentials..."

    if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]] && [[ -z "${AWS_PROFILE:-}" ]]; then
        if ! check_command aws; then
            log_error "AWS CLI not installed and no credentials in environment"
            exit 1
        fi

        if ! aws sts get-caller-identity > /dev/null 2>&1; then
            log_error "AWS credentials not configured"
            echo "Please configure AWS credentials using:"
            echo "  - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
            echo "  - AWS_PROFILE environment variable"
            echo "  - aws configure"
            exit 1
        fi
    fi

    log_success "AWS credentials configured"
}

# =============================================================================
# Test Execution
# =============================================================================

run_validation() {
    log_info "Running pre-test validation..."

    local validate_script="$SCRIPT_DIR/validate-all.sh"

    if [[ -x "$validate_script" ]]; then
        if ! "$validate_script"; then
            log_error "Validation failed. Fix issues before running tests."
            exit 1
        fi
    else
        # Basic validation
        log_info "Running basic Terraform validation..."
        if ! terraform fmt -check -recursive "$PROJECT_ROOT" > /dev/null 2>&1; then
            log_warn "Terraform format check failed"
        fi
    fi
}

setup_test_environment() {
    log_info "Setting up test environment..."

    if [[ ! -d "$TEST_DIR" ]]; then
        log_error "Test directory not found: $TEST_DIR"
        exit 1
    fi

    cd "$TEST_DIR"

    # Download Go dependencies
    if [[ -f "go.mod" ]]; then
        log_info "Downloading Go dependencies..."
        go mod download
        go mod tidy
    fi

    log_success "Test environment ready"
}

run_tests() {
    local test_pattern="${1:-./...}"
    local verbose="${2:-false}"

    log_info "Running tests..."
    log_info "  Directory: $TEST_DIR"
    log_info "  Pattern: $test_pattern"
    log_info "  Timeout: $TEST_TIMEOUT"
    log_info "  Parallelism: $TEST_PARALLELISM"
    echo ""

    cd "$TEST_DIR"

    local go_test_args=(
        "-v"
        "-timeout" "$TEST_TIMEOUT"
        "-parallel" "$TEST_PARALLELISM"
    )

    if [[ "$verbose" == "true" ]]; then
        go_test_args+=("-count=1")  # Disable test caching
    fi

    # Set Terratest-specific environment variables
    export SKIP_cleanup="false"
    export TF_IN_AUTOMATION="true"

    local start_time
    start_time=$(date +%s)

    if go test "${go_test_args[@]}" "$test_pattern"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        log_success "All tests passed in ${duration}s"
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        log_error "Tests failed after ${duration}s"
        exit 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local test_pattern="./..."
    local verbose="false"
    local skip_validate="false"
    local keep_resources="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--dir)
                TEST_DIR="$2"
                shift 2
                ;;
            -t|--timeout)
                TEST_TIMEOUT="$2"
                shift 2
                ;;
            -p|--parallel)
                TEST_PARALLELISM="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            --skip-validate)
                skip_validate="true"
                shift
                ;;
            --keep-resources)
                keep_resources="true"
                export SKIP_cleanup="true"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                test_pattern="$1"
                shift
                ;;
        esac
    done

    echo "=============================================="
    echo "  Terraform Infrastructure Tests"
    echo "=============================================="
    echo ""

    check_prerequisites
    check_aws_credentials

    if [[ "$skip_validate" != "true" ]]; then
        run_validation
    fi

    setup_test_environment
    run_tests "$test_pattern" "$verbose"
}

main "$@"
