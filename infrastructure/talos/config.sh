#!/usr/bin/env bash
set -euo pipefail

# Simple helper to run terraform then Talos-related post-apply commands
# Configurable via environment variables (see below)

# Defaults (can be overridden via env)
TF_DIR="${TF_DIR:-terraform}"
TF_PLAN_FILE="${TF_PLAN_FILE:-tfplan}"
PM_PATCH_PATH="${PM_PATCH_PATH:-./pm-qemu-agent-patch.yaml}"

# If set, a comma-separated list of targets (IP or hostname) to pass to talosctl
# Example: export TALOS_TARGETS="192.168.1.10,192.168.1.11"
TALOS_TARGETS="${TALOS_TARGETS:-}"

# Extra talosctl commands (separate multiple commands with ';;')
# Example: export TALOS_COMMANDS="talosctl -n 192.168.1.10 bootstrap;;talosctl -n 192.168.1.10 apply-config -f cluster.yaml"
TALOS_COMMANDS="${TALOS_COMMANDS:-}"

usage() {
  cat <<EOF
Usage: $(basename "$0")

Environment variables:
  TF_DIR             Directory containing Terraform configuration (default: terraform)
  TF_PLAN_FILE       File name for terraform plan (default: tfplan)
  TALOS_TARGETS      Comma-separated list of talos targets (IPs/hosts)
  TALOS_COMMANDS     Extra talosctl commands separated by ';;' (optional)
  PM_PATCH_PATH      Path to pm-qemu-agent-patch.yaml (default: ./pm-qemu-agent-patch.yaml)

The script runs: terraform init -> terraform plan -> terraform apply,
then runs any talosctl commands provided and finally applies the pm-qemu-agent patch via kubectl.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "Working directory: ${TF_DIR}"
pushd "${TF_DIR}" >/dev/null

echo "Running terraform init"
terraform init

echo "Running terraform plan -> ${TF_PLAN_FILE}"
terraform plan -out="${TF_PLAN_FILE}"

echo "Applying terraform plan"
terraform apply -auto-approve "${TF_PLAN_FILE}"

echo "Terraform apply complete"

# Return to repository root
popd >/dev/null

# Run talosctl commands if provided
if [[ -n "${TALOS_COMMANDS}" ]]; then
  echo "Running configured talosctl commands"
  IFS=';;' read -r -a cmds <<<"${TALOS_COMMANDS}"
  for c in "${cmds[@]}"; do
    c_trim=$(echo "${c}" | sed 's/^\s\+//;s/\s\+$//')
    if [[ -n "${c_trim}" ]]; then
      echo "> ${c_trim}"
      eval "${c_trim}"
    fi
  done
elif [[ -n "${TALOS_TARGETS}" ]]; then
  echo "TALOS_TARGETS provided; running default bootstrap for each target"
  IFS=',' read -r -a targets <<<"${TALOS_TARGETS}"
  for t in "${targets[@]}"; do
    t_trim=$(echo "${t}" | sed 's/^\s\+//;s/\s\+$//')
    if [[ -n "${t_trim}" ]]; then
      echo "Bootstrapping talos on ${t_trim}"
      talosctl -n "${t_trim}" bootstrap
    fi
  done
else
  echo "No talos commands or targets provided; skipping talos bootstrap step"
fi

# Apply pm-qemu-agent patch if file exists
if [[ -f "${PM_PATCH_PATH}" ]]; then
  echo "Applying pm-qemu-agent patch from ${PM_PATCH_PATH}"
  kubectl apply -f "${PM_PATCH_PATH}"
else
  echo "Patch file ${PM_PATCH_PATH} not found; skipping"
fi

echo "All done."
