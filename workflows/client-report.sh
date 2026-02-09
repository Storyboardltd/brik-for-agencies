#!/bin/bash
# =============================================================================
# Agency Agents — Client Report Generation Workflow
#
# Generates branded PowerPoint performance reports and email drafts
# for each client, then stages them for founder review.
#
# Usage:
#   ./workflows/client-report.sh                     # All clients
#   ./workflows/client-report.sh --client my-client   # Single client
#   ./workflows/client-report.sh --quarterly          # Quarterly review mode
#
# This workflow:
#   1. Collects data from all agent outputs for the reporting period
#   2. Invokes the report-delivery agent to generate PPTX + email draft
#   3. Converts PPTX to PDF for email attachment
#   4. Stages everything for founder review
#
# Typically run on the 5th of each month via workflows/daily.sh
# =============================================================================

set -euo pipefail

DATE=$(date +%Y-%m-%d)
MONTH=$(date +%Y-%m)
PREV_MONTH=$(date -d "1 month ago" +%Y-%m 2>/dev/null || date -v-1m +%Y-%m 2>/dev/null)
REPORT_TYPE="monthly"
CLIENT_FILTER=""
LOG_FILE="logs/${DATE}.md"

# Colours for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --client)
            CLIENT_FILTER="$2"
            shift 2
            ;;
        --quarterly)
            REPORT_TYPE="quarterly"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: client-report.sh [--client <slug>] [--quarterly]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Client Report Generation — ${REPORT_TYPE}${NC}"
echo -e "${BLUE}  Period: ${PREV_MONTH}${NC}"
echo -e "${BLUE}══════════════════════════════════════════════${NC}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Count clients processed
TOTAL=0
SUCCESS=0
FAILED=0

# Process each client
for config in clients/*/config.yaml; do
    [ -f "$config" ] || continue

    CLIENT_DIR=$(dirname "$config")
    SLUG=$(basename "$CLIENT_DIR")

    # Skip if filtering to specific client
    if [ -n "$CLIENT_FILTER" ] && [ "$SLUG" != "$CLIENT_FILTER" ]; then
        continue
    fi

    # Parse client details
    NAME=$(grep '^name:' "$config" | sed 's/name: *"\(.*\)"/\1/')
    PLAN=$(grep '^plan:' "$config" | sed 's/plan: *//')
    CONTACT=$(grep '^contact_name:' "$config" | sed 's/contact_name: *"\(.*\)"/\1/')

    # Check if reporting is in their service list
    if ! grep -q "reporting" "$config"; then
        echo -e "${YELLOW}  ⏭  Skipping ${NAME} — reporting not in service plan${NC}"
        continue
    fi

    TOTAL=$((TOTAL + 1))

    echo -e "\n${GREEN}▸ Generating ${REPORT_TYPE} report for ${NAME}${NC}"
    echo -e "  Plan: ${PLAN} | Contact: ${CONTACT}"

    # Ensure reports directory exists
    mkdir -p "${CLIENT_DIR}/reports"

    # =========================================================================
    # STEP 1: Collect data summary for the agent
    # =========================================================================
    DATA_SUMMARY=""

    # Health log data
    if [ -f "${CLIENT_DIR}/health-log.md" ]; then
        DATA_SUMMARY+="## Health Log (last 30 entries)\n"
        DATA_SUMMARY+="$(tail -60 "${CLIENT_DIR}/health-log.md")\n\n"
    fi

    # Agent activity for this client
    DATA_SUMMARY+="## Agent Activity This Period\n"
    for logfile in logs/${PREV_MONTH}-*.md; do
        [ -f "$logfile" ] && DATA_SUMMARY+="$(grep -i "${SLUG}" "$logfile" 2>/dev/null || true)\n"
    done
    DATA_SUMMARY+="\n"

    # Content delivered
    if [ -d "${CLIENT_DIR}/content" ]; then
        CONTENT_COUNT=$(find "${CLIENT_DIR}/content" -name "*.md" -newer "${CLIENT_DIR}/reports/" 2>/dev/null | wc -l || echo "0")
        DATA_SUMMARY+="## Content Delivered: ${CONTENT_COUNT} pieces\n"
        DATA_SUMMARY+="$(ls -la "${CLIENT_DIR}/content/" 2>/dev/null || echo "No content files found")\n\n"
    fi

    # Previous report (for trend comparison)
    PREV_REPORT="${CLIENT_DIR}/reports/${PREV_MONTH}-report.pptx"
    if [ -f "$PREV_REPORT" ]; then
        DATA_SUMMARY+="## Previous Report: ${PREV_REPORT} (exists for trend comparison)\n\n"
    else
        DATA_SUMMARY+="## Previous Report: None (this may be the first report)\n\n"
    fi

    # =========================================================================
    # STEP 2: Invoke report-delivery agent
    # =========================================================================
    echo -e "  ${YELLOW}→ Invoking report-delivery agent...${NC}"

    REPORT_TASK="Generate a ${REPORT_TYPE} client performance report for ${NAME}. "
    REPORT_TASK+="Report period: ${PREV_MONTH}. "
    REPORT_TASK+="Client plan: ${PLAN}. "
    REPORT_TASK+="Create a branded PowerPoint presentation following skills/client-report/SKILL.md. "
    REPORT_TASK+="Also draft a cover email for ${CONTACT}. "
    REPORT_TASK+="Save outputs to: ${CLIENT_DIR}/reports/${PREV_MONTH}-report.pptx and ${CLIENT_DIR}/reports/${PREV_MONTH}-email-draft.md. "
    REPORT_TASK+="Here is the collected data:\n\n${DATA_SUMMARY}"

    # Invoke Claude Code for report generation
    claude --print \
        --system-prompt "$(cat agents/report-delivery/CLAUDE.md)" \
        --append-system-prompt "Current date: ${DATE}. Client directory: ${CLIENT_DIR}. Report period: ${PREV_MONTH}. Read skills/client-report/SKILL.md for report structure and design guidelines." \
        --model claude-sonnet-4-5-20250929 \
        --max-turns 15 \
        "${REPORT_TASK}" && {
            echo -e "  ${GREEN}✅ Report generated for ${NAME}${NC}"
            SUCCESS=$((SUCCESS + 1))

            # Log success
            echo "- [$(date +%H:%M)] ✅ report-delivery: Generated ${REPORT_TYPE} report for ${NAME}" >> "$LOG_FILE"
            echo "- [$(date +%H:%M)] ⏳ Awaiting founder review: ${CLIENT_DIR}/reports/${PREV_MONTH}-report.pptx" >> "$LOG_FILE"
        } || {
            echo -e "  ${RED}❌ Report generation failed for ${NAME}${NC}"
            FAILED=$((FAILED + 1))

            # Log failure
            echo "- [$(date +%H:%M)] ❌ report-delivery: FAILED to generate report for ${NAME}" >> "$LOG_FILE"
        }

    echo ""
done

# =========================================================================
# SUMMARY
# =========================================================================
echo -e "${BLUE}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Report generation complete${NC}"
echo -e "  Total: ${TOTAL} | Success: ${SUCCESS} | Failed: ${FAILED}"
echo -e "${BLUE}══════════════════════════════════════════════${NC}"
echo ""

if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}  ⚠️  ${FAILED} report(s) failed — check logs for details${NC}"
fi

echo -e "${YELLOW}  📋 Next steps:${NC}"
echo -e "${YELLOW}  1. Review each report in clients/*/reports/${NC}"
echo -e "${YELLOW}  2. Review email drafts in clients/*/reports/*-email-draft.md${NC}"
echo -e "${YELLOW}  3. Personalise and send to clients${NC}"
echo ""
