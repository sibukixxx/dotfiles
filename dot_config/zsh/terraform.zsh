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
