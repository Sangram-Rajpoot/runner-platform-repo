#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_SCOPE:?Set RUNNER_SCOPE to repo or org}"
: "${GITHUB_OWNER:?Set GITHUB_OWNER}"
: "${GITHUB_PAT:?Set GITHUB_PAT}"

RUNNER_NAME="${RUNNER_NAME:-runner-$(hostname)}"
GITHUB_BASE_URL="${GITHUB_BASE_URL:-https://github.com}"
GITHUB_API_URL="${GITHUB_API_URL:-https://api.github.com}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-_work}"
RUNNER_LABELS="${RUNNER_LABELS:-jenkins-docker}"
EPHEMERAL="${EPHEMERAL:-true}"
DISABLE_RUNNER_UPDATE="${DISABLE_RUNNER_UPDATE:-true}"

if [[ "${RUNNER_SCOPE}" == "repo" ]]; then
  : "${GITHUB_REPO:?Set GITHUB_REPO when RUNNER_SCOPE=repo}"

  RUNNER_URL="${GITHUB_BASE_URL}/${GITHUB_OWNER}/${GITHUB_REPO}"
  REG_TOKEN_URL="${GITHUB_API_URL}/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token"
  REMOVE_TOKEN_URL="${GITHUB_API_URL}/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/remove-token"

elif [[ "${RUNNER_SCOPE}" == "org" ]]; then
  RUNNER_URL="${GITHUB_BASE_URL}/${GITHUB_OWNER}"
  REG_TOKEN_URL="${GITHUB_API_URL}/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
  REMOVE_TOKEN_URL="${GITHUB_API_URL}/orgs/${GITHUB_OWNER}/actions/runners/remove-token"

else
  echo "RUNNER_SCOPE must be repo or org"
  exit 1
fi

cd /home/runner/actions-runner

github_post() {
  local url="$1"
  curl -fsSL -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_PAT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${url}"
}

cleanup() {
  echo "Cleanup: removing runner registration if possible"

  REMOVE_TOKEN="$(github_post "${REMOVE_TOKEN_URL}" | jq -r .token || true)"

  if [[ -n "${REMOVE_TOKEN:-}" && "${REMOVE_TOKEN}" != "null" ]]; then
    ./config.sh remove --unattended --token "${REMOVE_TOKEN}" || true
  fi
}

trap cleanup EXIT INT TERM

REG_TOKEN="$(github_post "${REG_TOKEN_URL}" | jq -r .token)"

CONFIG_ARGS=(
  --unattended
  --replace
  --url "${RUNNER_URL}"
  --token "${REG_TOKEN}"
  --name "${RUNNER_NAME}"
  --work "${RUNNER_WORKDIR}"
  --labels "${RUNNER_LABELS}"
)

if [[ "${EPHEMERAL,,}" == "true" ]]; then
  CONFIG_ARGS+=(--ephemeral)
fi

if [[ "${DISABLE_RUNNER_UPDATE,,}" == "true" ]]; then
  CONFIG_ARGS+=(--disableupdate)
fi

./config.sh "${CONFIG_ARGS[@]}"
./run.sh
