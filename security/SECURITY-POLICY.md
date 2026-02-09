# Security Policy — Agency Agents

This document defines the data classification, access control, and handling rules for all agents operating in this system. Every agent CLAUDE.md file must reference this policy.

## Data Classification

All files in this system fall into one of four sensitivity levels:

### CRITICAL — Never stored in this repo
- CMS passwords, hosting credentials, API keys, SSH keys
- Client payment details, bank information, billing data
- Personal passwords or authentication tokens

**Handling:** Store in a dedicated password manager (1Password, Bitwarden, etc.). Reference by name only in config files (e.g., `credentials_ref: "1password://agency-vault/sheffield-dental"`). Agents must never request, generate, or log credential values.

### SENSITIVE — Encrypted or access-controlled
- Client contact details (email, phone, address)
- Client contract terms and pricing
- Revenue figures, churn data, financial projections
- Prospect research containing personal information

**Handling:** Stored in `clients/*/config.yaml` (git-ignored). Never committed to version control. Never included in agent log output beyond client slug references. Never transmitted to external services.

### INTERNAL — Operational data
- Health check results, uptime logs, response times
- SEO rankings, keyword data, content drafts
- Agent activity logs, task queues
- Audit reports, QA findings

**Handling:** Stored in `clients/*/` and `logs/`. May be shared between agents via log files. Must not contain SENSITIVE or CRITICAL data. Reviewed before inclusion in client-facing reports.

### PUBLIC — Safe to share
- Agent instruction files (CLAUDE.md)
- Scripts, workflows, skills
- Project documentation, README, examples
- Anonymised templates

**Handling:** Committed to version control. Shared in the open source repo. Must not reference real client names, URLs, or data.

## Agent Access Rules

### Permissions Matrix

| Agent | Client configs | Health logs | Content drafts | Reports | Prospect data | Financial data |
|-------|---------------|-------------|----------------|---------|---------------|----------------|
| Maintenance | Read | Read/Write | — | — | — | — |
| QA | Read | Read | — | Write | — | — |
| SEO | Read | Read | Read | Write | — | — |
| Content | Read | — | Read/Write | — | — | — |
| Design | Read | — | Read | Write | — | — |
| Research | Read | — | — | Write | Read/Write | — |
| Report Delivery | Read | Read | Read | Read/Write | — | — |
| Reports | Read | Read | Read | Read/Write | — | Read (summary only) |
| Sales | Read | — | — | Read | Read/Write | — |

### Enforcement

The `scripts/run-agent.sh` script controls what context each agent receives. Agents only see:
1. Their own CLAUDE.md instructions
2. The specific client config requested via `--client`
3. Today's shared activity log
4. Files in the client directory relevant to their role

Agents must NOT:
- Read other agents' working files outside the shared log
- Access client directories not specified in their task
- Write to directories outside their designated output folders
- Attempt to read `.env`, `credentials`, or `secrets` files

## Secrets Management

### Environment Variables

Store credentials as environment variables, never in files:

```bash
# In your shell profile or a .env file (git-ignored)
export AGENCY_ANTHROPIC_API_KEY="sk-ant-..."
export AGENCY_UPTIME_MONITOR_KEY="..."
```

### Credential References in Config

Client configs should reference credentials by location, not value:

```yaml
# CORRECT — reference only
credentials_ref: "1password://agency-vault/sheffield-dental"
cms_login_ref: "bitwarden://client-logins/sheffield-dental-wp"

# WRONG — never do this
cms_password: "hunter2"
api_key: "sk-..."
```

### Pre-Commit Checks

Run `scripts/secrets-check.sh` before every commit. It scans for:
- API keys, tokens, and password patterns
- Email addresses in non-example files
- Private IP addresses and internal URLs
- AWS, GCP, and cloud credential patterns
- Base64-encoded secrets

Add it as a git pre-commit hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/secrets-check.sh --staged
```

## Audit Logging

### Requirements

All agent actions must be logged through `scripts/audit-logger.sh`, which provides:
- Append-only log files (agents cannot modify previous entries)
- SHA-256 hash chain for tamper detection
- Structured format for automated review
- Separate security event log for access violations

### Log Retention

| Log Type | Retention | Location |
|----------|-----------|----------|
| Daily activity logs | 90 days | `logs/YYYY-MM-DD.md` |
| Audit trail | 1 year | `logs/audit/YYYY-MM-DD.audit` |
| Security events | 1 year | `logs/audit/security-events.log` |
| Client health logs | Indefinite | `clients/*/health-log.md` |

### Tamper Detection

Run the audit log verifier to check integrity:

```bash
./scripts/audit-logger.sh --verify 2025-02-08
```

This recomputes the hash chain and flags any entries that have been modified after the fact.

## Incident Response

If an agent produces output containing SENSITIVE or CRITICAL data:

1. **Stop** — halt the daily orchestration (`Ctrl+C` or kill the cron job)
2. **Contain** — identify which log files or output files contain the leaked data
3. **Clean** — remove the sensitive data from all output files
4. **Verify** — run `scripts/secrets-check.sh` against the entire project
5. **Review** — check the audit log to understand how the leak occurred
6. **Fix** — update the agent CLAUDE.md or run-agent.sh to prevent recurrence

## Dependency Security

- Pin Claude Code to a specific version in your setup scripts
- Review agent CLAUDE.md changes before merging (treat as code review)
- Keep the `--max-turns` limit low (10 for routine, 5 for sensitive operations)
- Use `--allowedTools` in Claude Code to restrict agent capabilities where possible

## Compliance Notes

If you handle client data subject to GDPR, CCPA, or similar regulations:
- Document your data processing activities for each client
- Include data handling terms in your client contracts
- Ensure the `clients/*/config.yaml` retention aligns with your privacy policy
- Consider adding a `data_retention_days` field to client configs
- Run `scripts/secrets-check.sh` as part of your regular compliance audit
