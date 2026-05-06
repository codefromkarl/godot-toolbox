#!/usr/bin/env bash
# quickstart.sh — Interactive deployment wizard for godot-toolbox
# Reads packs.manifest.json, displays categorized pack list, resolves
# dependencies (BFS), detects conflicts, then calls bootstrap_toolbox_project.sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_PATH="${REPO_ROOT}/packs.manifest.json"
BOOTSTRAP="${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh"

# ── Colors ──────────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

# ── State ───────────────────────────────────────────────────────────────
DEST=""
PACKS_CSV=""
AUTO_DEPS="0"
NON_INTERACTIVE="0"

# ── Argument parsing ────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
Usage:
  ./scripts/quickstart.sh <destination> [--packs=...] [--auto-deps] [--non-interactive]
  ./scripts/quickstart.sh --list-packs

Options:
  --packs=<csv>        Comma-separated pack IDs (skips interactive selection)
  --auto-deps          Automatically resolve dependencies
  --non-interactive    Same as --packs + --auto-deps (for CI)
  --list-packs         Print categorized pack table and exit
  -h, --help           Show this help
EOF
}

LIST_ONLY="0"

for arg in "$@"; do
  case "$arg" in
    --packs=*)
      PACKS_CSV="${arg#--packs=}"
      ;;
    --auto-deps)
      AUTO_DEPS="1"
      ;;
    --non-interactive)
      NON_INTERACTIVE="1"
      AUTO_DEPS="1"
      ;;
    --list-packs)
      LIST_ONLY="1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${DEST}" ]]; then
        DEST="$arg"
      else
        echo "[quickstart] ERROR: unexpected argument: ${arg}" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

# ── Dependency checks ───────────────────────────────────────────────────
check_deps() {
  local missing=()
  command -v jq &>/dev/null || missing+=("jq")
  command -v python3 &>/dev/null || missing+=("python3")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}[quickstart] ERROR: missing dependencies: ${missing[*]}${RESET}" >&2
    echo "Install with: apt install ${missing[*]}  (or brew install ${missing[*]})" >&2
    exit 1
  fi

  if [[ ! -f "${MANIFEST_PATH}" ]]; then
    echo -e "${RED}[quickstart] ERROR: ${MANIFEST_PATH} not found.${RESET}" >&2
    exit 1
  fi
}

# ── Pack metadata helpers ───────────────────────────────────────────────
# Returns the value of a field for a given pack ID.
pack_field() {
  local pack_id="$1" field="$2"
  jq -r --arg p "$pack_id" --arg f "$field" \
    '.packs[] | select(.id==$p) | .[$f]' "$MANIFEST_PATH"
}

# Returns plugin names as comma-separated string for a pack.
pack_plugins_csv() {
  local pack_id="$1"
  jq -r --arg p "$pack_id" \
    '.packs[] | select(.id==$p) | (.plugins // []) | join(", ")' "$MANIFEST_PATH"
}

# Returns requires array as newline-separated list.
pack_requires() {
  local pack_id="$1"
  jq -r --arg p "$pack_id" \
    '.packs[] | select(.id==$p) | (.requires // [])[]' "$MANIFEST_PATH"
}

# Returns conflicts array as newline-separated list.
pack_conflicts() {
  local pack_id="$1"
  jq -r --arg p "$pack_id" \
    '.packs[] | select(.id==$p) | (.conflicts // [])[]' "$MANIFEST_PATH"
}

# Returns selection_rationale for a pack.
pack_rationale() {
  local pack_id="$1"
  jq -r --arg p "$pack_id" \
    '.packs[] | select(.id==$p) | .selection_rationale // ""' "$MANIFEST_PATH"
}

# ── Pack categories (display order) ─────────────────────────────────────
# Each entry: "category_name|pack_id1,pack_id2,..."
CATEGORIES=(
  "开发工具|validation,debug,stateful,juice,ai-behavior,save-state-lite"
  "输入 & 自动化|input,automation"
  "架构核心|flow-core,simulation-core,data-core,save-core,rules-events-core,ui-game-shell,flow-test-kit,ai-testing"
  "游戏系统（Vendor）|inventory,quest,dialogue"
  "RPG 扩展|rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,rpg-art-demo"
)

# ── List packs ──────────────────────────────────────────────────────────
list_packs() {
  echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║  godot-toolbox Pack 目录                 ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
  echo ""

  local cat_idx=1
  for cat_entry in "${CATEGORIES[@]}"; do
    local cat_name="${cat_entry%%|*}"
    local cat_packs="${cat_entry#*|}"

    echo -e "${CYAN}${BOLD}[${cat_idx}] ${cat_name}${RESET}"

    IFS=',' read -ra packs_arr <<< "$cat_packs"
    for pid in "${packs_arr[@]}"; do
      local plugins
      plugins="$(pack_plugins_csv "$pid")"
      local rationale
      rationale="$(pack_rationale "$pid")"
      local requires
      requires="$(pack_requires "$pid" | { grep -v '^base$' || true; } | tr '\n' ',' | sed 's/,$//')"

      local label="${pid}"
      [[ -n "${plugins}" ]] && label="${pid}  ${DIM}${plugins}${RESET}"
      [[ -n "${requires}" ]] && label="${label}  ${DIM}(需 ${requires})${RESET}"

      # Conflict warning
      local conflicts
      conflicts="$(pack_conflicts "$pid")"
      if [[ -n "${conflicts}" ]]; then
        label="${label}  ${YELLOW}⚠️ 冲突 ${conflicts}${RESET}"
      fi

      echo -e "  • ${label}"
    done

    echo ""
    cat_idx=$((cat_idx + 1))
  done
}

# ── BFS dependency resolution ───────────────────────────────────────────
resolve_deps() {
  local input_csv="$1"
  local -a queue=()
  local -a resolved=()

  # Seed queue from input
  IFS=',' read -ra input_packs <<< "$input_csv"
  for p in "${input_packs[@]}"; do
    p="$(echo "$p" | xargs)"  # trim
    [[ -n "$p" ]] && queue+=("$p")
  done

  while [[ ${#queue[@]} -gt 0 ]]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")

    # Check if already resolved
    local found="0"
    for r in "${resolved[@]+"${resolved[@]}"}"; do
      [[ "$r" == "$current" ]] && found="1" && break
    done

    if [[ "$found" == "0" ]]; then
      resolved+=("$current")

      # Collect requires from manifest
      local deps
      deps="$(pack_requires "$current")"
      while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        local dep_found="0"
        for r in "${resolved[@]+"${resolved[@]}"}"; do
          [[ "$r" == "$dep" ]] && dep_found="1" && break
        done
        for q in "${queue[@]+"${queue[@]}"}"; do
          [[ "$q" == "$dep" ]] && dep_found="1" && break
        done
        [[ "$dep_found" == "0" ]] && queue+=("$dep")
      done <<< "$deps"
    fi
  done

  # Output as CSV
  local result=""
  for r in "${resolved[@]}"; do
    [[ -n "$result" ]] && result="${result},${r}" || result="$r"
  done
  echo "$result"
}

# ── Conflict detection ──────────────────────────────────────────────────
detect_conflicts() {
  local csv="$1"
  local -a conflict_pairs=()

  IFS=',' read -ra packs_arr <<< "$csv"
  for pid in "${packs_arr[@]}"; do
    local conflicts
    conflicts="$(pack_conflicts "$pid")"
    while IFS= read -r conflict_id; do
      [[ -z "$conflict_id" ]] && continue
      # Check if the conflicting pack is also in the list
      for p in "${packs_arr[@]}"; do
        if [[ "$p" == "$conflict_id" ]]; then
          conflict_pairs+=("${pid} ↔ ${conflict_id}")
        fi
      done
    done <<< "$conflicts"
  done

  if [[ ${#conflict_pairs[@]} -gt 0 ]]; then
    echo -e "\n${RED}${BOLD}⚠️  检测到冲突：${RESET}"
    for pair in "${conflict_pairs[@]}"; do
      echo -e "  ${RED}• ${pair}${RESET}"
    done
    echo ""
    echo -e "${YELLOW}请移除其中一个冲突 pack 后重试。${RESET}"
    return 1
  fi
  return 0
}

# ── Interactive wizard ──────────────────────────────────────────────────
interactive_select() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║  godot-toolbox 一键部署向导               ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
  echo ""

  local cat_idx=1
  for cat_entry in "${CATEGORIES[@]}"; do
    local cat_name="${cat_entry%%|*}"
    local cat_packs="${cat_entry#*|}"

    echo -e "${CYAN}${BOLD}[${cat_idx}] ${cat_name}${RESET}"

    IFS=',' read -ra packs_arr <<< "$cat_packs"
    for pid in "${packs_arr[@]}"; do
      local plugins
      plugins="$(pack_plugins_csv "$pid")"
      local rationale
      rationale="$(pack_rationale "$pid")"
      local requires
      requires="$(pack_requires "$pid" | { grep -v '^base$' || true; } | tr '\n' ',' | sed 's/,$//')"

      local line="  ${BOLD}${pid}${RESET}"
      [[ -n "${plugins}" ]] && line="${line}  ${plugins}"
      [[ -n "${requires}" ]] && line="${line}  ${DIM}(需 ${requires})${RESET}"

      local conflicts
      conflicts="$(pack_conflicts "$pid")"
      if [[ -n "${conflicts}" ]]; then
        line="${line}  ${YELLOW}⚠️ 冲突 ${conflicts}${RESET}"
      fi

      echo -e "$line"
    done

    echo ""
    cat_idx=$((cat_idx + 1))
  done

  echo -e "──────────────────────────────────────────"
  echo -e "请输入要启用的 pack（逗号分隔，如: validation,debug,rpg-core）:"
  echo -n "> "

  local selection
  read -r selection

  # Normalize: trim spaces, lower-case
  selection="$(echo "$selection" | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/ //g')"

  if [[ -z "$selection" ]]; then
    echo -e "${YELLOW}未选择任何 pack，仅部署基线模板。${RESET}"
    selection=""
  fi

  echo "$selection"
}

# ── Main ────────────────────────────────────────────────────────────────
main() {
  check_deps

  # --list-packs mode
  if [[ "$LIST_ONLY" == "1" ]]; then
    list_packs
    exit 0
  fi

  # Validate destination
  if [[ -z "${DEST}" ]]; then
    echo -e "${RED}[quickstart] ERROR: destination path is required.${RESET}" >&2
    usage
    exit 1
  fi

  # Resolve to absolute path
  DEST="$(cd "$(dirname "${DEST}")" 2>/dev/null && pwd)/$(basename "${DEST}")" || \
    DEST="$(pwd)/$(basename "${DEST}")"

  # ── Select packs ──────────────────────────────────────────────────────
  local selected="$PACKS_CSV"

  if [[ "${NON_INTERACTIVE}" == "0" && -z "${PACKS_CSV}" ]]; then
    selected="$(interactive_select)"
  fi

  # ── Resolve dependencies ──────────────────────────────────────────────
  local resolved=""
  if [[ -n "${selected}" ]]; then
    if [[ "${AUTO_DEPS}" == "1" || "${NON_INTERACTIVE}" == "0" ]]; then
      echo ""
      echo -e "${BOLD}自动解析依赖...${RESET}"
      resolved="$(resolve_deps "${selected}")"

      # Show what was auto-added
      IFS=',' read -ra orig_arr <<< "$selected"
      IFS=',' read -ra resolved_arr <<< "$resolved"
      for r in "${resolved_arr[@]}"; do
        local is_orig="0"
        for o in "${orig_arr[@]}"; do
          [[ "$o" == "$r" ]] && is_orig="1" && break
        done
        if [[ "$is_orig" == "0" ]]; then
          echo -e "  ${GREEN}+ ${r}${RESET}（自动添加）"
        fi
      done
    else
      resolved="${selected}"
    fi
  fi

  # ── Detect conflicts ──────────────────────────────────────────────────
  if [[ -n "${resolved}" ]]; then
    if ! detect_conflicts "${resolved}"; then
      exit 1
    fi
  fi

  # ── Summary & confirm ─────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}最终启用 packs:${RESET}"
  if [[ -z "${resolved}" ]]; then
    echo -e "  ${DIM}(仅基线 base)${RESET}"
  else
    echo -e "  ${GREEN}${resolved}${RESET}"
  fi
  echo ""

  if [[ "${NON_INTERACTIVE}" == "0" ]]; then
    echo -e "确认部署到 ${BOLD}${DEST}${RESET}? [Y/n]"
    echo -n "> "
    local confirm
    read -r confirm
    case "${confirm}" in
      n|N|no|No|NO)
        echo -e "${YELLOW}已取消。${RESET}"
        exit 0
        ;;
    esac
  fi

  # ── Execute bootstrap ─────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}调用 bootstrap_toolbox_project.sh ...${RESET}"
  echo ""

  local bootstrap_args=("${DEST}")
  [[ -n "${resolved}" ]] && bootstrap_args+=("--packs=${resolved}")
  bootstrap_args+=("--force")

  "${BOOTSTRAP}" "${bootstrap_args[@]}"

  echo ""
  echo -e "${GREEN}${BOLD}✓ 部署完成！${RESET}"
  echo -e "项目路径: ${DEST}"
  if [[ -n "${resolved}" ]]; then
    echo -e "启用 packs: ${resolved}"
  fi
}

main "$@"
