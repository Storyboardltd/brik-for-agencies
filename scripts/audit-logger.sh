#!/bin/bash
# =============================================================================
# audit-logger.sh — Tamper-evident append-only audit logging
#
# Provides a hash-chained audit trail so any modification to previous entries
# is detectable. Each log line includes a SHA-256 hash of (previous_hash + entry).
#
# Usage:
#   ./scripts/audit-logger.sh log <agent> <action> <details>    # Append entry
#   ./scripts/audit-logger.sh security <agent> <event> <details> # Security event
#   ./scripts/audit-logger.sh verify [date]                      # Verify integrity
#   ./scripts/audit-logger.sh summary [date]                     # Show day summary
#
# Examples:
#   ./scripts/audit-logger.sh log maintenance "updated-plugins" "3 plugins on staging"
#   ./scripts/audit-logger.sh security qa "access-violation" "Attempted to read .env"
#   ./scripts/audit-logger.sh verify 2025-02-08
#   ./scripts/audit-logger.sh summary
# =============================================================================

set -euo pipefail

# Colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

AUDIT_DIR="logs/audit"
SECURITY_LOG="${AUDIT_DIR}/security-events.log"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S%z)
AUDIT_FILE="${AUDIT_DIR}/${DATE}.audit"

# Ensure audit directory exists
mkdir -p "$AUDIT_DIR"

# Get the hash of the last entry in a file (or "GENESIS" if empty/new)
get_last_hash() {
    local file="$1"
    if [ -f "$file" ] && [ -s "$file" ]; then
        tail -1 "$file" | cut -d'|' -f1
    else
        echo "GENESIS"
    fi
}

# Compute hash: SHA-256 of (previous_hash + entry_content)
compute_hash() {
    local prev_hash="$1"
    local content="$2"
    echo -n "${prev_hash}${content}" | sha256sum | cut -d' ' -f1
}

# =============================================================================
# COMMANDS
# =============================================================================

cmd_log() {
    local agent="${1:?Usage: audit-logger.sh log <agent> <action> <details>}"
    local action="${2:?Usage: audit-logger.sh log <agent> <action> <details>}"
    local details="${3:-}"

    local prev_hash
    prev_hash=$(get_last_hash "$AUDIT_FILE")

    local entry_content="${TIMESTAMP}|${agent}|${action}|${details}"
    local entry_hash
    entry_hash=$(compute_hash "$prev_hash" "$entry_content")

    # Format: hash|timestamp|agent|action|details
    echo "${entry_hash}|${entry_content}" >> "$AUDIT_FILE"

    echo -e "${GREEN}✓${NC} Logged: [${agent}] ${action} — ${details}"
}

cmd_security() {
    local agent="${1:?Usage: audit-logger.sh security <agent> <event> <details>}"
    local event="${2:?Usage: audit-logger.sh security <agent> <event> <details>}"
    local details="${3:-}"

    # Log to the main audit trail
    cmd_log "$agent" "SECURITY:${event}" "$details"

    # Also append to the persistent security events log
    local prev_hash
    prev_hash=$(get_last_hash "$SECURITY_LOG")

    local entry_content="${TIMESTAMP}|${agent}|${event}|${details}"
    local entry_hash
    entry_hash=$(compute_hash "$prev_hash" "$entry_content")

    echo "${entry_hash}|${entry_content}" >> "$SECURITY_LOG"

    echo -e "${RED}🚨 Security event logged:${NC} [${agent}] ${event} — ${details}"
}

cmd_verify() {
    local target_date="${1:-$DATE}"
    local target_file="${AUDIT_DIR}/${target_date}.audit"

    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Audit Log Verification — ${target_date}${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo ""

    if [ ! -f "$target_file" ]; then
        echo -e "${YELLOW}  No audit log found for ${target_date}${NC}"
        exit 0
    fi

    local line_num=0
    local prev_hash="GENESIS"
    local valid=0
    local invalid=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Extract stored hash (first field)
        local stored_hash
        stored_hash=$(echo "$line" | cut -d'|' -f1)

        # Extract content (everything after first pipe)
        local content
        content=$(echo "$line" | cut -d'|' -f2-)

        # Recompute hash
        local expected_hash
        expected_hash=$(compute_hash "$prev_hash" "$content")

        if [ "$stored_hash" = "$expected_hash" ]; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
            echo -e "  ${RED}✘ Line ${line_num}: TAMPERED${NC}"
            echo -e "    Expected: ${expected_hash:0:16}..."
            echo -e "    Found:    ${stored_hash:0:16}..."

            # Show the entry for context
            local entry_agent
            entry_agent=$(echo "$content" | cut -d'|' -f2)
            local entry_action
            entry_action=$(echo "$content" | cut -d'|' -f3)
            echo -e "    Entry:    [${entry_agent}] ${entry_action}"
            echo ""
        fi

        # This entry's hash becomes the previous for the next
        prev_hash="$stored_hash"
    done < "$target_file"

    echo ""
    if [ $invalid -gt 0 ]; then
        echo -e "  ${RED}✘ INTEGRITY FAILURE — ${invalid} tampered entries out of ${line_num}${NC}"
        echo -e "  ${RED}  The audit trail has been modified. Investigate immediately.${NC}"
        echo -e "${BLUE}══════════════════════════════════════════════${NC}"
        exit 1
    else
        echo -e "  ${GREEN}✔ VERIFIED — All ${valid} entries intact${NC}"
        echo -e "  ${GREEN}  Hash chain is valid from GENESIS through entry ${line_num}${NC}"
        echo -e "${BLUE}══════════════════════════════════════════════${NC}"
        exit 0
    fi
}

cmd_summary() {
    local target_date="${1:-$DATE}"
    local target_file="${AUDIT_DIR}/${target_date}.audit"

    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Audit Summary — ${target_date}${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo ""

    if [ ! -f "$target_file" ]; then
        echo -e "${YELLOW}  No audit log found for ${target_date}${NC}"
        exit 0
    fi

    local total=0
    local security=0

    # Count by agent
    declare -A agent_counts

    while IFS= read -r line; do
        total=$((total + 1))

        local agent
        agent=$(echo "$line" | cut -d'|' -f3)
        local action
        action=$(echo "$line" | cut -d'|' -f4)

        agent_counts["$agent"]=$(( ${agent_counts["$agent"]:-0} + 1 ))

        if [[ "$action" == SECURITY:* ]]; then
            security=$((security + 1))
        fi
    done < "$target_file"

    echo -e "  Total entries:    ${total}"
    echo -e "  Security events:  ${security}"
    echo ""

    echo -e "  ${BLUE}By agent:${NC}"
    for agent in "${!agent_counts[@]}"; do
        echo -e "    ${agent}: ${agent_counts[$agent]}"
    done

    echo ""

    # Show security events if any
    if [ $security -gt 0 ]; then
        echo -e "  ${RED}Security events:${NC}"
        grep "SECURITY:" "$target_file" | while IFS= read -r line; do
            local ts
            ts=$(echo "$line" | cut -d'|' -f2)
            local agent
            agent=$(echo "$line" | cut -d'|' -f3)
            local action
            action=$(echo "$line" | cut -d'|' -f4 | sed 's/SECURITY://')
            local details
            details=$(echo "$line" | cut -d'|' -f5)
            echo -e "    ${RED}[${ts}]${NC} ${agent}: ${action} — ${details}"
        done
        echo ""
    fi

    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
}

# =============================================================================
# MAIN
# =============================================================================

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    log)
        cmd_log "$@"
        ;;
    security)
        cmd_security "$@"
        ;;
    verify)
        cmd_verify "$@"
        ;;
    summary)
        cmd_summary "$@"
        ;;
    help|--help|-h)
        echo "Usage: audit-logger.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  log <agent> <action> <details>       Append an audit entry"
        echo "  security <agent> <event> <details>    Log a security event"
        echo "  verify [date]                         Verify audit log integrity"
        echo "  summary [date]                        Show day summary"
        echo ""
        echo "Examples:"
        echo "  ./scripts/audit-logger.sh log maintenance updated-plugins '3 plugins on staging'"
        echo "  ./scripts/audit-logger.sh security qa access-violation 'Attempted to read .env'"
        echo "  ./scripts/audit-logger.sh verify 2025-02-08"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Run with --help for usage"
        exit 2
        ;;
esac
