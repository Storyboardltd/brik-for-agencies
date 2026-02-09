#!/bin/bash
# =============================================================================
# health-check.sh — Automated site health checker
# Checks uptime, response time, SSL expiry, and basic status for all clients
#
# Usage: ./scripts/health-check.sh [--client <slug>]
# =============================================================================

set -euo pipefail

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H:%M)
CLIENT_FILTER="${2:-}"

echo "🔍 Running health checks — ${DATE} ${TIMESTAMP}"
echo ""

# Find all client configs
for config in clients/*/config.yaml; do
    [ -f "$config" ] || continue

    CLIENT_DIR=$(dirname "$config")
    SLUG=$(basename "$CLIENT_DIR")

    # Skip if filtering to specific client
    if [ -n "$CLIENT_FILTER" ] && [ "$SLUG" != "$CLIENT_FILTER" ]; then
        continue
    fi

    # Parse config (basic yaml parsing — works for simple flat configs)
    NAME=$(grep '^name:' "$config" | sed 's/name: *"\(.*\)"/\1/')
    URL=$(grep '^url:' "$config" | sed 's/url: *//')
    STAGING_URL=$(grep '^staging_url:' "$config" | sed 's/staging_url: *//' || echo "")

    echo "━━━ ${NAME} (${SLUG}) ━━━"

    # 1. Uptime & Response Time Check
    HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$URL" 2>/dev/null || echo "000")
    RESPONSE_TIME=$(curl -o /dev/null -s -w "%{time_total}" --max-time 10 "$URL" 2>/dev/null || echo "timeout")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "  ✅ Status: UP (HTTP ${HTTP_CODE})"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "  🚨 Status: DOWN — Connection failed"
    else
        echo "  ⚠️  Status: HTTP ${HTTP_CODE}"
    fi

    echo "  ⏱️  Response: ${RESPONSE_TIME}s"

    # 2. SSL Certificate Check
    if [[ "$URL" == https://* ]]; then
        DOMAIN=$(echo "$URL" | sed 's|https://||' | sed 's|/.*||')
        SSL_EXPIRY=$(echo | openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')

        if [ -n "$SSL_EXPIRY" ]; then
            EXPIRY_EPOCH=$(date -d "$SSL_EXPIRY" +%s 2>/dev/null || echo "0")
            NOW_EPOCH=$(date +%s)
            DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

            if [ "$DAYS_LEFT" -lt 7 ]; then
                echo "  🚨 SSL: Expires in ${DAYS_LEFT} days! (${SSL_EXPIRY})"
            elif [ "$DAYS_LEFT" -lt 30 ]; then
                echo "  ⚠️  SSL: Expires in ${DAYS_LEFT} days (${SSL_EXPIRY})"
            else
                echo "  🔒 SSL: Valid for ${DAYS_LEFT} days"
            fi
        else
            echo "  ⚠️  SSL: Could not check certificate"
        fi
    fi

    # 3. Write to client health log
    HEALTH_LOG="${CLIENT_DIR}/health-log.md"
    if [ ! -f "$HEALTH_LOG" ]; then
        echo "# Health Log — ${NAME}" > "$HEALTH_LOG"
        echo "" >> "$HEALTH_LOG"
    fi

    echo "" >> "$HEALTH_LOG"
    echo "## ${DATE} ${TIMESTAMP}" >> "$HEALTH_LOG"
    echo "- **Status:** HTTP ${HTTP_CODE}" >> "$HEALTH_LOG"
    echo "- **Response Time:** ${RESPONSE_TIME}s" >> "$HEALTH_LOG"

    if [ -n "${DAYS_LEFT:-}" ]; then
        echo "- **SSL Expiry:** ${DAYS_LEFT} days remaining" >> "$HEALTH_LOG"
    fi

    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Health checks complete. Results written to client health logs."
