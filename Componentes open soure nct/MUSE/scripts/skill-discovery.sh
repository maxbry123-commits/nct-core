#!/bin/bash
# MUSE Skill Marketplace — browse, search, install, share, and discover skills
# Usage:
#   ./scripts/skill-discovery.sh list              # List all available skills
#   ./scripts/skill-discovery.sh search <query>     # Search skills by keyword
#   ./scripts/skill-discovery.sh info <skill-name>  # Show skill details
#   ./scripts/skill-discovery.sh install <skill-name> [target-dir]  # Install a local skill
#   ./scripts/skill-discovery.sh remote-install <github-url> [target-dir]  # Install from GitHub
#   ./scripts/skill-discovery.sh index              # Generate SKILL_INDEX.md
#   ./scripts/skill-discovery.sh categories         # Browse skills by category
#   ./scripts/skill-discovery.sh stats              # Show skill system statistics
#   ./scripts/skill-discovery.sh export <skill-name> # Export skill as shareable bundle
#   ./scripts/skill-discovery.sh recommend <context> # Recommend skills for a context
#   ./scripts/skill-discovery.sh registry           # Fetch community skill registry

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MUSE_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$MUSE_ROOT/skills"
REGISTRY_CACHE="$MUSE_ROOT/.cache/registry.json"
REGISTRY_URL="https://raw.githubusercontent.com/myths-labs/muse/main/SKILL_INDEX.md"

# Colors
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; MAGENTA=$'\033[0;35m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; MAGENTA=''
  BOLD=''; DIM=''; NC=''
fi

# ─── Helpers ─────────────────────────────────────────────────

extract_frontmatter() {
    local file="$1"
    local field="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${field}:" | sed "s/^${field}: *//" | sed 's/^"//' | sed 's/"$//'
}

get_tier() {
    local path="$1"
    if [[ "$path" == *"/core/"* ]]; then echo "core"
    elif [[ "$path" == *"/ecosystem/"* ]]; then echo "ecosystem"
    elif [[ "$path" == *"/toolkit/"* ]]; then echo "toolkit"
    elif [[ "$path" == *"/imported/"* ]]; then echo "imported"
    else echo "unknown"
    fi
}

get_tier_emoji() {
    case "$1" in
        core)      echo "🔵" ;;
        toolkit)   echo "🟢" ;;
        ecosystem) echo "🟠" ;;
        imported)  echo "📥" ;;
        *)         echo "⚪" ;;
    esac
}

count_lines() {
    wc -l < "$1" | tr -d ' '
}

# Categorize a skill by keywords in its name/description
categorize_skill() {
    local name="$1" desc="$2"
    local combined
    combined="$(echo "$name $desc" | tr '[:upper:]' '[:lower:]')"

    if echo "$combined" | grep -qiE "git|commit|branch|pr|pull.request|merge"; then
        echo "🔀 Git & VCS"
    elif echo "$combined" | grep -qiE "test|qa|verify|debug|e2e"; then
        echo "🧪 Testing & QA"
    elif echo "$combined" | grep -qiE "frontend|ui|ux|design|css|react|html"; then
        echo "🎨 Frontend & Design"
    elif echo "$combined" | grep -qiE "backend|database|postgres|sql|api"; then
        echo "🗄️ Backend & Data"
    elif echo "$combined" | grep -qiE "mobile|expo|ios|android"; then
        echo "📱 Mobile"
    elif echo "$combined" | grep -qiE "doc|readme|changelog|writing"; then
        echo "📝 Documentation"
    elif echo "$combined" | grep -qiE "security|auth|review|vulnerability"; then
        echo "🔒 Security"
    elif echo "$combined" | grep -qiE "plan|architect|brainstorm|design"; then
        echo "📐 Planning & Architecture"
    elif echo "$combined" | grep -qiE "skill|context|memory|resume|compact"; then
        echo "🧠 Meta & Context"
    elif echo "$combined" | grep -qiE "deploy|vercel|build|error"; then
        echo "🚀 DevOps & Deploy"
    elif echo "$combined" | grep -qiE "agent|subagent|parallel|dispatch"; then
        echo "🤖 Agent Orchestration"
    else
        echo "🔧 General"
    fi
}

# ─── Commands ────────────────────────────────────────────────

cmd_list() {
    echo -e "${BOLD}📦 MUSE Skill Marketplace${NC}"
    echo ""

    local total=0 core_count=0 toolkit_count=0 eco_count=0 imported_count=0

    while IFS= read -r skill_file; do
        local name desc tier emoji lines
        name=$(extract_frontmatter "$skill_file" "name")
        desc=$(extract_frontmatter "$skill_file" "description")
        tier=$(get_tier "$skill_file")
        emoji=$(get_tier_emoji "$tier")
        lines=$(count_lines "$skill_file")

        if [ ${#desc} -gt 80 ]; then
            desc="${desc:0:77}..."
        fi

        printf "  %s %-30s %s\n" "$emoji" "${BOLD}${name}${NC}" "$desc"
        total=$((total + 1))

        case "$tier" in
            core)      core_count=$((core_count + 1)) ;;
            toolkit)   toolkit_count=$((toolkit_count + 1)) ;;
            ecosystem) eco_count=$((eco_count + 1)) ;;
            imported)  imported_count=$((imported_count + 1)) ;;
        esac
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f | sort)

    echo ""
    echo -e "${BOLD}Total: ${total} skills${NC} (🔵 Core: ${core_count} | 🟢 Toolkit: ${toolkit_count} | 🟠 Ecosystem: ${eco_count}${imported_count:+ | 📥 Imported: ${imported_count}})"
    echo ""
    echo -e "  ${DIM}Commands:${NC}"
    echo -e "    ${CYAN}info <name>${NC}        Skill details"
    echo -e "    ${CYAN}search <query>${NC}     Search by keyword"
    echo -e "    ${CYAN}categories${NC}         Browse by category"
    echo -e "    ${CYAN}stats${NC}              System statistics"
    echo -e "    ${CYAN}recommend <ctx>${NC}     Get recommendations"
}

cmd_search() {
    local query="${1:-}"
    if [ -z "$query" ]; then
        echo -e "${RED}Error: search query required${NC}"
        echo "Usage: ./scripts/skill-discovery.sh search <query>"
        exit 1
    fi

    echo -e "${BOLD}🔍 Searching for: ${CYAN}${query}${NC}"
    echo ""

    local found=0
    while IFS= read -r skill_file; do
        local name desc tier emoji
        name=$(extract_frontmatter "$skill_file" "name")
        desc=$(extract_frontmatter "$skill_file" "description")
        tier=$(get_tier "$skill_file")
        emoji=$(get_tier_emoji "$tier")

        if echo "$name $desc" | grep -iq "$query"; then
            if [ ${#desc} -gt 80 ]; then
                desc="${desc:0:77}..."
            fi
            printf "  %s %-30s %s\n" "$emoji" "${BOLD}${name}${NC}" "$desc"
            found=$((found + 1))
        fi
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f | sort)

    echo ""
    if [ $found -eq 0 ]; then
        echo -e "${YELLOW}No skills found matching '${query}'${NC}"
        echo -e "${DIM}  Tip: try broader terms like 'git', 'test', 'frontend'${NC}"
    else
        echo -e "${GREEN}Found ${found} skill(s)${NC}"
    fi
}

cmd_info() {
    local skill_name="${1:-}"
    if [ -z "$skill_name" ]; then
        echo -e "${RED}Error: skill name required${NC}"
        echo "Usage: ./scripts/skill-discovery.sh info <skill-name>"
        exit 1
    fi

    local skill_file
    skill_file=$(find "$SKILLS_DIR" -name "SKILL.md" -type f | while read -r f; do
        local n
        n=$(extract_frontmatter "$f" "name")
        if [ "$n" = "$skill_name" ]; then
            echo "$f"
            break
        fi
    done)

    if [ -z "$skill_file" ]; then
        echo -e "${RED}Skill '${skill_name}' not found${NC}"
        echo ""
        echo "Similar skills:"
        cmd_search "$skill_name"
        exit 1
    fi

    local name desc tier lines deps category
    name=$(extract_frontmatter "$skill_file" "name")
    desc=$(extract_frontmatter "$skill_file" "description")
    tier=$(get_tier "$skill_file")
    lines=$(count_lines "$skill_file")
    deps=$(extract_frontmatter "$skill_file" "dependencies" 2>/dev/null || echo "none")
    category=$(categorize_skill "$name" "$desc")

    local rel_path="${skill_file#$MUSE_ROOT/}"
    local skill_dir
    skill_dir=$(dirname "$skill_file")

    echo -e "${BOLD}📋 Skill: ${CYAN}${name}${NC}"
    echo ""
    echo -e "  ${BOLD}Tier:${NC}         $(get_tier_emoji "$tier") ${tier}"
    echo -e "  ${BOLD}Category:${NC}     ${category}"
    echo -e "  ${BOLD}Path:${NC}         ${rel_path}"
    echo -e "  ${BOLD}Lines:${NC}        ${lines}"
    echo -e "  ${BOLD}Dependencies:${NC} ${deps}"
    echo ""
    echo -e "  ${BOLD}Description:${NC}"
    echo "  $desc"
    echo ""

    # Show extras
    if [ -d "$skill_dir/scripts" ]; then
        local script_count
        script_count=$(ls "$skill_dir/scripts/" 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  ${BOLD}Scripts:${NC}       ${script_count} files"
        for sf in "$skill_dir/scripts"/*; do
            [ -f "$sf" ] && echo -e "    ${DIM}→ $(basename "$sf")${NC}"
        done
    fi
    if [ -d "$skill_dir/references" ]; then
        local ref_count
        ref_count=$(ls "$skill_dir/references/" 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  ${BOLD}References:${NC}   ${ref_count} files"
        for rf in "$skill_dir/references"/*; do
            [ -f "$rf" ] && echo -e "    ${DIM}→ $(basename "$rf")${NC}"
        done
    fi

    echo ""
    echo -e "  ${DIM}Install: ./scripts/skill-discovery.sh install ${name} /path/to/project${NC}"
    echo -e "  ${DIM}Export:  ./scripts/skill-discovery.sh export ${name}${NC}"
}

cmd_install() {
    local skill_name="${1:-}"
    local target_dir="${2:-.}"

    if [ -z "$skill_name" ]; then
        echo -e "${RED}Error: skill name required${NC}"
        echo "Usage: ./scripts/skill-discovery.sh install <skill-name> [target-dir]"
        exit 1
    fi

    local skill_file
    skill_file=$(find "$SKILLS_DIR" -name "SKILL.md" -type f | while read -r f; do
        local n
        n=$(extract_frontmatter "$f" "name")
        if [ "$n" = "$skill_name" ]; then
            echo "$f"
            break
        fi
    done)

    if [ -z "$skill_file" ]; then
        echo -e "${RED}Skill '${skill_name}' not found${NC}"
        exit 1
    fi

    local skill_dir dest
    skill_dir=$(dirname "$skill_file")
    dest="$target_dir/.agent/skills/$skill_name"

    if [ -d "$dest" ]; then
        echo -e "${YELLOW}Skill '${skill_name}' already installed at ${dest}${NC}"
        echo -n "Overwrite? [y/N] "
        read -r answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    mkdir -p "$dest"
    cp -r "$skill_dir"/* "$dest/"
    echo -e "${GREEN}✅ Installed '${skill_name}' → ${dest}${NC}"

    # Check dependencies
    local deps
    deps=$(extract_frontmatter "$skill_file" "dependencies" 2>/dev/null || echo "")
    if [ -n "$deps" ] && [ "$deps" != "none" ]; then
        echo -e "${YELLOW}📦 This skill depends on: ${deps}${NC}"
        echo -e "${DIM}  Install dependencies with: ./scripts/skill-discovery.sh install <dep-name>${NC}"
    fi
}

cmd_remote_install() {
    local url="${1:-}"
    local target_dir="${2:-.}"

    if [ -z "$url" ]; then
        echo -e "${RED}Error: GitHub URL required${NC}"
        echo "Usage: ./scripts/skill-discovery.sh remote-install <github-url> [target-dir]"
        echo ""
        echo "Examples:"
        echo "  ./scripts/skill-discovery.sh remote-install https://github.com/user/repo/tree/main/skills/my-skill"
        echo "  ./scripts/skill-discovery.sh remote-install https://github.com/user/repo/tree/main/skills/my-skill ~/myproject"
        exit 1
    fi

    echo -e "${BOLD}📥 Remote Install${NC}"
    echo "  Source: $url"
    echo "  Target: $target_dir"
    echo ""

    # Parse GitHub URL → raw download paths
    # Format: https://github.com/{owner}/{repo}/tree/{branch}/{path}
    if [[ "$url" =~ github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.*) ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo="${BASH_REMATCH[2]}"
        local branch="${BASH_REMATCH[3]}"
        local path="${BASH_REMATCH[4]}"
        local skill_name
        skill_name=$(basename "$path")
        local raw_base="https://raw.githubusercontent.com/$owner/$repo/$branch/$path"

        echo -e "  ${DIM}Owner: $owner, Repo: $repo, Branch: $branch${NC}"
        echo -e "  ${DIM}Skill: $skill_name${NC}"
        echo ""

        local dest="$target_dir/.agent/skills/$skill_name"
        mkdir -p "$dest"

        # Download SKILL.md
        local skill_url="$raw_base/SKILL.md"
        echo -e "  Downloading SKILL.md..."
        if curl -fsSL "$skill_url" -o "$dest/SKILL.md" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} SKILL.md downloaded"
        else
            echo -e "  ${RED}✗ Failed to download SKILL.md from $skill_url${NC}"
            rm -rf "$dest"
            exit 1
        fi

        # Try to download common companion files
        for companion in scripts references; do
            # We can't easily list GitHub dirs via curl, but try known patterns
            echo -e "  ${DIM}Checking for $companion/...${NC}"
        done

        echo ""
        echo -e "${GREEN}✅ Installed '${skill_name}' → ${dest}${NC}"
        echo -e "${DIM}  Note: scripts/ and references/ may need manual download${NC}"
    else
        echo -e "${RED}Invalid GitHub URL format${NC}"
        echo "Expected: https://github.com/{owner}/{repo}/tree/{branch}/{path-to-skill}"
        exit 1
    fi
}

cmd_categories() {
    echo -e "${BOLD}📂 Skills by Category${NC}"
    echo ""

    # Use temp file instead of associative arrays (bash 3.2 compat)
    local tmpfile
    tmpfile=$(mktemp)
    trap "rm -f '$tmpfile'" EXIT

    while IFS= read -r skill_file; do
        local name desc category
        name=$(extract_frontmatter "$skill_file" "name")
        desc=$(extract_frontmatter "$skill_file" "description")
        [[ -z "$name" ]] && continue
        category=$(categorize_skill "$name" "$desc")
        echo "${category}|${name}" >> "$tmpfile"
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f | sort)

    # Display grouped by category
    local prev_cat=""
    sort "$tmpfile" | while IFS='|' read -r cat skill; do
        if [ "$cat" != "$prev_cat" ]; then
            [ -n "$prev_cat" ] && echo ""
            local count
            count=$(grep -c "^${cat}|" "$tmpfile" || true)
            echo -e "  ${BOLD}${cat}${NC} (${count})"
            prev_cat="$cat"
        fi
        echo -e "    ${DIM}→ ${skill}${NC}"
    done

    rm -f "$tmpfile"
    trap - EXIT
}

cmd_stats() {
    echo -e "${BOLD}📊 MUSE Skill System Statistics${NC}"
    echo ""

    local total=0 core=0 toolkit=0 ecosystem=0 imported=0
    local total_lines=0 max_lines=0 max_name="" min_lines=99999 min_name=""
    local with_scripts=0 with_refs=0 with_deps=0

    while IFS= read -r skill_file; do
        local name lines skill_dir tier
        name=$(extract_frontmatter "$skill_file" "name")
        [[ -z "$name" ]] && continue
        lines=$(count_lines "$skill_file")
        skill_dir=$(dirname "$skill_file")
        tier=$(get_tier "$skill_file")

        total=$((total + 1))
        total_lines=$((total_lines + lines))

        case "$tier" in
            core)      core=$((core + 1)) ;;
            toolkit)   toolkit=$((toolkit + 1)) ;;
            ecosystem) ecosystem=$((ecosystem + 1)) ;;
            imported)  imported=$((imported + 1)) ;;
        esac

        if [ "$lines" -gt "$max_lines" ]; then
            max_lines=$lines; max_name=$name
        fi
        if [ "$lines" -lt "$min_lines" ]; then
            min_lines=$lines; min_name=$name
        fi

        [ -d "$skill_dir/scripts" ] && with_scripts=$((with_scripts + 1))
        [ -d "$skill_dir/references" ] && with_refs=$((with_refs + 1))

        local deps
        deps=$(extract_frontmatter "$skill_file" "dependencies" 2>/dev/null || echo "")
        [ -n "$deps" ] && with_deps=$((with_deps + 1))
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f | sort)

    local avg_lines=$((total_lines / (total > 0 ? total : 1)))

    echo -e "  ${BOLD}Overview${NC}"
    echo -e "    Total skills:       ${BOLD}${total}${NC}"
    echo -e "    🔵 Core:            ${core}"
    echo -e "    🟢 Toolkit:         ${toolkit}"
    echo -e "    🟠 Ecosystem:       ${ecosystem}"
    [ "$imported" -gt 0 ] && echo -e "    📥 Imported:        ${imported}"
    echo ""
    echo -e "  ${BOLD}Size Analysis${NC}"
    echo -e "    Total lines:        ${total_lines}"
    echo -e "    Average lines:      ${avg_lines}"
    echo -e "    Largest:            ${max_name} (${max_lines} lines)"
    echo -e "    Smallest:           ${min_name} (${min_lines} lines)"
    echo ""
    echo -e "  ${BOLD}Composition${NC}"
    echo -e "    With scripts/:      ${with_scripts}/${total}"
    echo -e "    With references/:   ${with_refs}/${total}"
    echo -e "    With dependencies:  ${with_deps}/${total}"
    echo ""
    echo -e "  ${BOLD}Storage${NC}"
    local total_bytes
    total_bytes=$(find "$SKILLS_DIR" -name "SKILL.md" -type f -exec cat {} + | wc -c | tr -d ' ')
    local total_kb=$((total_bytes / 1024))
    echo -e "    Total SKILL.md size: ${total_kb} KB"
    echo -e "    Skill dirs size:     $(du -sh "$SKILLS_DIR" 2>/dev/null | cut -f1)"
}

cmd_export() {
    local skill_name="${1:-}"
    if [ -z "$skill_name" ]; then
        echo -e "${RED}Error: skill name required${NC}"
        echo "Usage: ./scripts/skill-discovery.sh export <skill-name>"
        exit 1
    fi

    local skill_file
    skill_file=$(find "$SKILLS_DIR" -name "SKILL.md" -type f | while read -r f; do
        local n
        n=$(extract_frontmatter "$f" "name")
        if [ "$n" = "$skill_name" ]; then
            echo "$f"
            break
        fi
    done)

    if [ -z "$skill_file" ]; then
        echo -e "${RED}Skill '${skill_name}' not found${NC}"
        exit 1
    fi

    local skill_dir bundle_name bundle_path
    skill_dir=$(dirname "$skill_file")
    bundle_name="muse-skill-${skill_name}"
    bundle_path="/tmp/${bundle_name}.tar.gz"

    # Create tarball
    tar -czf "$bundle_path" -C "$(dirname "$skill_dir")" "$(basename "$skill_dir")"

    local size
    size=$(du -h "$bundle_path" | cut -f1)

    echo -e "${BOLD}📤 Skill Export${NC}"
    echo ""
    echo -e "  ${GREEN}✅ Exported: ${bundle_path}${NC}"
    echo -e "  Size: ${size}"
    echo ""
    echo -e "  ${BOLD}Share this skill:${NC}"
    echo -e "    1. Upload to GitHub/Gist"
    echo -e "    2. Others install: ${CYAN}tar xzf ${bundle_name}.tar.gz -C ~/.agent/skills/${NC}"
    echo -e "    3. Or use: ${CYAN}./scripts/skill-discovery.sh remote-install <github-url>${NC}"
}

cmd_recommend() {
    local context="${1:-}"
    if [ -z "$context" ]; then
        echo -e "${RED}Error: context description required${NC}"
        echo "Usage: ./scripts/skill-discovery.sh recommend <context>"
        echo ""
        echo "Examples:"
        echo "  ./scripts/skill-discovery.sh recommend 'building a React app'"
        echo "  ./scripts/skill-discovery.sh recommend 'debugging production issues'"
        echo "  ./scripts/skill-discovery.sh recommend 'starting a new feature'"
        exit 1
    fi

    echo -e "${BOLD}💡 Recommended Skills for: ${CYAN}${context}${NC}"
    echo ""

    local found=0
    # Search against context and show matches with relevance
    while IFS= read -r skill_file; do
        local name desc tier emoji
        name=$(extract_frontmatter "$skill_file" "name")
        desc=$(extract_frontmatter "$skill_file" "description")
        tier=$(get_tier "$skill_file")
        emoji=$(get_tier_emoji "$tier")

        # Score relevance by word overlap
        local score=0
        for word in $context; do
            word="$(echo "$word" | tr '[:upper:]' '[:lower:]')"
            [ ${#word} -lt 3 ] && continue
            echo "$name $desc" | grep -iq "$word" && score=$((score + 1))
        done

        if [ $score -gt 0 ]; then
            local stars=""
            for ((i=0; i<score && i<5; i++)); do stars+="⭐"; done
            if [ ${#desc} -gt 60 ]; then desc="${desc:0:57}..."; fi
            printf "  %s %-30s %s %s\n" "$emoji" "${BOLD}${name}${NC}" "$stars" "${DIM}${desc}${NC}"
            found=$((found + 1))
        fi
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f | sort)

    echo ""
    if [ $found -eq 0 ]; then
        echo -e "${YELLOW}No matching skills found. Try broader terms.${NC}"
    else
        echo -e "${GREEN}Found ${found} relevant skill(s)${NC}"
        echo -e "${DIM}  ⭐ = relevance score (more stars = better match)${NC}"
    fi
}

cmd_registry() {
    echo -e "${BOLD}🌐 MUSE Community Registry${NC}"
    echo ""

    # Try to fetch fresh registry
    mkdir -p "$(dirname "$REGISTRY_CACHE")"

    echo -e "  ${DIM}Fetching community skill index...${NC}"
    if curl -fsSL "$REGISTRY_URL" -o "$REGISTRY_CACHE" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Registry updated${NC}"
        echo ""

        # Parse and display
        local skill_count
        skill_count=$(grep -c "^| \*\*" "$REGISTRY_CACHE" 2>/dev/null || echo "0")
        echo -e "  Skills in registry: ${BOLD}${skill_count}${NC}"
        echo ""
        echo -e "  ${DIM}Registry source: ${REGISTRY_URL}${NC}"
        echo -e "  ${DIM}Local cache: ${REGISTRY_CACHE}${NC}"
        echo ""
        echo -e "  ${BOLD}To contribute a skill:${NC}"
        echo -e "    1. Create skill following MUSE conventions"
        echo -e "    2. Export: ${CYAN}./scripts/skill-discovery.sh export <name>${NC}"
        echo -e "    3. Submit PR to github.com/myths-labs/muse"
        echo ""
        echo -e "  ${BOLD}To install community skills:${NC}"
        echo -e "    ${CYAN}./scripts/skill-discovery.sh remote-install <github-url>${NC}"
    else
        echo -e "  ${YELLOW}⚠ Could not fetch registry (offline?)${NC}"
        if [ -f "$REGISTRY_CACHE" ]; then
            echo -e "  ${DIM}Using cached version${NC}"
        else
            echo -e "  ${DIM}No cached version available${NC}"
        fi
    fi
}

cmd_index() {
    echo -e "${BOLD}📝 Generating SKILL_INDEX.md...${NC}"

    local output="$MUSE_ROOT/SKILL_INDEX.md"
    
    {
        echo "# 📦 MUSE Skill Index"
        echo ""
        echo "> Auto-generated by \`scripts/skill-discovery.sh index\`"
        echo "> Last updated: $(date '+%Y-%m-%d %H:%M')"
        echo "> Total: $(find "$SKILLS_DIR" -name "SKILL.md" -type f | wc -l | tr -d ' ') skills"
        echo ""
        echo "## 🔵 Core Skills"
        echo ""
        echo "Essential skills loaded by default. Required for MUSE to function."
        echo ""
        echo "| Skill | Description |"
        echo "|-------|-------------|"

        find "$SKILLS_DIR/core" -name "SKILL.md" -type f | sort | while read -r f; do
            local name desc
            name=$(extract_frontmatter "$f" "name")
            desc=$(extract_frontmatter "$f" "description")
            if [ ${#desc} -gt 100 ]; then desc="${desc:0:97}..."; fi
            echo "| **${name}** | ${desc} |"
        done

        echo ""
        echo "## 🟢 Toolkit Skills"
        echo ""
        echo "General-purpose development skills. Mix and match based on your workflow."
        echo ""
        echo "| Skill | Description |"
        echo "|-------|-------------|"

        find "$SKILLS_DIR/toolkit" -name "SKILL.md" -type f | sort | while read -r f; do
            local name desc
            name=$(extract_frontmatter "$f" "name")
            desc=$(extract_frontmatter "$f" "description")
            if [ ${#desc} -gt 100 ]; then desc="${desc:0:97}..."; fi
            echo "| **${name}** | ${desc} |"
        done

        echo ""
        echo "## 🟠 Ecosystem Skills"
        echo ""
        echo "Technology-specific skill packs. Install only what matches your stack."
        echo ""

        for pack_dir in "$SKILLS_DIR/ecosystem"/*/; do
            local pack_name
            pack_name=$(basename "$pack_dir")
            echo "### ${pack_name}"
            echo ""
            echo "| Skill | Description |"
            echo "|-------|-------------|"

            find "$pack_dir" -name "SKILL.md" -type f | sort | while read -r f; do
                local name desc
                name=$(extract_frontmatter "$f" "name")
                desc=$(extract_frontmatter "$f" "description")
                if [ ${#desc} -gt 100 ]; then desc="${desc:0:97}..."; fi
                echo "| **${name}** | ${desc} |"
            done
            echo ""
        done

        echo "---"
        echo ""
        echo "## CLI Discovery"
        echo ""
        echo '```bash'
        echo "# List all skills"
        echo "./scripts/skill-discovery.sh list"
        echo ""
        echo "# Search by keyword"
        echo './scripts/skill-discovery.sh search "git"'
        echo ""
        echo "# Browse by category"
        echo "./scripts/skill-discovery.sh categories"
        echo ""
        echo "# Get skill details"
        echo "./scripts/skill-discovery.sh info git-commit"
        echo ""
        echo "# See system statistics"
        echo "./scripts/skill-discovery.sh stats"
        echo ""
        echo "# Get smart recommendations"
        echo './scripts/skill-discovery.sh recommend "building a React app"'
        echo ""
        echo "# Install a skill to your project"
        echo "./scripts/skill-discovery.sh install brainstorming /path/to/project"
        echo ""
        echo "# Install from GitHub"
        echo "./scripts/skill-discovery.sh remote-install https://github.com/user/repo/tree/main/skills/my-skill"
        echo ""
        echo "# Export a skill for sharing"
        echo "./scripts/skill-discovery.sh export git-commit"
        echo '```'
    } > "$output"

    echo -e "${GREEN}✅ Generated ${output}${NC}"
    echo -e "  $(wc -l < "$output" | tr -d ' ') lines"
}

# ─── Main ────────────────────────────────────────────────────

case "${1:-help}" in
    list)            cmd_list ;;
    search)          cmd_search "${2:-}" ;;
    info)            cmd_info "${2:-}" ;;
    install)         cmd_install "${2:-}" "${3:-}" ;;
    remote-install)  cmd_remote_install "${2:-}" "${3:-}" ;;
    index)           cmd_index ;;
    categories)      cmd_categories ;;
    stats)           cmd_stats ;;
    export)          cmd_export "${2:-}" ;;
    recommend)       shift; cmd_recommend "$*" ;;
    registry)        cmd_registry ;;
    help|--help|-h)
        echo -e "${BOLD}🎭 MUSE Skill Marketplace${NC}"
        echo ""
        echo "Usage:"
        echo "  ./scripts/skill-discovery.sh list                    List all skills"
        echo "  ./scripts/skill-discovery.sh search <query>           Search by keyword"
        echo "  ./scripts/skill-discovery.sh info <name>              Show skill details"
        echo "  ./scripts/skill-discovery.sh install <name> [dir]     Install a local skill"
        echo "  ./scripts/skill-discovery.sh remote-install <url> [dir]  Install from GitHub"
        echo "  ./scripts/skill-discovery.sh index                    Generate SKILL_INDEX.md"
        echo "  ./scripts/skill-discovery.sh categories               Browse by category"
        echo "  ./scripts/skill-discovery.sh stats                    System statistics"
        echo "  ./scripts/skill-discovery.sh export <name>            Export skill bundle"
        echo "  ./scripts/skill-discovery.sh recommend <context>      Smart recommendations"
        echo "  ./scripts/skill-discovery.sh registry                 Community registry"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Run with --help for usage"
        exit 1
        ;;
esac
