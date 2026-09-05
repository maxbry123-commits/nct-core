#!/bin/bash
# muse-agents-generator: AGENTS.md Compatibility Layer
# Auto-generates a master AGENTS.md file from MUSE project components.
#
# Usage:
#   ./scripts/generate-agents-md.sh [--target /path/to/output]

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: ./scripts/generate-agents-md.sh [--target <dir>]"
      echo "Auto-generates an AGENTS.md file from MUSE components."
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"
mkdir -p "$TARGET_DIR"
OUTFILE="$TARGET_DIR/AGENTS.md"

echo -e "${BLUE}🎭 MUSE -> AGENTS.md Generator${NC}"
echo "Compiling components..."

# Initialize file
cat > "$OUTFILE" << 'EOF'
# AGENTS.md
> Auto-generated from MUSE (The AI Coding Governance System)
> This file acts as a compatibility layer for tools expecting a single AGENTS.md file.

EOF

# 1. Project Constitution
if [ -f "CLAUDE.md" ]; then
  echo "  + Adding Constitution (CLAUDE.md)"
  echo "## Core Constitution" >> "$OUTFILE"
  cat "CLAUDE.md" >> "$OUTFILE"
  echo -e "\n---\n" >> "$OUTFILE"
elif [ -f "GEMINI.md" ]; then
  echo "  + Adding Constitution (GEMINI.md)"
  echo "## Core Constitution" >> "$OUTFILE"
  cat "GEMINI.md" >> "$OUTFILE"
  echo -e "\n---\n" >> "$OUTFILE"
fi

# 2. Roles
if [ -d ".muse" ]; then
  echo "## Roles" >> "$OUTFILE"
  for role_file in .muse/*.md; do
    [ -e "$role_file" ] || continue
    role_name=$(basename "$role_file" .md)
    echo "  + Adding Role: $role_name"
    
    role_upper=$(echo "$role_name" | tr '[:lower:]' '[:upper:]')
    echo "### Role: ${role_upper}" >> "$OUTFILE"
    
    # Extract L0 header
    l0_line=$(head -n 1 "$role_file")
    if [[ "$l0_line" == "<!-- L0:"* ]]; then
      echo "**Current State**: \`${l0_line}\`" >> "$OUTFILE"
      echo "" >> "$OUTFILE"
    fi
    
    # Add body (skipping L0)
    tail -n +2 "$role_file" >> "$OUTFILE"
    echo -e "\n" >> "$OUTFILE"
  done
  echo -e "---\n" >> "$OUTFILE"
fi

# 3. Core Skills needed for fallback
echo "## Core Skills" >> "$OUTFILE"
SKILLS_DIR="$REPO_ROOT/skills/core"
if [ -d "$SKILLS_DIR" ]; then
  for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
    [ -e "$skill_file" ] || continue
    
    # Extract name from yaml frontmatter
    skill_name=$(awk '/^name: /{print $2}' "$skill_file" | tr -d '\r')
    [ -z "$skill_name" ] && skill_name=$(basename "$(dirname "$skill_file")")
    
    echo "  + Adding Skill: $skill_name"
    echo "### Skill: $skill_name" >> "$OUTFILE"
    
    # Extract body (skip yaml frontmatter)
    awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$skill_file" >> "$OUTFILE"
    echo -e "\n" >> "$OUTFILE"
  done
fi

echo -e "\n${GREEN}✓ Generated: $OUTFILE${NC}"
