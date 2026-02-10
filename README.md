# Brik — AI Agent Team for Small Marketing Agencies

> Run a lean marketing agency with a team of AI agents handling maintenance, QA, content, SEO, design, research, reporting, and sales support — so the humans can focus on relationships and growth.

This is an open source reference implementation showing how a small agency (2-3 people) can use [Claude Code](https://docs.anthropic.com/en/docs/claude-code) agents to automate back-office operations and scale from ~10 clients to 30+ without hiring.

**What's included:** Nine specialized agents with detailed instructions, a daily orchestration workflow, automated client report generation (PowerPoint + email), client onboarding scripts, health monitoring, and a complete sales pipeline — ready to fork and customize for your agency.

## Who This Is For

Small web/marketing agencies (1-5 people) that:

- Spend more time servicing existing clients than finding new ones
- Can't afford to hire specialists (SEO, QA, content, reporting)
- Want to scale revenue without scaling headcount
- Use WordPress or similar CMS platforms for client sites

## Architecture

```
┌───────────────────────────────────────────────┐
│              FOUNDER A (Supervisor)            │
│  Reviews agent output · Approves production   │
│  Handles complex dev · Client escalations     │
├───────────────────────────────────────────────┤
│              DAILY ORCHESTRATOR                │
│            workflows/daily.sh (cron)           │
├───────┬─────┬─────┬───────┬──────┬───────┬──────┬────────┤
│Maint. │ QA  │ SEO │Content│Design│Resrch │Report│ Sales  │
│ Agent │Agent│Agent│ Agent │Agent │ Agent │Agent │Support │
├───────┴─────┴─────┴───────┴──────┴───────┴──────┴────────┤
│              CLIENT CONFIGS                    │
│     clients/*/config.yaml — one per client     │
├───────────────────────────────────────────────┤
│            FOUNDER B (Prospecting)             │
│  Networking · Sales meetings · Relationships   │
│  Feeds workflows/prospects-queue.yaml          │
└───────────────────────────────────────────────┘
```

## Quick Start

### 1. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

### 2. Clone and Set Up

```bash
git clone https://github.com/vinay-lgtm-code/brik-for-agencies.git
cd brik-for-agencies
chmod +x scripts/*.sh workflows/*.sh
```

### 3. Onboard Your First Client

```bash
./scripts/onboard-client.sh my-first-client
# Edit clients/my-first-client/config.yaml with their details
```

### 4. Run a Health Check

```bash
./scripts/health-check.sh
```

### 5. Run an Agent

```bash
# Run a specific agent for a specific client
./scripts/run-agent.sh maintenance "Run daily health checks" --client my-first-client

# Run the full daily orchestration
./workflows/daily.sh
```

### 6. Set Up the Cron Job

```bash
# Add to crontab: crontab -e
0 7 * * 1-5 cd /path/to/agency-agents && ./workflows/daily.sh >> logs/cron.log 2>&1
```

## The Nine Agents

| Agent | Purpose | Key Output |
|-------|---------|------------|
| **Maintenance** | Updates, security, backups, uptime | Health logs, update reports |
| **QA** | Testing, accessibility, performance | Audit reports, bug reports |
| **SEO** | Rankings, local SEO, technical SEO | SEO reports, keyword research |
| **Content** | Blog posts, copy, meta tags | Content drafts, calendars |
| **Design** | Wireframes, mockups, design systems | Page designs, brand guidelines |
| **Research** | Prospect profiling, competitor analysis | Research briefs, landscape reports |
| **Report Delivery** | Branded PPTX reports, email drafts | PowerPoint decks, cover emails |
| **Reports** | Internal summaries, churn detection | Weekly summaries, monthly reports |
| **Sales** | Proposal drafting, meeting prep | Lead briefs, proposal drafts |

Each agent has its own detailed instruction file in `agents/*/CLAUDE.md` with procedures, output formats, and safety boundaries. The report-delivery agent also uses `skills/client-report/SKILL.md` for slide design and layout guidelines.

## Daily Schedule

| Time | Agent | Task | Frequency |
|------|-------|------|-----------|
| 07:00 | Maintenance | Health checks (all clients) | Daily |
| 07:30 | QA | Post-update regression checks | Daily (if updates) |
| 08:00 | Sales Support | Process prospect queue | Daily |
| Monday AM | Maintenance | Weekly update audit | Weekly |
| Tuesday AM | SEO + Research | Keyword & competitor checks | Weekly |
| Wednesday AM | QA | Weekly site audits | Weekly |
| Thursday AM | Content | Draft weekly content | Weekly |
| Friday PM | Reports | Weekly internal summary | Weekly |
| 1st of month | All | Monthly deep audits & reports | Monthly |
| 5th of month | Report Delivery | Branded PPTX client reports | Monthly |

## Project Structure

```
agency-agents/
├── README.md                ← You are here
├── CLAUDE.md                ← Master ground rules for all agents
├── LICENSE
├── CONTRIBUTING.md
│
├── agents/                  ← Agent-specific instructions
│   ├── maintenance/CLAUDE.md
│   ├── qa/CLAUDE.md
│   ├── content/CLAUDE.md
│   ├── seo/CLAUDE.md
│   ├── design/CLAUDE.md
│   ├── research/CLAUDE.md
│   ├── report-delivery/CLAUDE.md ← Branded PPTX + email
│   ├── reports/CLAUDE.md
│   └── sales/CLAUDE.md
│
├── skills/                  ← Skill definitions for agent tasks
│   └── client-report/SKILL.md   ← Report design guide
│
├── security/                ← Security policy and data classification
│   └── SECURITY-POLICY.md
│
├── scripts/                 ← Utility scripts
│   ├── run-agent.sh         ← Run individual agents
│   ├── health-check.sh      ← Automated health checker
│   ├── onboard-client.sh    ← New client setup
│   ├── secrets-check.sh     ← Scan for leaked credentials
│   └── audit-logger.sh      ← Tamper-evident audit trail
│
├── workflows/               ← Multi-agent workflows
│   ├── daily.sh             ← Daily orchestration (cron job)
│   ├── client-report.sh     ← Monthly PPTX report generation
│   └── prospects-queue.yaml ← Sales pipeline
│
├── docs/                    ← Strategy and reference
│   ├── STRATEGY.md          ← Scaling strategy and revenue model
│   └── PACKAGES.md          ← Service tier pricing (example)
│
├── examples/                ← Example configurations
│   └── sheffield-dental/
│       └── config.yaml      ← Example client config
│
├── clients/                 ← Your clients (created by onboard script)
│   └── {client-slug}/
│       ├── config.yaml
│       ├── health-log.md
│       ├── reports/
│       └── content/
│
├── logs/                    ← Daily action logs (auto-created)
│   └── audit/               ← Hash-chained audit trail
└── templates/               ← Report and email templates
```

## Customizing for Your Agency

This repo is built around a Sheffield (UK) web agency as a worked example. To adapt it for your agency:

1. **Update `CLAUDE.md`** — change the ground rules to match your workflows
2. **Edit `agents/*/CLAUDE.md`** — adjust agent instructions for your services, tools, and local market
3. **Edit `docs/PACKAGES.md`** — define your own service tiers and pricing
4. **Edit `docs/STRATEGY.md`** — set your own revenue targets and growth plan
5. **Edit `workflows/prospects-queue.yaml`** — customize for your sales process
6. **Update local references** — replace Sheffield-specific content with your own market

## Security

Every agent has hard safety limits (no production changes, no client contact, no credential storage, no deleting, staging-first, log everything). See `security/SECURITY-POLICY.md` for the full policy including data classification, agent access controls, and incident response.

### Secrets Scanner

Scan for leaked credentials before committing:

```bash
./scripts/secrets-check.sh              # Full project scan
./scripts/secrets-check.sh --staged     # Git pre-commit (staged files only)
```

Detects API keys, passwords, tokens, private keys, cloud credentials, PII (emails, phone numbers), and sensitive file types. Set it as a git pre-commit hook:

```bash
ln -s ../../scripts/secrets-check.sh .git/hooks/pre-commit
```

### Audit Trail

Tamper-evident logging with SHA-256 hash chains — any modification to previous entries is detectable:

```bash
./scripts/audit-logger.sh log maintenance "updated-plugins" "3 plugins on staging"
./scripts/audit-logger.sh security qa "access-violation" "Attempted to read .env"
./scripts/audit-logger.sh verify 2025-02-08    # Check integrity
./scripts/audit-logger.sh summary              # Daily summary
```

### Data Classification

All data is classified into four levels (CRITICAL → SENSITIVE → INTERNAL → PUBLIC) with handling rules for each. Client credentials must never be stored in this repo — use credential references pointing to your password manager instead.

## Estimated Costs

| Item | Monthly |
|------|---------|
| Claude Code / API usage | $200–$500 |
| Hosting tools (uptime monitoring, etc.) | $25–$60 |
| **Total agent team** | **$225–$560** |

The agent team pays for itself with a single new client.

## Example: Sheffield Web Agency

The `examples/` and `docs/` folders contain a complete worked example for a 2-person web agency in Sheffield, UK, including:

- A real client configuration (dental practice)
- Three-tier pricing model (Basic / Standard / Premium)
- Six-month scaling strategy from 10 to 28+ clients
- Revenue projections and churn reduction playbook
- Local SEO strategy and prospecting intelligence

See `docs/STRATEGY.md` for the full business case.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new agents, improving existing ones, or sharing your agency's adaptations.

## License

MIT — see [LICENSE](LICENSE) for details.

---

Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Designed for small agencies that want to punch above their weight.
