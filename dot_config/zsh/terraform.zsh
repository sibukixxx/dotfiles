# =============================================================================
# Terraform Shell Functions and Aliases
# =============================================================================

# Basic aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt'
alias tfo='terraform output'
alias tfs='terraform show'
alias tfr='terraform refresh'
alias tfw='terraform workspace'

# Workspace aliases
alias tfwl='terraform workspace list'
alias tfws='terraform workspace select'
alias tfwn='terraform workspace new'
alias tfwd='terraform workspace delete'

# =============================================================================
# tfcheck - Run all validation and security checks
# =============================================================================
tfcheck() {
    local has_error=0

    echo "=== Running Terraform Format Check ==="
    if ! terraform fmt -check -recursive; then
        echo "[WARN] Format issues found. Run 'terraform fmt -recursive' to fix."
        has_error=1
    fi
    echo ""

    echo "=== Running Terraform Validate ==="
    if ! terraform validate; then
        echo "[ERROR] Validation failed."
        has_error=1
    fi
    echo ""

    echo "=== Running TFLint ==="
    if command -v tflint &> /dev/null; then
        if ! tflint --recursive; then
            echo "[WARN] TFLint found issues."
            has_error=1
        fi
    else
        echo "[SKIP] TFLint not installed."
    fi
    echo ""

    echo "=== Running tfsec ==="
    if command -v tfsec &> /dev/null; then
        if ! tfsec .; then
            echo "[WARN] tfsec found security issues."
            has_error=1
        fi
    else
        echo "[SKIP] tfsec not installed."
    fi
    echo ""

    echo "=== Running Checkov ==="
    if command -v checkov &> /dev/null; then
        if ! checkov -d . --compact=false; then
            echo "[WARN] Checkov found issues."
            has_error=1
        fi
    else
        echo "[SKIP] Checkov not installed. Install with: pipx install checkov"
    fi
    echo ""

    if [[ $has_error -eq 0 ]]; then
        echo "All checks passed!"
    else
        echo "Some checks had warnings or errors."
    fi

    return $has_error
}

# =============================================================================
# tfcd - Navigate to Terraform projects with fzf
# =============================================================================
tfcd() {
    local tf_dirs
    local selected_dir

    # Find directories containing .tf files
    tf_dirs=$(find "${1:-.}" -name "*.tf" -type f 2>/dev/null | \
        xargs -I {} dirname {} | \
        sort -u)

    if [[ -z "$tf_dirs" ]]; then
        echo "No Terraform projects found."
        return 1
    fi

    if command -v fzf &> /dev/null; then
        selected_dir=$(echo "$tf_dirs" | fzf --prompt="Select Terraform project: ")
    elif command -v peco &> /dev/null; then
        selected_dir=$(echo "$tf_dirs" | peco --prompt="Select Terraform project: ")
    else
        echo "fzf or peco is required for interactive selection."
        echo "Available directories:"
        echo "$tf_dirs"
        return 1
    fi

    if [[ -n "$selected_dir" ]]; then
        cd "$selected_dir" || return 1
        echo "Changed to: $selected_dir"
    fi
}

# =============================================================================
# tfwf - Select Terraform workspace with fzf
# =============================================================================
tfwf() {
    local workspaces
    local selected

    if ! terraform workspace list &> /dev/null; then
        echo "Not in a Terraform directory or not initialized."
        return 1
    fi

    workspaces=$(terraform workspace list | sed 's/^\* //' | sed 's/^ *//')

    if command -v fzf &> /dev/null; then
        selected=$(echo "$workspaces" | fzf --prompt="Select workspace: ")
    elif command -v peco &> /dev/null; then
        selected=$(echo "$workspaces" | peco --prompt="Select workspace: ")
    else
        echo "fzf or peco is required for interactive selection."
        terraform workspace list
        return 1
    fi

    if [[ -n "$selected" ]]; then
        terraform workspace select "$selected"
    fi
}

# =============================================================================
# tfplan-save - Save plan to file with timestamp
# =============================================================================
tfplan-save() {
    local plan_name="${1:-tfplan-$(date +%Y%m%d-%H%M%S)}"
    terraform plan -out="$plan_name"
    echo "Plan saved to: $plan_name"
}

# =============================================================================
# tfapply-plan - Apply a saved plan file
# =============================================================================
tfapply-plan() {
    local plan_file="$1"

    if [[ -z "$plan_file" ]]; then
        # Find plan files and let user select
        local plan_files
        plan_files=$(find . -maxdepth 1 -name "tfplan-*" -type f 2>/dev/null | sort -r)

        if [[ -z "$plan_files" ]]; then
            echo "No plan files found. Run 'tfplan-save' first."
            return 1
        fi

        if command -v fzf &> /dev/null; then
            plan_file=$(echo "$plan_files" | fzf --prompt="Select plan file: ")
        elif command -v peco &> /dev/null; then
            plan_file=$(echo "$plan_files" | peco --prompt="Select plan file: ")
        else
            echo "Specify a plan file or install fzf/peco."
            echo "Available plans:"
            echo "$plan_files"
            return 1
        fi
    fi

    if [[ -n "$plan_file" ]]; then
        terraform apply "$plan_file"
    fi
}

# =============================================================================
# tfdocs - Generate documentation for current module
# =============================================================================
tfdocs() {
    if command -v terraform-docs &> /dev/null; then
        terraform-docs markdown table . > README.md
        echo "Documentation generated in README.md"
    else
        echo "terraform-docs not installed. Install with: brew install terraform-docs"
        return 1
    fi
}

# =============================================================================
# tfclean - Clean up Terraform cache and lock files
# =============================================================================
tfclean() {
    echo "This will remove:"
    echo "  - .terraform/ directories"
    echo "  - .terraform.lock.hcl files"
    echo "  - *.tfplan files"
    echo ""
    read -r "REPLY?Are you sure? [y/N] "

    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null
        find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null
        find . -type f -name "*.tfplan" -delete 2>/dev/null
        find . -type f -name "tfplan-*" -delete 2>/dev/null
        echo "Terraform cache cleaned."
    else
        echo "Aborted."
    fi
}

# =============================================================================
# tfenv-use - Switch Terraform version (if tfenv is installed)
# =============================================================================
tfenv-use() {
    if command -v tfenv &> /dev/null; then
        if [[ -n "$1" ]]; then
            tfenv use "$1"
        else
            tfenv list | head -20
        fi
    else
        echo "tfenv not installed. Using system terraform."
        terraform version
    fi
}

# =============================================================================
# tftest - Run infrastructure tests with Terratest
# =============================================================================
tftest() {
    local test_dir="${1:-test}"
    local test_pattern="${2:-./...}"
    local timeout="${3:-30m}"

    if [[ ! -d "$test_dir" ]]; then
        echo "[ERROR] Test directory not found: $test_dir"
        echo "Create tests with: tf-new <template> <name> --with-tests"
        return 1
    fi

    echo "=== Running Infrastructure Tests ==="
    echo "Directory: $test_dir"
    echo "Pattern: $test_pattern"
    echo "Timeout: $timeout"
    echo ""

    # Check prerequisites
    if ! command -v go &> /dev/null; then
        echo "[ERROR] Go is required for Terratest. Install with: brew install go"
        return 1
    fi

    # Change to test directory and run tests
    (
        cd "$test_dir" || exit 1

        # Download dependencies if go.mod exists
        if [[ -f "go.mod" ]]; then
            echo "Downloading Go dependencies..."
            go mod download
            go mod tidy
        fi

        # Run tests
        echo ""
        echo "Running tests..."
        go test -v -timeout "$timeout" -parallel 2 "$test_pattern"
    )
}

# =============================================================================
# tfmodule - Manage and create Terraform modules
# =============================================================================
tfmodule() {
    local command="${1:-help}"
    local module_name="${2:-}"

    case "$command" in
        list)
            echo "Available modules in current project:"
            if [[ -d "modules" ]]; then
                for module_dir in modules/*/; do
                    if [[ -d "$module_dir" ]]; then
                        local name
                        name=$(basename "$module_dir")
                        echo "  - $name"
                    fi
                done
            else
                echo "  No modules directory found."
            fi
            ;;
        new)
            if [[ -z "$module_name" ]]; then
                echo "Usage: tfmodule new <module-name>"
                return 1
            fi

            local module_dir="modules/$module_name"
            if [[ -d "$module_dir" ]]; then
                echo "[ERROR] Module already exists: $module_name"
                return 1
            fi

            echo "Creating module: $module_name"
            mkdir -p "$module_dir"

            # Create main.tf
            cat > "$module_dir/main.tf" << 'EOF'
# =============================================================================
# Main Module Configuration
# =============================================================================

# TODO: Add your resources here
EOF

            # Create variables.tf
            cat > "$module_dir/variables.tf" << 'EOF'
# =============================================================================
# Input Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be dev, stg, or prod."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
EOF

            # Create outputs.tf
            cat > "$module_dir/outputs.tf" << 'EOF'
# =============================================================================
# Output Values
# =============================================================================

# TODO: Add your outputs here
EOF

            # Create README.md
            cat > "$module_dir/README.md" << EOF
# $module_name Module

## Description

TODO: Add module description here.

## Usage

\`\`\`hcl
module "$module_name" {
  source = "./modules/$module_name"

  project_name = var.project_name
  environment  = var.environment
}
\`\`\`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | string | n/a | yes |
| environment | Environment (dev, stg, prod) | string | n/a | yes |
| tags | Additional tags for resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| TODO | TODO |
EOF

            echo "[SUCCESS] Module created: $module_dir"
            echo ""
            echo "Next steps:"
            echo "  1. Edit $module_dir/main.tf to add resources"
            echo "  2. Add required variables to $module_dir/variables.tf"
            echo "  3. Define outputs in $module_dir/outputs.tf"
            echo "  4. Update $module_dir/README.md"
            ;;
        docs)
            if [[ -z "$module_name" ]]; then
                echo "Generating docs for all modules..."
                if command -v terraform-docs &> /dev/null; then
                    for module_dir in modules/*/; do
                        if [[ -d "$module_dir" ]]; then
                            echo "  Generating: $module_dir"
                            terraform-docs markdown table "$module_dir" > "$module_dir/README.md"
                        fi
                    done
                    echo "[SUCCESS] Documentation generated"
                else
                    echo "[ERROR] terraform-docs not installed. Install with: brew install terraform-docs"
                    return 1
                fi
            else
                local module_dir="modules/$module_name"
                if [[ ! -d "$module_dir" ]]; then
                    echo "[ERROR] Module not found: $module_name"
                    return 1
                fi
                if command -v terraform-docs &> /dev/null; then
                    terraform-docs markdown table "$module_dir" > "$module_dir/README.md"
                    echo "[SUCCESS] Documentation generated: $module_dir/README.md"
                else
                    echo "[ERROR] terraform-docs not installed. Install with: brew install terraform-docs"
                    return 1
                fi
            fi
            ;;
        validate)
            echo "Validating modules..."
            local has_error=0
            for module_dir in modules/*/; do
                if [[ -d "$module_dir" ]]; then
                    local name
                    name=$(basename "$module_dir")
                    echo -n "  $name: "
                    if (cd "$module_dir" && terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1); then
                        echo "✓ valid"
                    else
                        echo "✗ invalid"
                        has_error=1
                    fi
                fi
            done
            return $has_error
            ;;
        help|*)
            cat << 'EOF'
Usage: tfmodule <command> [module-name]

Commands:
    list              List modules in current project
    new <name>        Create a new module scaffold
    docs [name]       Generate documentation (all or specific module)
    validate          Validate all modules

Examples:
    tfmodule list
    tfmodule new vpc
    tfmodule docs
    tfmodule docs vpc
    tfmodule validate
EOF
            ;;
    esac
}
