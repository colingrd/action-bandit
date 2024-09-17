#!/bin/bash
set -euo pipefail

# Helper functions
install_tool() {
  local install_cmd="$2"
  local check_cmd="$3"
  local install_msg="$4"

  if ! command -v "${check_cmd}" &>/dev/null; then
    echo "::group::${install_msg}"
    eval "${install_cmd}"
    echo '::endgroup::'
  fi
}

cleanup() {
  if [[ -n "${RDTMP:-}" ]] && [[ -d "${RDTMP}" ]]; then
    rm -rf "$RDTMP"
  fi
}

print_output() {
  local file="$1"
  local label="$2"

  echo "::group:: 🛠️ ${label} ::"
  cat "$file"
  echo '::endgroup::'
}

# Set paths and environment variables
BASE_PATH="$(cd "$(dirname "$0")" && pwd)"
TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# Install reviewdog
echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

# Install bandit if not already installed
install_tool "bandit" "python -m pip install --upgrade bandit &> /dev/null" "bandit" "🐶 Installing bandit ..."

echo "[action-bandit] bandit version:"
bandit --version

# Prepare bandit arguments
BANDIT_ARGS=()
[ -n "${INPUT_BANDIT_CONFIG:-}" ] && BANDIT_ARGS+=(-c "${INPUT_BANDIT_CONFIG}")
[ -n "${INPUT_BANDIT_FLAGS:-}" ] && BANDIT_ARGS+=("${INPUT_BANDIT_FLAGS}")

# Create temporary directory and set trap for cleanup
RDTMP=$(mktemp -d)
trap cleanup EXIT

# Run bandit and convert output
set -x
bandit "${BANDIT_ARGS[@]}" -f json -o "$RDTMP/bandit.json" -r . --exit-zero
python3 "${BASE_PATH}/bandit_to_rdjson/rd_converter.py" <"$RDTMP/bandit.json" >"$RDTMP/bandit_rdjson.json"

# Configure reviewdog flags
REVIEWDOG_FLAGS="${INPUT_BANDIT_FLAGS:-}"
[ "${INPUT_VERBOSE:-false}" == "true" ] && {
  set +x
  print_output "$RDTMP/bandit.json" "original json output"
  print_output "$RDTMP/bandit_rdjson.json" "converted rdjson output"
  REVIEWDOG_FLAGS="$REVIEWDOG_FLAGS -tee"
}

# Run reviewdog
echo '::group:: Running bandit with reviewdog 🐶 ...'
set +e
set -x
reviewdog -f=rdjson \
  -name="${INPUT_TOOL_NAME}" \
  -reporter="${INPUT_REPORTER:-github-pr-review}" \
  -filter-mode="${INPUT_FILTER_MODE}" \
  -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
  -level="${INPUT_LEVEL}" \
  "${REVIEWDOG_FLAGS}" <"$RDTMP/bandit_rdjson.json"

reviewdog_rc=$?

set +x
echo "reviewdog exited with exit status $reviewdog_rc"
echo '::endgroup::'

exit $reviewdog_rc
