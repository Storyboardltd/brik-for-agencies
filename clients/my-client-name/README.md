# my-client-name

## Setup Checklist
- [ ] Fill in config.yaml with all client details
- [ ] Set up staging environment URL
- [ ] Add CMS login credentials to password manager (NOT in config.yaml)
- [ ] Run initial health check: `./scripts/health-check.sh --client my-client-name`
- [ ] Run initial QA audit: `./scripts/run-agent.sh qa "Full initial audit" --client my-client-name`
- [ ] Run initial SEO baseline: `./scripts/run-agent.sh seo "Initial SEO baseline" --client my-client-name`
- [ ] Brief agents on client preferences and priorities

## Quick Commands
```bash
# Health check
./scripts/health-check.sh --client my-client-name

# Run maintenance
./scripts/run-agent.sh maintenance "Weekly maintenance check" --client my-client-name

# Run QA audit
./scripts/run-agent.sh qa "Full site audit" --client my-client-name

# Draft content
./scripts/run-agent.sh content "Draft blog post about [topic]" --client my-client-name

# SEO report
./scripts/run-agent.sh seo "Monthly SEO report" --client my-client-name

# Generate client report
./scripts/run-agent.sh reports "Monthly client report" --client my-client-name
```
