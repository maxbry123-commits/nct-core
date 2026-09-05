#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# MUSE Search — Zero-dependency TF-IDF semantic search
# Indexes: memory/ + .muse/ + MEMORIES.md + skills/
# Usage:  ./scripts/search.sh <query> [--top N] [--scope memory|roles|skills|all]
# ──────────────────────────────────────────────────────────────
set -euo pipefail

# ─── Config ───
MUSE_ROOT="${MUSE_ROOT:-$(pwd)}"
TOP_N=5
SCOPE="all"
QUERY=""
COLOR=true

# ─── Colors ───
if [[ -t 1 ]]; then
  BOLD='\033[1m' DIM='\033[2m' CYAN='\033[36m' GOLD='\033[33m'
  GREEN='\033[32m' RESET='\033[0m' UNDERLINE='\033[4m'
else
  BOLD='' DIM='' CYAN='' GOLD='' GREEN='' RESET='' UNDERLINE=''
fi

# ─── Usage ───
usage() {
  echo -e "${BOLD}🔍 MUSE Search${RESET} — Zero-dependency TF-IDF search"
  echo ""
  echo -e "  ${CYAN}Usage:${RESET}  search.sh <query> [options]"
  echo ""
  echo -e "  ${CYAN}Options:${RESET}"
  echo "    --top N           Show top N results (default: 5)"
  echo "    --scope SCOPE     Search scope: memory, roles, skills, all (default: all)"
  echo "    -h, --help        Show this help"
  echo ""
  echo -e "  ${CYAN}Examples:${RESET}"
  echo "    search.sh \"auth jwt oauth\""
  echo "    search.sh \"database migration\" --scope memory --top 3"
  echo "    search.sh \"testing strategy\" --scope skills"
  exit 0
}

# ─── Parse Args ───
while [[ $# -gt 0 ]]; do
  case "$1" in
    --top) TOP_N="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1"; usage ;;
    *) QUERY="${QUERY:+$QUERY }$1"; shift ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  echo -e "${BOLD}Error:${RESET} No search query provided."
  echo ""
  usage
fi

# ─── Collect Files ───
declare -a FILES=()

collect_files() {
  local scope="$1"

  if [[ "$scope" == "all" || "$scope" == "memory" ]]; then
    if [[ -d "$MUSE_ROOT/memory" ]]; then
      while IFS= read -r -d '' f; do FILES+=("$f"); done < <(find "$MUSE_ROOT/memory" -name '*.md' -print0 2>/dev/null)
    fi
    if [[ -f "$MUSE_ROOT/MEMORIES.md" ]]; then
      FILES+=("$MUSE_ROOT/MEMORIES.md")
    fi
  fi

  if [[ "$scope" == "all" || "$scope" == "roles" ]]; then
    if [[ -d "$MUSE_ROOT/.muse" ]]; then
      while IFS= read -r -d '' f; do FILES+=("$f"); done < <(find "$MUSE_ROOT/.muse" -name '*.md' -print0 2>/dev/null)
    fi
  fi

  if [[ "$scope" == "all" || "$scope" == "skills" ]]; then
    if [[ -d "$MUSE_ROOT/skills" ]]; then
      while IFS= read -r -d '' f; do FILES+=("$f"); done < <(find "$MUSE_ROOT/skills" -name 'SKILL.md' -print0 2>/dev/null)
    fi
    if [[ -d "$MUSE_ROOT/.agent/skills" ]]; then
      while IFS= read -r -d '' f; do FILES+=("$f"); done < <(find "$MUSE_ROOT/.agent/skills" -name 'SKILL.md' -print0 2>/dev/null)
    fi
  fi
}

collect_files "$SCOPE"

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo -e "${BOLD}No files found${RESET} in scope '${SCOPE}'. Make sure you're in a MUSE project root."
  exit 1
fi

# ─── TF-IDF Search (awk) ───
# 1. Tokenize query into terms
# 2. For each file: compute TF (term frequency) for each query term
# 3. Compute IDF (inverse document frequency) across all files
# 4. Score = sum(TF * IDF) for each file
# 5. Sort by score, show top N with context snippets

TOTAL_FILES=${#FILES[@]}

# Create a temp file list
TMPDIR="${TMPDIR:-/tmp}"
FILE_LIST=$(mktemp "$TMPDIR/muse_search_XXXXXX")
for f in "${FILES[@]}"; do echo "$f" >> "$FILE_LIST"; done

# Run TF-IDF scoring via awk
awk -v query="$QUERY" -v top_n="$TOP_N" -v total="$TOTAL_FILES" -v muse_root="$MUSE_ROOT" '
BEGIN {
  # Tokenize query (lowercase, split on spaces/punctuation)
  n_terms = split(tolower(query), query_terms, /[[:space:]+\/\-_]+/)

  # Read all files
  file_idx = 0
}

FNR == 1 {
  file_idx++
  filenames[file_idx] = FILENAME
  file_words[file_idx] = 0
  file_content[file_idx] = ""
}

{
  line = tolower($0)
  file_content[file_idx] = file_content[file_idx] "\n" $0

  # Count total words in this file
  n = split(line, words, /[^a-z0-9]+/)
  file_words[file_idx] += n

  # Count query term occurrences
  for (t = 1; t <= n_terms; t++) {
    term = query_terms[t]
    if (length(term) < 2) continue

    # Count occurrences of this term in this line
    temp = line
    count = 0
    while (idx = index(temp, term)) {
      count++
      temp = substr(temp, idx + length(term))
    }
    tf[file_idx, t] += count

    # Track which files contain this term
    if (count > 0) {
      doc_freq_seen[file_idx, t] = 1
    }
  }
}

END {
  n_files = file_idx

  # Compute IDF for each term
  for (t = 1; t <= n_terms; t++) {
    df = 0
    for (f = 1; f <= n_files; f++) {
      if (doc_freq_seen[f, t]) df++
    }
    if (df > 0)
      idf[t] = log(n_files / df) + 1
    else
      idf[t] = 0
  }

  # Compute TF-IDF score for each file
  for (f = 1; f <= n_files; f++) {
    score = 0
    total_w = file_words[f]
    if (total_w == 0) total_w = 1

    for (t = 1; t <= n_terms; t++) {
      term = query_terms[t]
      if (length(term) < 2) continue

      # Normalized TF
      raw_tf = tf[f, t] + 0
      norm_tf = raw_tf / total_w

      score += norm_tf * idf[t]
    }

    scores[f] = score
  }

  # Sort by score (simple selection sort for top N)
  for (i = 1; i <= top_n && i <= n_files; i++) {
    max_score = -1
    max_idx = -1
    for (f = 1; f <= n_files; f++) {
      if (scores[f] > max_score && !used[f]) {
        max_score = scores[f]
        max_idx = f
      }
    }

    if (max_idx == -1 || max_score <= 0) break

    used[max_idx] = 1

    # Get relative path
    fname = filenames[max_idx]
    sub(muse_root "/", "", fname)

    # Find best matching line (context snippet)
    split(file_content[max_idx], lines, "\n")
    best_line = ""
    best_line_score = 0
    best_line_num = 0
    for (l = 1; l <= length(lines); l++) {
      ls = 0
      line_lower = tolower(lines[l])
      for (t = 1; t <= n_terms; t++) {
        term = query_terms[t]
        if (length(term) < 2) continue
        if (index(line_lower, term)) ls += idf[t]
      }
      if (ls > best_line_score) {
        best_line_score = ls
        best_line = lines[l]
        best_line_num = l
      }
    }

    # Truncate snippet
    if (length(best_line) > 120) best_line = substr(best_line, 1, 117) "..."

    # Output: rank|score|file|line_num|snippet|total_words
    printf "%d|%.6f|%s|%d|%s|%d\n", i, max_score, fname, best_line_num, best_line, file_words[max_idx]
  }
}
' "${FILES[@]}" | while IFS='|' read -r rank score file line_num snippet words; do
  # Pretty print results
  if [[ "$rank" == "1" ]]; then
    echo -e "\n${BOLD}🔍 Search results for: ${GOLD}\"$QUERY\"${RESET}"
    echo -e "${DIM}   Indexed ${TOTAL_FILES} files in scope '${SCOPE}'${RESET}\n"
  fi

  # Score bar (visual)
  bar_len=$(echo "$score" | awk '{printf "%d", $1 * 500}')
  [[ $bar_len -gt 20 ]] && bar_len=20
  [[ $bar_len -lt 1 ]] && bar_len=1
  bar=$(printf '█%.0s' $(seq 1 "$bar_len"))

  echo -e "  ${BOLD}${GOLD}#${rank}${RESET}  ${UNDERLINE}${file}${RESET}${DIM}:${line_num}${RESET}"
  echo -e "      ${GREEN}${bar}${RESET} ${DIM}(score: ${score}, ${words} words)${RESET}"
  echo -e "      ${DIM}▸${RESET} ${snippet}"
  echo ""
done

# Cleanup
rm -f "$FILE_LIST"

# If no results printed
if [[ $(awk -v query="$QUERY" -v top_n="$TOP_N" -v total="$TOTAL_FILES" -v muse_root="$MUSE_ROOT" '
FNR==1{fi++} {line=tolower($0); for(i in qt){if(index(line,qt[i]))c++}} END{print c+0}
' qt="$(echo "$QUERY" | tr ' ' '\n')" "${FILES[@]}" 2>/dev/null) == "0" ]]; then
  echo -e "\n${BOLD}🔍 Search results for: ${GOLD}\"$QUERY\"${RESET}"
  echo -e "${DIM}   Indexed ${TOTAL_FILES} files in scope '${SCOPE}'${RESET}\n"
  echo -e "  ${DIM}No matching results found.${RESET}\n"
fi
