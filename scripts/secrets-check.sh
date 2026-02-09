#!/bin/bash
# =============================================================================
# secrets-check.sh — Scan project files for leaked credentials and sensitive data
#
# Usage:
#   ./scripts/secrets-check.sh             # Scan entire project
#   ./scripts/secrets-check.sh --staged    # Scan only git-staged files (pre-commit)
#   ./scripts/secrets-check.sh --path dir  # Scan a specific directory
#
# Exit codes:
#   0 = Clean — no secrets detected
#   1 = Findings — potential secrets found (review required)
#   2 = Error — script failed to run
#
# Add as a git pre-commit hook:
#   cp scripts/secrets-check.sh .git/hooks/pre-commit
#   # or symlink: ln -s ../../scripts/secrets-check.sh .git/hooks/pre-commit
# =============================================================================

set -euo pipefail

# Colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCAN_MODE="full"
SCAN_PATH="."
FINDINGS=0
WARNINGS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --staged)
            SCAN_MODE="staged"
            shift
            ;;
        --path)
            SCAN_PATH="$2"
            SCAN_MODE="path"
            shift 2
            ;;
        --help|-h)
            echo "Usage: secrets-check.sh [--staged] [--path <dir>]"
            echo "  --staged   Scan only git-staged files (for pre-commit hook)"
            echo "  --path     Scan a specific directory or file"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 2
            ;;
    esac
done

echo -e "${BLUE}══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Secrets Check — Agency Agents${NC}"
echo -e "${BLUE}  Mode: ${SCAN_MODE}${NC}"
echo -e "${BLUE}══════════════════════════════════════════════${NC}"
echo ""

# Build file list based on scan mode
get_files() {
    case $SCAN_MODE in
        staged)
            git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo ""
            ;;
        path)
            find "$SCAN_PATH" -type f \
                ! -path '*/.git/*' \
                ! -path '*/node_modules/*' \
                ! -name '*.png' ! -name '*.jpg' ! -name '*.gif' \
                ! -name '*.pdf' ! -name '*.zip' \
                2>/dev/null
            ;;
        full)
            find . -type f \
                ! -path '*/.git/*' \
                ! -path '*/node_modules/*' \
                ! -name '*.png' ! -name '*.jpg' ! -name '*.gif' \
                ! -name '*.pdf' ! -name '*.zip' \
                2>/dev/null
            ;;
    esac
}

# Files that are EXPECTED to contain patterns (allowlisted)
is_allowlisted() {
    local file="$1"
    local pattern_name="$2"

    # The secrets-check script itself contains patterns — skip it
    [[ "$file" == *"secrets-check.sh"* ]] && return 0

    # Security policy doc describes patterns — skip it
    [[ "$file" == *"SECURITY-POLICY.md"* ]] && return 0

    # Example configs are meant to show format
    [[ "$file" == *"examples/"* && "$pattern_name" == "email" ]] && return 0

    # CONTRIBUTING.md and README may reference example emails
    [[ "$file" == *"CONTRIBUTING.md"* && "$pattern_name" == "email" ]] && return 0

    return 1
}

# Pattern scanning function
scan_pattern() {
    local label="$1"
    local pattern="$2"
    local severity="$3"  # CRITICAL or WARNING
    local pattern_name="$4"

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue

        # Skip binary files
        if file "$file" 2>/dev/null | grep -q "binary"; then
            continue
        fi

        # Skip allowlisted files for this pattern
        if is_allowlisted "$file" "$pattern_name"; then
            continue
        fi

        # Search for pattern
        local matches
        matches=$(grep -nP "$pattern" "$file" 2>/dev/null || true)

        if [ -n "$matches" ]; then
            while IFS= read -r match; do
                local line_num=$(echo "$match" | cut -d: -f1)
                local line_content=$(echo "$match" | cut -d: -f2-)

                # Truncate long lines for display
                if [ ${#line_content} -gt 80 ]; then
                    line_content="${line_content:0:77}..."
                fi

                if [ "$severity" = "CRITICAL" ]; then
                    echo -e "  ${RED}CRITICAL${NC} ${label}"
                    FINDINGS=$((FINDINGS + 1))
                else
                    echo -e "  ${YELLOW}WARNING${NC}  ${label}"
                    WARNINGS=$((WARNINGS + 1))
                fi
                echo -e "    File: ${file}:${line_num}"
                echo -e "    Line: ${line_content}"
                echo ""
            done <<< "$matches"
        fi
    done <<< "$(get_files)"
}

# =============================================================================
# CRITICAL PATTERNS — These should never appear in committed files
# =============================================================================
echo -e "${BLUE}━━━ Scanning for API keys and tokens ━━━${NC}"

scan_pattern "Anthropic API Key" \
    'sk-ant-[a-zA-Z0-9_-]{20,}' \
    "CRITICAL" "api_key"

scan_pattern "OpenAI API Key" \
    'sk-[a-zA-Z0-9]{20,}' \
    "CRITICAL" "api_key"

scan_pattern "Generic API Key Assignment" \
    '(?i)(api[_-]?key|apikey|api[_-]?secret)\s*[:=]\s*["\x27][a-zA-Z0-9_\-]{16,}["\x27]' \
    "CRITICAL" "api_key"

scan_pattern "Bearer Token" \
    '(?i)bearer\s+[a-zA-Z0-9_\-\.]{20,}' \
    "CRITICAL" "token"

scan_pattern "Private Key Block" \
    '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----' \
    "CRITICAL" "private_key"

echo -e "${BLUE}━━━ Scanning for passwords and secrets ━━━${NC}"

scan_pattern "Password Assignment" \
    '(?i)(password|passwd|pwd)\s*[:=]\s*["\x27][^\s"'\'']{4,}["\x27]' \
    "CRITICAL" "password"

scan_pattern "Secret Assignment" \
    '(?i)(secret|token|auth)\s*[:=]\s*["\x27][a-zA-Z0-9_\-]{8,}["\x27]' \
    "CRITICAL" "secret"

scan_pattern "Connection String" \
    '(?i)(mysql|postgres|mongodb|redis)://[^\s"]+:[^\s"]+@' \
    "CRITICAL" "connection_string"

echo -e "${BLUE}━━━ Scanning for cloud credentials ━━━${NC}"

scan_pattern "AWS Access Key" \
    'AKIA[0-9A-Z]{16}' \
    "CRITICAL" "aws_key"

scan_pattern "AWS Secret Key" \
    '(?i)aws[_-]?secret[_-]?access[_-]?key\s*[:=]\s*["\x27]?[A-Za-z0-9/+=]{40}' \
    "CRITICAL" "aws_secret"

scan_pattern "GCP Service Account" \
    '"type"\s*:\s*"service_account"' \
    "CRITICAL" "gcp_creds"

echo -e "${BLUE}━━━ Scanning for personal data ━━━${NC}"

scan_pattern "Email Address (non-example)" \
    '[a-zA-Z0-9._%+-]+@(?!example\.)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' \
    "WARNING" "email"

scan_pattern "UK Phone Number" \
    '(?<!\d)0[0-9]{3,4}\s?[0-9]{3}\s?[0-9]{3,4}(?!\d)' \
    "WARNING" "phone"

scan_pattern "Private IP Address" \
    '(?<!\d)(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})(?!\d)' \
    "WARNING" "private_ip"

# =============================================================================
# FILE-LEVEL CHECKS — Dangerous file types that shouldn't be committed
# =============================================================================
echo -e "${BLUE}━━━ Scanning for sensitive files ━━━${NC}"

while IFS= read -r file; do
    [ -z "$file" ] && continue

    basename=$(basename "$file")

    case "$basename" in
        .env|.env.local|.env.production|.env.staging)
            echo -e "  ${RED}CRITICAL${NC} Environment file: ${file}"
            FINDINGS=$((FINDINGS + 1))
            ;;
        credentials.json|credentials.yaml|credentials.yml)
            echo -e "  ${RED}CRITICAL${NC} Credentials file: ${file}"
            FINDINGS=$((FINDINGS + 1))
            ;;
        *.pem|*.key|*.p12|*.pfx)
            echo -e "  ${RED}CRITICAL${NC} Certificate/key file: ${file}"
            FINDINGS=$((FINDINGS + 1))
            ;;
        id_rsa|id_ed25519|id_ecdsa)
            echo -e "  ${RED}CRITICAL${NC} SSH private key: ${file}"
            FINDINGS=$((FINDINGS + 1))
            ;;
        .htpasswd|.htaccess)
            echo -e "  ${YELLOW}WARNING${NC}  Server config file: ${file}"
            WARNINGS=$((WARNINGS + 1))
            ;;
    esac
done <<< "$(get_files)"

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${BLUE}══════════════════════════════════════════════${NC}"

if [ $FINDINGS -gt 0 ]; then
    echo -e "${RED}  ✘ FAILED — ${FINDINGS} critical finding(s), ${WARNINGS} warning(s)${NC}"
    echo -e "${RED}  Review and fix all CRITICAL items before committing.${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}  ⚠ PASSED WITH WARNINGS — ${WARNINGS} warning(s)${NC}"
    echo -e "${YELLOW}  Review warnings to ensure no sensitive data is exposed.${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${GREEN}  ✔ CLEAN — No secrets or sensitive data detected${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    exit 0
fi
