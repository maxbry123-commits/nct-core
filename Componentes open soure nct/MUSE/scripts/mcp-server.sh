#!/usr/bin/env bash
# MUSE MCP Server — Zero-dependency MCP server for MUSE AI Memory OS
# Protocol: JSON-RPC 2.0 over stdio (stdin/stdout)
# Dependencies: bash 4+, jq
# Usage: echo '{"jsonrpc":"2.0","id":1,"method":"initialize",...}' | ./mcp-server.sh --project-root /path/to/project

set -euo pipefail

# ─── Constants ───
SERVER_NAME="muse-memory-os"
SERVER_VERSION="1.0.0"
PROTOCOL_VERSION="2024-11-05"
MUSE_DIR=".muse"
MEMORY_DIR="memory"

# ─── Argument Parsing ───
PROJECT_ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root) PROJECT_ROOT="$2"; shift 2 ;;
    --help|-h)
      echo "MUSE MCP Server — AI Memory OS integration"
      echo ""
      echo "Usage: mcp-server.sh --project-root /path/to/project"
      echo ""
      echo "Options:"
      echo "  --project-root PATH   Project root containing .muse/ directory"
      echo "  --help, -h            Show this help"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Auto-detect project root if not specified
if [[ -z "$PROJECT_ROOT" ]]; then
  # Walk up from script location
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [[ -d "$dir/$MUSE_DIR" ]]; then
    PROJECT_ROOT="$dir"
  else
    PROJECT_ROOT="$(pwd)"
  fi
fi

# Validate project root
if [[ ! -d "$PROJECT_ROOT/$MUSE_DIR" ]]; then
  echo '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"No .muse/ directory found. Run MUSE setup first."}}' >&2
  exit 1
fi

# Check jq dependency
if ! command -v jq &>/dev/null; then
  echo '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"jq is required. Install: brew install jq (macOS) or apt install jq (Linux)"}}' >&2
  exit 1
fi

# ─── Logging (stderr only, stdout is protocol) ───
log() { echo "[muse-mcp] $*" >&2; }

# ─── Security: Validate role name (prevent path traversal) ───
validate_role_name() {
  local role="$1"
  if [[ "$role" =~ [/\\] ]] || [[ "$role" == *".."* ]] || [[ -z "$role" ]]; then
    return 1
  fi
  return 0
}

# ─── JSON Response Helpers ───
json_result() {
  local id="$1" content="$2"
  jq -nc --arg id "$id" --arg content "$content" '{
    jsonrpc: "2.0",
    id: ($id | tonumber),
    result: {
      content: [{type: "text", text: $content}]
    }
  }'
}

json_error() {
  local id="$1" code="$2" message="$3"
  jq -nc --arg id "$id" --argjson code "$code" --arg msg "$message" '{
    jsonrpc: "2.0",
    id: ($id | tonumber),
    error: {code: $code, message: $msg}
  }'
}

# ─── Tool Definitions ───
TOOLS_JSON='[
  {
    "name": "muse_get_status",
    "description": "Get project status by reading all L0 header lines from MUSE role files. Returns a concise (~400 token) overview of the entire project state across all roles (build, growth, qa, gm, etc).",
    "inputSchema": {
      "type": "object",
      "properties": {},
      "required": []
    }
  },
  {
    "name": "muse_list_roles",
    "description": "List all available MUSE role files in the project. Returns role names and their L0 status summaries.",
    "inputSchema": {
      "type": "object",
      "properties": {},
      "required": []
    }
  },
  {
    "name": "muse_get_role",
    "description": "Read the full content of a specific MUSE role file (L1 deep read). Use muse_get_status first for an overview, then this for details.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "role": {
          "type": "string",
          "description": "Role file name without extension (e.g., build, growth, qa, gm, strategy)"
        }
      },
      "required": ["role"]
    }
  },
  {
    "name": "muse_send_directive",
    "description": "Send a cross-role directive using the MUSE directive protocol (📡). Creates a directive entry in the specified role file.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "target_role": {
          "type": "string",
          "description": "Target role file name (e.g., build, growth)"
        },
        "directive_id": {
          "type": "string",
          "description": "Directive ID (e.g., S042)"
        },
        "title": {
          "type": "string",
          "description": "One-line directive title"
        },
        "body": {
          "type": "string",
          "description": "Directive body content"
        }
      },
      "required": ["target_role", "directive_id", "title", "body"]
    }
  },
  {
    "name": "muse_write_memory",
    "description": "Append content to today'\''s daily memory log (memory/YYYY-MM-DD.md). Creates the file if it doesn'\''t exist.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "content": {
          "type": "string",
          "description": "Content to append to today'\''s memory file"
        },
        "section": {
          "type": "string",
          "description": "Optional section header to add before content (e.g., Build Session)"
        }
      },
      "required": ["content"]
    }
  },
  {
    "name": "muse_search_memory",
    "description": "Search across MUSE memory files (memory/*.md) and long-term knowledge (MEMORIES.md) for a query string.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "query": {
          "type": "string",
          "description": "Search query (grep pattern)"
        },
        "scope": {
          "type": "string",
          "enum": ["all", "recent", "longterm"],
          "description": "Search scope: all (memory/ + MEMORIES.md), recent (last 3 days memory/), longterm (MEMORIES.md only). Default: all"
        }
      },
      "required": ["query"]
    }
  }
]'

# ─── Tool Handlers ───

handle_muse_get_status() {
  local output=""
  for f in "$PROJECT_ROOT/$MUSE_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    local basename
    basename="$(basename "$f" .md)"
    local l0
    l0="$(head -1 "$f" | grep -o '<!-- L0:.*-->' | sed 's/<!-- L0: //;s/ -->//' || echo 'no L0')"
    output+="[$basename] $l0"$'\n'
  done
  [[ -z "$output" ]] && output="No role files found in $MUSE_DIR/"
  echo "$output"
}

handle_muse_list_roles() {
  local output=""
  for f in "$PROJECT_ROOT/$MUSE_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    local basename
    basename="$(basename "$f" .md)"
    local lines
    lines="$(wc -l < "$f" | tr -d ' ')"
    local l0
    l0="$(head -1 "$f" | grep -o '<!-- L0:.*-->' | sed 's/<!-- L0: //;s/ -->//' || echo '')"
    output+="- **$basename** (${lines} lines): $l0"$'\n'
  done
  [[ -z "$output" ]] && output="No role files found."
  echo "$output"
}

handle_muse_get_role() {
  local role="$1"
  if ! validate_role_name "$role"; then
    echo "ERROR: Invalid role name '$role'. Use alphanumeric names like: build, growth, qa, gm"
    return 1
  fi
  local filepath="$PROJECT_ROOT/$MUSE_DIR/${role}.md"
  if [[ ! -f "$filepath" ]]; then
    echo "ERROR: Role file '$role.md' not found. Available roles:"
    ls "$PROJECT_ROOT/$MUSE_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  - /'
    return 1
  fi
  cat "$filepath"
}

handle_muse_send_directive() {
  local target_role="$1" directive_id="$2" title="$3" body="$4"
  if ! validate_role_name "$target_role"; then
    echo "ERROR: Invalid target role '$target_role'"
    return 1
  fi
  local filepath="$PROJECT_ROOT/$MUSE_DIR/${target_role}.md"
  if [[ ! -f "$filepath" ]]; then
    echo "ERROR: Target role file '$target_role.md' not found"
    return 1
  fi
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M')"
  local directive
  directive="$(printf '\n### 📡 %s→%s (%s) — 🟡 待处理\n\n> %s\n\n%s\n' \
    "$directive_id" "$(echo "$target_role" | tr '[:lower:]' '[:upper:]')" \
    "$timestamp" "$title" "$body")"

  # Append to the role file
  echo "$directive" >> "$filepath"
  echo "✅ Directive $directive_id sent to $target_role ($timestamp)"
}

handle_muse_write_memory() {
  local content="$1" section="${2:-}"
  local today
  today="$(date '+%Y-%m-%d')"
  local filepath="$PROJECT_ROOT/$MEMORY_DIR/${today}.md"

  # Create memory directory if needed
  mkdir -p "$PROJECT_ROOT/$MEMORY_DIR"

  local entry=""
  if [[ -n "$section" ]]; then
    entry="$(printf '\n## %s\n\n%s\n' "$section" "$content")"
  else
    entry="$(printf '\n%s\n' "$content")"
  fi

  echo "$entry" >> "$filepath"
  echo "✅ Written to memory/$today.md"
}

handle_muse_search_memory() {
  local query="$1" scope="${2:-all}"
  local output="" found=0

  case "$scope" in
    longterm)
      if [[ -f "$PROJECT_ROOT/MEMORIES.md" ]]; then
        local results
        results="$(grep -n "$query" "$PROJECT_ROOT/MEMORIES.md" 2>/dev/null || true)"
        if [[ -n "$results" ]]; then
          output+="=== MEMORIES.md ===$results"$'\n'
          found=1
        fi
      fi
      ;;
    recent)
      # Last 3 days
      for i in 0 1 2; do
        local d
        d="$(date -v-${i}d '+%Y-%m-%d' 2>/dev/null || date -d "-${i} days" '+%Y-%m-%d' 2>/dev/null || true)"
        [[ -z "$d" ]] && continue
        local mf="$PROJECT_ROOT/$MEMORY_DIR/${d}.md"
        if [[ -f "$mf" ]]; then
          local results
          results="$(grep -n "$query" "$mf" 2>/dev/null || true)"
          if [[ -n "$results" ]]; then
            output+="=== memory/$d.md ==="$'\n'"$results"$'\n\n'
            found=1
          fi
        fi
      done
      ;;
    all|*)
      # Search MEMORIES.md
      if [[ -f "$PROJECT_ROOT/MEMORIES.md" ]]; then
        local results
        results="$(grep -n "$query" "$PROJECT_ROOT/MEMORIES.md" 2>/dev/null || true)"
        if [[ -n "$results" ]]; then
          output+="=== MEMORIES.md ==="$'\n'"$results"$'\n\n'
          found=1
        fi
      fi
      # Search all memory files
      for mf in "$PROJECT_ROOT/$MEMORY_DIR"/*.md; do
        [[ -f "$mf" ]] || continue
        local results
        results="$(grep -n "$query" "$mf" 2>/dev/null || true)"
        if [[ -n "$results" ]]; then
          output+="=== $(basename "$mf") ==="$'\n'"$results"$'\n\n'
          found=1
        fi
      done
      ;;
  esac

  if [[ $found -eq 0 ]]; then
    echo "No results found for '$query' in scope '$scope'"
  else
    echo "$output"
  fi
}

# ─── Request Router ───

handle_request() {
  local request="$1"

  local method id
  method="$(echo "$request" | jq -r '.method // empty')"
  id="$(echo "$request" | jq -r '.id // "null"')"

  case "$method" in
    initialize)
      jq -nc --arg name "$SERVER_NAME" --arg ver "$SERVER_VERSION" --arg proto "$PROTOCOL_VERSION" --arg id "$id" '{
        jsonrpc: "2.0",
        id: ($id | tonumber),
        result: {
          protocolVersion: $proto,
          capabilities: {tools: {}},
          serverInfo: {name: $name, version: $ver}
        }
      }'
      ;;

    "notifications/initialized")
      # No response needed for notifications
      return
      ;;

    "tools/list")
      jq -nc --arg id "$id" --argjson tools "$TOOLS_JSON" '{
        jsonrpc: "2.0",
        id: ($id | tonumber),
        result: {tools: $tools}
      }'
      ;;

    "tools/call")
      local tool_name
      tool_name="$(echo "$request" | jq -r '.params.name // empty')"
      local args
      args="$(echo "$request" | jq -r '.params.arguments // {} | @json')"

      local result=""
      local is_error=0

      case "$tool_name" in
        muse_get_status)
          result="$(handle_muse_get_status)"
          ;;
        muse_list_roles)
          result="$(handle_muse_list_roles)"
          ;;
        muse_get_role)
          local role
          role="$(echo "$args" | jq -r '.role // empty')"
          result="$(handle_muse_get_role "$role" 2>&1)" || is_error=1
          ;;
        muse_send_directive)
          local target_role directive_id title body
          target_role="$(echo "$args" | jq -r '.target_role // empty')"
          directive_id="$(echo "$args" | jq -r '.directive_id // empty')"
          title="$(echo "$args" | jq -r '.title // empty')"
          body="$(echo "$args" | jq -r '.body // empty')"
          result="$(handle_muse_send_directive "$target_role" "$directive_id" "$title" "$body" 2>&1)" || is_error=1
          ;;
        muse_write_memory)
          local content section
          content="$(echo "$args" | jq -r '.content // empty')"
          section="$(echo "$args" | jq -r '.section // empty')"
          result="$(handle_muse_write_memory "$content" "$section" 2>&1)" || is_error=1
          ;;
        muse_search_memory)
          local query scope
          query="$(echo "$args" | jq -r '.query // empty')"
          scope="$(echo "$args" | jq -r '.scope // "all"')"
          result="$(handle_muse_search_memory "$query" "$scope" 2>&1)" || is_error=1
          ;;
        *)
          json_error "$id" -32601 "Unknown tool: $tool_name"
          return
          ;;
      esac

      if [[ $is_error -eq 1 ]]; then
        jq -nc --arg id "$id" --arg content "$result" '{
          jsonrpc: "2.0",
          id: ($id | tonumber),
          result: {
            content: [{type: "text", text: $content}],
            isError: true
          }
        }'
      else
        json_result "$id" "$result"
      fi
      ;;

    "ping")
      jq -nc --arg id "$id" '{jsonrpc: "2.0", id: ($id | tonumber), result: {}}'
      ;;

    *)
      # Ignore unknown notifications (method starts with notifications/)
      if [[ "$method" == notifications/* ]]; then
        return
      fi
      json_error "$id" -32601 "Method not found: $method"
      ;;
  esac
}

# ─── Main Loop: Read JSON-RPC from stdin, respond on stdout ───

log "MUSE MCP Server v$SERVER_VERSION started (project: $PROJECT_ROOT)"

while IFS= read -r line; do
  # Skip empty lines
  [[ -z "$line" ]] && continue

  # Validate JSON
  if ! echo "$line" | jq empty 2>/dev/null; then
    log "Invalid JSON received: $line"
    continue
  fi

  # Handle request
  handle_request "$line"
done

log "MUSE MCP Server shutting down"
