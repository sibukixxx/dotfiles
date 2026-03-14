# terraform module template placeholders

- Status: done
- Updated: 2026-03-12
- Progress: 100%
- Summary: `tfmodule new` now generates guidance-oriented scaffolds, and `tfmodule validate` rejects the legacy placeholder strings that used to ship in new modules.
- Evidence:
- `dot_config/zsh/terraform.zsh` now writes actionable scaffold comments into `main.tf`, `outputs.tf`, and `README.md` instead of raw `TODO` text.
- `dot_config/zsh/terraform.zsh` now adds `_tfmodule_check_placeholders`, and `tfmodule validate` fails if the old placeholder strings are present in a module.
- `zsh -n dot_config/zsh/terraform.zsh` passed on 2026-03-12.
- A temporary module created with `tfmodule new sample` validated successfully, and the same module failed validation immediately after reintroducing `TODO: Add module description here.` into `README.md`.
- Remaining work: none
