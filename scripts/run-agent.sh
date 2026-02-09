#!/bin/bash
# =============================================================================
# run-agent.sh — Invoke a specific agent with Claude Code
# 
# Usage:
#   ./scripts/run-agent.sh <agent-name> <task-description> [--client <slug>]
#
# Examples:
#   ./scripts/run-agent.sh maintenance "Run daily health checks on all clients"
#   ./scripts/run-agent.sh qa "Post-update regression check" --client sheffield-dental
#   ./scripts/run-agent.sh sales "Research new prospect" --client peak-physio
#   ./scripts/run-agent.sh content "Draft blog post on emergency dentistry" --client sheffield-dental
#
# This script constructs the full context for each agent and invokes Claude Code.
# =============================================================================

set -euo pipefail

AGENT_NAME="${1:?Usage: run-agent.sh <agent-name> <task>}"
TASK="${2:?Usage: run-agent.sh <agent-name> <task>}"
CLIENT_SLUG=""

# Parse optional --client flag
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --client)
            CLIENT_SLUG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

DATE=$(date +%Y-%m-%d)
LOG_FILE="logs/${DATE}.md"
AGENT_DIR="agents/${AGENT_NAME}"

# Validate agent exists
if [ ! -f "${AGENT_DIR}/CLAUDE.md" ]; then
    echo "Error: Agent '${AGENT_NAME}' not found at ${AGENT_DIR}/CLAUDE.md"
    echo "Available agents: maintenance, qa, content, seo, design, research, report-delivery, reports, sales"
    exit 1
fi

# Build context prompt
CONTEXT="You are the ${AGENT_NAME} agent for this agency.\n\n"

# Include client config if specified
if [ -n "$CLIENT_SLUG" ]; then
    CLIENT_DIR="clients/${CLIENT_SLUG}"
    if [ -f "${CLIENT_DIR}/config.yaml" ]; then
        CONTEXT+="## Client Context\n"
        CONTEXT+="$(cat ${CLIENT_DIR}/config.yaml)\n\n"
    fi
    if [ -f "${CLIENT_DIR}/health-log.md" ]; then
        CONTEXT+="## Recent Health Log\n"
        CONTEXT+="$(tail -50 ${CLIENT_DIR}/health-log.md)\n\n"
    fi
fi

# Include today's log for cross-agent awareness
if [ -f "$LOG_FILE" ]; then
    CONTEXT+="## Today's Activity Log\n"
    CONTEXT+="$(cat ${LOG_FILE})\n\n"
fi

CONTEXT+="## Your Task\n${TASK}\n"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Agent: ${AGENT_NAME}"
echo "  Task:  ${TASK}"
[ -n "$CLIENT_SLUG" ] && echo "  Client: ${CLIENT_SLUG}"
echo "  Date:  ${DATE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log the invocation (both human-readable and audit trail)
mkdir -p "$(dirname $LOG_FILE)"
echo "- [$(date +%H:%M)] ⏳ ${AGENT_NAME}: ${TASK}" >> "$LOG_FILE"

# Audit trail — tamper-evident logging
if [ -x "scripts/audit-logger.sh" ]; then
    ./scripts/audit-logger.sh log "${AGENT_NAME}" "task-started" "${TASK}${CLIENT_SLUG:+ [client: ${CLIENT_SLUG}]}"
fi

# =============================================================================
# INVOKE CLAUDE CODE
# 
# This is the actual Claude Code invocation. Adjust flags as needed:
#   --model     : claude-sonnet-4-5-20250929 for routine tasks, opus for complex
#   --max-turns : limit agent autonomy (higher for maintenance, lower for content)
#   --allowedTools : restrict which tools the agent can use
# =============================================================================

claude --print \
    --system-prompt "$(cat ${AGENT_DIR}/CLAUDE.md)" \
    --append-system-prompt "Current date: ${DATE}. Log all actions to ${LOG_FILE}. Work directory: $(pwd). Security policy: follow security/SECURITY-POLICY.md — never store credentials, never access files outside your scope, never include PII in logs." \
    --model claude-sonnet-4-5-20250929 \
    --max-turns 10 \
    "${CONTEXT}"

# Log completion (both human-readable and audit trail)
echo "- [$(date +%H:%M)] ✅ ${AGENT_NAME}: Completed — ${TASK}" >> "$LOG_FILE"

if [ -x "scripts/audit-logger.sh" ]; then
    ./scripts/audit-logger.sh log "${AGENT_NAME}" "task-completed" "${TASK}${CLIENT_SLUG:+ [client: ${CLIENT_SLUG}]}"
fi

echo ""
echo "✅ Agent ${AGENT_NAME} completed. Check ${LOG_FILE} for details."
