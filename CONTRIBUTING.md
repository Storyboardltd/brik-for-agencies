# Contributing to Agency Agents

Thanks for your interest in contributing. This project aims to help small marketing and web agencies automate their operations with AI agents.

## Ways to Contribute

**Share your adaptation** — If you've customized these agents for your own agency (different market, different services, different CMS), consider opening a PR to add it as an example in `examples/`.

**Improve agent instructions** — The `agents/*/CLAUDE.md` files are the core of this project. If you've found better prompts, procedures, or output formats, share them.

**Add new agents** — Have an idea for a seventh agent? (e.g., social media, email marketing, billing) Open an issue to discuss, then submit a PR with the agent's `CLAUDE.md` and any supporting scripts.

**Fix bugs in scripts** — The shell scripts in `scripts/` and `workflows/` can always be improved. Bug fixes, portability improvements, and better error handling are all welcome.

**Improve documentation** — Clearer setup instructions, better examples, additional strategy docs — all helpful.

## Adding a New Agent

1. Create a new directory: `agents/your-agent/CLAUDE.md`
2. Follow the structure of existing agents — each should have:
   - A clear **Role** section
   - **Core Responsibilities** broken into daily/weekly/monthly
   - **Procedures** with step-by-step instructions
   - **Output Formats** with templates
   - **Boundaries** listing what the agent must never do
3. Update `workflows/daily.sh` to include the new agent in the orchestration
4. Update the agent table in `README.md`
5. Test by running the agent with `scripts/run-agent.sh`

## Adding an Example

1. Create a directory in `examples/` with a descriptive name
2. Include at least a `config.yaml` showing how a client would be configured
3. Add a brief README explaining the context (what kind of agency, what market)

## Pull Request Process

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Test any script changes locally
4. Update documentation if needed
5. Submit a PR with a clear description of what you changed and why

## Code Style

- Shell scripts: use `set -euo pipefail`, include usage comments at the top
- Markdown: keep it scannable — tables over long paragraphs, clear headings
- CLAUDE.md files: be specific and actionable — agents need clear instructions, not vague guidance

## Questions?

Open an issue. We're a small project and happy to help.
