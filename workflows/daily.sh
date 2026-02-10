#!/bin/bash
# =============================================================================
# Agency Agents — Daily Orchestration
# Run this each morning to trigger the full agent workflow
# Usage: ./workflows/daily.sh
# =============================================================================

set -euo pipefail

DATE=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%u)  # 1=Monday, 7=Sunday
DAY_OF_MONTH=$(date +%d)
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/${DATE}.md"

# Colours for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Storyboard Digital — Daily Orchestration${NC}"
echo -e "${BLUE}  ${DATE}${NC}"
echo -e "${BLUE}══════════════════════════════════════════════${NC}"

# Create log file for today
mkdir -p "$LOG_DIR"
if [ ! -f "$LOG_FILE" ]; then
    echo "## ${DATE}" > "$LOG_FILE"
    echo "" >> "$LOG_FILE"
fi

# Helper function to run an agent task
run_agent() {
    local agent_name=$1
    local task_description=$2
    local agent_dir=$3

    echo -e "\n${GREEN}▸ Running ${agent_name}: ${task_description}${NC}"
    echo "" >> "$LOG_FILE"
    echo "### ${agent_name}" >> "$LOG_FILE"
    echo "- [$(date +%H:%M)] ⏳ Starting: ${task_description}" >> "$LOG_FILE"

    # This is where Claude Code would be invoked for each agent
    # Using the agent-specific CLAUDE.md as context
    echo -e "${YELLOW}  → claude -p agents/${agent_dir}/CLAUDE.md \"${task_description}\"${NC}"

    echo "- [$(date +%H:%M)] ✅ Completed: ${task_description}" >> "$LOG_FILE"
}

# =============================================================================
# PHASE 1: MAINTENANCE (First — so QA can check results)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 1: Maintenance ━━━${NC}"

run_agent "maintenance-agent" \
    "Run daily health checks on all client sites. Check uptime, SSL expiry, backup status, and error logs. Write results to each client's health-log.md" \
    "maintenance"

# Weekly maintenance tasks (Monday only)
if [ "$DAY_OF_WEEK" -eq 1 ]; then
    run_agent "maintenance-agent" \
        "Run weekly maintenance audit: check for available CMS updates, scan for security vulnerabilities, audit databases for bloat, and crawl for broken links across all client sites" \
        "maintenance"
fi

# Monthly maintenance tasks (1st of month)
if [ "$DAY_OF_MONTH" -eq "01" ]; then
    run_agent "maintenance-agent" \
        "Run monthly deep maintenance: performance baseline recording, storage audit, plugin audit, and security hardening review for all clients" \
        "maintenance"
fi

# =============================================================================
# PHASE 2: QA (After maintenance — checks their work)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 2: Quality Assurance ━━━${NC}"

# Check if maintenance agent flagged any updates applied to staging
run_agent "qa-agent" \
    "Check today's maintenance log for any staging updates. Run post-update regression checks on any client sites that received updates. Report findings with PASS/FAIL status" \
    "qa"

# Weekly QA audit (Wednesday)
if [ "$DAY_OF_WEEK" -eq 3 ]; then
    run_agent "qa-agent" \
        "Run weekly site audits: accessibility scan, performance audit, and basic SEO health check for all client sites. Write audit reports to each client folder" \
        "qa"
fi

# =============================================================================
# PHASE 3: SEO (Weekly and Monthly cycles)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 3: SEO ━━━${NC}"

# Weekly SEO tasks (Tuesday)
if [ "$DAY_OF_WEEK" -eq 2 ]; then
    run_agent "seo-agent" \
        "Run weekly SEO checks: update keyword ranking tracker, review Search Console for new errors, spot-check competitor changes, and identify quick-win opportunities for all clients" \
        "seo"
fi

# Monthly SEO tasks (1st of month)
if [ "$DAY_OF_MONTH" -eq "01" ]; then
    run_agent "seo-agent" \
        "Run monthly SEO audit: full technical crawl analysis, keyword research refresh, local SEO audit, backlink check, and content gap analysis for all clients. Generate monthly SEO reports" \
        "seo"
fi

# =============================================================================
# PHASE 3B: RESEARCH (Runs alongside SEO — feeds sales and content)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 3B: Research ━━━${NC}"

# Weekly competitor monitoring (Tuesday — same day as SEO)
if [ "$DAY_OF_WEEK" -eq 2 ]; then
    run_agent "research-agent" \
        "Run weekly competitor monitoring: check for competitor website changes, new competitors in client markets, and review trend updates. Feed findings to SEO and content agents" \
        "research"
fi

# Monthly competitor landscape (1st of month)
if [ "$DAY_OF_MONTH" -eq "01" ]; then
    run_agent "research-agent" \
        "Run monthly competitor landscape refresh for all clients: full competitor website audits, feature comparisons, SEO landscape mapping, and content strategy analysis. Write reports to each client's reports/ folder" \
        "research"
fi

# =============================================================================
# PHASE 4: CONTENT (Based on content calendar)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 4: Content ━━━${NC}"

# Weekly content tasks (Thursday)
if [ "$DAY_OF_WEEK" -eq 4 ]; then
    run_agent "content-agent" \
        "Check content calendars for all clients. Draft any content due this week. Refresh any stale content flagged by SEO agent. Write drafts to each client's content/ folder" \
        "content"
fi

# Monthly content calendar (last working day of month)
if [ "$DAY_OF_MONTH" -eq "28" ]; then
    run_agent "content-agent" \
        "Generate next month's content calendar for all clients based on SEO agent keyword research and current content gaps. Coordinate with SEO agent recommendations" \
        "content"
fi

# =============================================================================
# PHASE 4B: DESIGN (Project-driven — triggered by new builds or redesigns)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 4B: Design ━━━${NC}"

# Monthly design review (15th of month)
if [ "$DAY_OF_MONTH" -eq "15" ]; then
    run_agent "design-agent" \
        "Run monthly design review for all clients: check for visual inconsistencies, conversion opportunities, mobile layout issues, and competitor design improvements. Write design review reports to each client's design/ folder" \
        "design"
fi

# =============================================================================
# PHASE 5: REPORTING (Compiles all other agent work)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 5: Reporting ━━━${NC}"

# Weekly internal summary (Friday)
if [ "$DAY_OF_WEEK" -eq 5 ]; then
    run_agent "report-agent" \
        "Generate weekly internal summary for founders. Compile all agent activity this week, flag churn risk clients, identify upsell opportunities, and list next week's priorities. Check for churn signals across all clients" \
        "reports"
fi

# Monthly client reports (5th of month — covers previous month)
# Uses the dedicated client-report workflow for branded PPTX + email drafts
if [ "$DAY_OF_MONTH" -eq "05" ]; then
    echo -e "\n${GREEN}▸ Running client-report workflow (branded PPTX + email drafts)${NC}"
    if [ -x "workflows/client-report.sh" ]; then
        ./workflows/client-report.sh
    else
        echo -e "${RED}  ⚠️  workflows/client-report.sh not found or not executable${NC}"
        # Fallback to generic report agent
        run_agent "report-agent" \
            "Generate monthly client-facing reports for all clients. Compile uptime, performance, SEO, content, and maintenance data from the previous month. Write reports to each client's reports/ folder. Flag for founder review before sending" \
            "reports"
    fi
fi

# =============================================================================
# PHASE 6: SALES SUPPORT (Daily during prospecting season)
# =============================================================================
echo -e "\n${BLUE}━━━ Phase 6: Sales Support ━━━${NC}"

# Research new prospects (research agent does the deep dive)
run_agent "research-agent" \
    "Check workflows/prospects-queue.yaml for any new prospect research requests. Run full digital presence audit, competitor context analysis, and lead scoring for any pending prospects. Write research briefs to clients/_prospects/ folder" \
    "research"

# Sales agent uses research to prepare proposals and meeting briefs
run_agent "sales-agent" \
    "Review any new research briefs from the research agent. Generate meeting briefs for any meetings scheduled this week. Draft proposals and follow-up emails for any recent meetings. Update prospects-queue.yaml with status changes" \
    "sales"

# =============================================================================
# SUMMARY
# =============================================================================
echo -e "\n${BLUE}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Daily orchestration complete${NC}"
echo -e "${BLUE}  Log: ${LOG_FILE}${NC}"
echo -e "${BLUE}══════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}  ⚡ Review today's log for any 🚨 URGENT items${NC}"
echo -e "${YELLOW}  ⚡ Check for QA-blocked items needing attention${NC}"
echo -e "${YELLOW}  ⚡ Review any content/reports flagged for approval${NC}"
echo ""
