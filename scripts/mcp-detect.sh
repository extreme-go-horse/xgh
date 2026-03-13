#!/usr/bin/env bash
# xgh mcp-detect.sh — MCP availability detection helpers
# Source this file in other scripts; do not execute directly.
#
# Usage:
#   source "$(dirname "$0")/mcp-detect.sh"
#   xgh_has_slack   && echo "Slack available"
#   xgh_has_jira    && echo "Jira available"
#   xgh_has_github  && echo "GitHub CLI available"
#   xgh_has_cipher  && echo "Cipher available"
#
# Each function checks for the canonical environment variable that Claude Code
# sets when the corresponding MCP server is active, or falls back to a
# tool-list check via XGH_TOOLS (set by the hook before sourcing).
#
# The functions return 0 (true) when the MCP is detected, 1 otherwise.

# Sourcing guard — safe to source multiple times
[ -n "${XGH_MCP_DETECT_LOADED:-}" ] && return 0
XGH_MCP_DETECT_LOADED=1

# ---------------------------------------------------------------------------
# Internal helper: check if a tool name appears in XGH_TOOLS (space-separated
# list of available MCP tool names injected by the calling hook/skill).
# ---------------------------------------------------------------------------
_xgh_tool_available() {
  local tool="$1"
  # XGH_TOOLS may be unset; treat as empty
  echo "${XGH_TOOLS:-}" | tr ',' '\n' | grep -qx "$tool" 2>/dev/null
}

# ---------------------------------------------------------------------------
# xgh_has_slack
# Detects the Claude.ai first-party Slack MCP.
# Canonical tool: slack_read_thread
# ---------------------------------------------------------------------------
xgh_has_slack() {
  _xgh_tool_available "slack_read_thread" || \
  _xgh_tool_available "mcp__claude_ai_Slack__slack_read_thread"
}

# ---------------------------------------------------------------------------
# xgh_has_jira
# Detects the Claude.ai first-party Atlassian (Jira) MCP.
# Canonical tool: getJiraIssue
# ---------------------------------------------------------------------------
xgh_has_jira() {
  _xgh_tool_available "getJiraIssue" || \
  _xgh_tool_available "mcp__claude_ai_Atlassian__getJiraIssue"
}

# ---------------------------------------------------------------------------
# xgh_has_github
# Detects the GitHub CLI (gh). Not an MCP — uses the local CLI.
# ---------------------------------------------------------------------------
xgh_has_github() {
  command -v gh >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# xgh_has_cipher
# Detects the Cipher MCP server.
# Canonical tool: cipher_memory_search
# ---------------------------------------------------------------------------
xgh_has_cipher() {
  _xgh_tool_available "cipher_memory_search" || \
  _xgh_tool_available "mcp__cipher__cipher_memory_search"
}
