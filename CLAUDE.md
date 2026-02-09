# Agency Agents — Agent Team Workspace

## Project Overview
This is the Claude Code workspace for a small web/marketing agency. The agent team handles maintenance, QA, content, SEO, reporting, and sales support so the founders can focus on high-value work and in-person prospecting.

## Ground Rules for ALL Agents

### Never Do Without Human Approval
- Push code to production/live sites
- Send emails or messages to clients
- Delete files, databases, or backups
- Modify DNS, hosting, or SSL settings
- Make purchases or commit to costs
- Respond to client complaints

### Never Do (Security)
- Store passwords, API keys, or tokens in any file — use credential references only
- Access `.env`, `credentials.*`, or `secrets/` files
- Include client emails, phone numbers, or PII in log entries — use client slug only
- Read client directories outside of your assigned task scope
- Write output to directories other than your designated output folders
- Bypass or disable the audit logger

### Always Do
- Write changes to staging/preview first
- Log every action via `scripts/audit-logger.sh` (tamper-evident audit trail)
- Also log to `logs/YYYY-MM-DD.md` for human-readable daily summaries
- Flag anything urgent with `🚨 URGENT:` prefix in logs
- Include before/after evidence for any change
- Estimate time and cost before starting work
- Ask for clarification rather than guessing
- Follow the data classification rules in `security/SECURITY-POLICY.md`

### File Structure
```
agency-agents/
├── CLAUDE.md                    ← You are here
├── clients/                     ← One folder per client
│   └── {client-slug}/
│       ├── config.yaml          ← Site URL, CMS type, credentials ref, contacts
│       ├── health-log.md        ← Running health record
│       ├── reports/             ← Generated reports
│       └── content/             ← Drafted content
├── agents/                      ← Agent-specific instructions
│   ├── maintenance/CLAUDE.md
│   ├── qa/CLAUDE.md
│   ├── content/CLAUDE.md
│   ├── seo/CLAUDE.md
│   ├── design/CLAUDE.md
│   ├── research/CLAUDE.md
│   ├── report-delivery/CLAUDE.md ← Branded PPTX reports + email drafts
│   ├── reports/CLAUDE.md
│   └── sales/CLAUDE.md
├── skills/                      ← Skill definitions for agent tasks
│   └── client-report/SKILL.md  ← PPTX report design & structure guide
├── security/                    ← Security policy and data classification
│   └── SECURITY-POLICY.md
├── scripts/                     ← Shared automation scripts
│   ├── secrets-check.sh        ← Scan for leaked credentials
│   └── audit-logger.sh         ← Tamper-evident audit trail
├── templates/                   ← Report, email, proposal templates
├── workflows/                   ← Multi-agent workflow definitions
├── logs/                        ← Daily action logs
│   └── audit/                  ← Hash-chained audit trail
└── docs/                        ← Strategy, processes, reference
```

### Client Config Format (`clients/{slug}/config.yaml`)
```yaml
name: "Example Client Co."
slug: example-client
url: https://example-client.com
staging_url: https://staging.example-client.com
cms: wordpress
hosting: siteground
plan: standard  # basic | standard | premium
monthly_fee: 600
contact_name: Jane Smith
contact_email: jane@example.com
services:
  - maintenance
  - seo
  - content
  - reporting
notes: "Sensitive about page speed. Wants to rank for '[service] [city]'"
onboarded: 2024-03-15
```

### Logging Format (`logs/YYYY-MM-DD.md`)
```markdown
## 2025-02-08

### maintenance-agent
- [09:00] ✅ Updated WordPress core 6.4.2 → 6.4.3 on example-client (staging)
- [09:15] ✅ Updated 3 plugins on example-client (staging)
- [09:30] ⏳ Awaiting approval to push example-client updates to production
- [10:00] 🚨 URGENT: SSL certificate for acme-plumbing expires in 7 days

### qa-agent
- [09:45] ✅ Post-update regression check on example-client staging — no issues
- [10:00] ⚠️ example-client mobile nav menu overlaps CTA on iPhone SE viewport
```

### Communication Protocols
- **Between agents:** Use shared log files and `workflows/` task queues
- **To founders:** Write to `logs/` and flag with urgency markers
- **Never directly contact clients** — all client communication goes through founders
