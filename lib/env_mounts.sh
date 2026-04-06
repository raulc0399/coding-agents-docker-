#!/usr/bin/env bash
# Populates the provided array with -v /dev/null:/workspace/<file>:ro flags for secret files found in $1

env_null_mounts() {
  local src_dir="$1"
  local -n mounts_ref="$2"
  local file
  local rel

  mounts_ref=()

  while IFS= read -r -d '' file; do
    rel="${file#"$src_dir"/}"
    mounts_ref+=("-v" "/dev/null:/workspace/${rel}:ro")
  done < <(
    find "$src_dir" -type f \
      \( \
        -name '.env' -o \
        -name '.env.*' -o \
        -name '.envrc' -o \
        -name '.npmrc' -o \
        -name '.yarnrc' -o \
        -name '.yarnrc.yml' -o \
        -name '.pypirc' -o \
        -name 'pip.conf' -o \
        -name 'auth.json' -o \
        -name '.pnpmfile.cjs' -o \
        -name '.sentryclirc' -o \
        -name '.vercelrc' \
      \) \
      -print0
  )

  # Per-project overrides: each line in .nullmounts is an additional path to mask
  local nullmounts_file="$src_dir/.nullmounts"
  if [[ -f "$nullmounts_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      mounts_ref+=("-v" "/dev/null:/workspace/${line}:ro")
    done < "$nullmounts_file"
  fi
}

agent_instructions_args() {
  local src_dir="$1"
  local container_path="$2"
  local -n args_ref="$3"
  local resolved_host_path=""

  args_ref=()

  resolve_agent_instructions_path "$src_dir" resolved_host_path || return 1

  if [[ -z "$resolved_host_path" ]]; then
    return 0
  fi

  args_ref+=("-v" "${resolved_host_path}:${container_path}:ro")
}

agent_config_mount_args() {
  local host_dir="$1"
  local container_dir="$2"
  local -n args_ref="$3"

  args_ref=()

  if [[ "$host_dir" == ~* ]]; then
    host_dir="${HOME}${host_dir#"~"}"
  fi

  mkdir -p "$host_dir"
  args_ref+=("-v" "${host_dir}:${container_dir}")
}

resolve_agent_instructions_path() {
  local src_dir="$1"
  local -n path_ref="$2"
  local host_path="${AGENTS_MD_PATH:-}"

  path_ref=""

  if [[ -z "$host_path" ]]; then
    return 0
  fi

  if [[ "$host_path" == ~* ]]; then
    host_path="${HOME}${host_path#"~"}"
  fi

  if [[ "$host_path" != /* ]]; then
    host_path="${src_dir}/${host_path}"
  fi

  if [[ ! -f "$host_path" ]]; then
    echo "AGENTS_MD_PATH file not found: ${host_path}" >&2
    return 1
  fi

  path_ref="$host_path"
}
