# Client Report Skill — Website Performance Report Generator

## Overview

This skill generates professional client-facing website performance reports as PowerPoint (.pptx) presentations and optional email drafts. It compiles data from all other agents (maintenance, QA, SEO, content, design, research) into a polished, branded deliverable that demonstrates value and reduces churn.

## When to Use This Skill

- Monthly client reporting cycle (5th of each month)
- Quarterly business review preparation
- Ad-hoc performance reviews requested by founders
- New client onboarding (baseline report)

## Inputs

The skill expects these data sources per client:

```
clients/{slug}/
├── config.yaml            ← Client details, plan tier, contact info
├── health-log.md          ← Uptime, response times, SSL status
├── reports/               ← Previous reports (for trend comparison)
│   └── {YYYY-MM}.pptx
├── content/               ← Content published this period
└── design/                ← Design work delivered
```

Plus cross-agent data from:
- `logs/` — agent activity logs for the reporting period
- SEO agent output — keyword rankings, traffic data
- QA agent output — audit scores, issues found/fixed
- Maintenance agent output — updates applied, security patches

## Report Structure (8-10 Slides)

### Slide 1: Title
- Client logo/name
- Report period (e.g., "February 2025 Website Report")
- Agency branding
- Professional, dark background

### Slide 2: Executive Summary
- 3-4 key metrics as large stat callouts
- Uptime %, page speed improvement, keyword ranking gains, issues resolved
- One-sentence narrative: "Your website is performing well with X improvements this month."
- Traffic light indicator: Overall Health 🟢/🟡/🔴

### Slide 3: Uptime & Performance
- Uptime percentage (from health-log.md)
- Response time trend (chart — line graph, last 3 months)
- Core Web Vitals scores: LCP, CLS, TBT
- Before/after comparison if improvements were made

### Slide 4: SEO Progress
- Keyword ranking table (target keywords with position changes)
- Organic traffic trend (chart — bar graph)
- New keywords entering top 10
- Local SEO score / Google Business Profile stats

### Slide 5: Content Delivered
- Blog posts published (titles, dates, word counts)
- Content refresh work done
- Next month's content calendar preview
- Performance of previous content (views, clicks)

### Slide 6: Maintenance & Security
- Updates applied (WordPress core, plugins, themes)
- Security incidents blocked / scans passed
- Backup status
- SSL certificate status
- Framed positively: "We kept your site secure with X updates"

### Slide 7: Issues Found & Resolved
- Issues identified by QA/maintenance (with severity)
- Issues resolved this month
- Outstanding items with timeline
- Net issue trend (chart or simple metric)

### Slide 8: Recommendations
- 2-3 specific, actionable recommendations
- Each with business impact statement
- Tied to the client's package tier (upsell opportunities where appropriate)
- Priority ranking

### Slide 9: Next Month Preview
- Planned maintenance windows
- Content calendar
- SEO targets
- Any upcoming deadlines or milestones

### Slide 10: Contact
- Agency contact details
- How to reach your account lead
- Support hours
- Warm closing message

## Design Guidelines

### Brand-Neutral Color Palettes (Choose per client or use agency default)

| Theme | Primary | Secondary | Accent | Background |
|-------|---------|-----------|--------|------------|
| **Professional Blue** | `1E3A5F` | `4A90D9` | `00C49F` | `F8FAFB` |
| **Modern Teal** | `0D9488` | `14B8A6` | `F59E0B` | `F0FDFA` |
| **Warm Charcoal** | `374151` | `6B7280` | `3B82F6` | `F9FAFB` |
| **Agency Custom** | Use client's brand primary | Lighter tint | Complementary | Near-white |

### Chart Styling
- Bar charts for comparisons (keyword rankings, traffic by month)
- Line charts for trends (uptime, response time, traffic over time)
- Pie/doughnut for composition (traffic sources, device split)
- Always use the presentation color palette for chart colors
- Include data labels, not just axes
- Subtle grid lines, no chartjunk

### Typography
- Headers: 28-36pt bold, dark primary color
- Body: 14-16pt regular, dark gray
- Stats: 48-72pt bold for hero numbers
- Captions: 10-12pt muted gray

### Layout Rules
- Maximum 5-6 items of information per slide
- Every slide has a visual element (chart, icon, stat callout)
- Client name or agency logo on every slide (footer or header)
- Consistent margins: 0.5" minimum from edges
- Mobile-friendly PDF export consideration (large text, high contrast)

## PPTX Generation

Use PptxGenJS to create the report programmatically:

```bash
# Dependencies
npm install -g pptxgenjs react-icons react react-dom sharp
```

### Key Technical Notes
- Use `pres.layout = 'LAYOUT_16x9'` for all reports
- Never use `#` prefix in hex colors (causes file corruption)
- Use factory functions for shadow/style objects (never reuse mutable objects)
- Generate charts using `pres.charts.BAR`, `pres.charts.LINE`, `pres.charts.PIE`
- Export icons via react-icons → sharp → base64 PNG for icons
- Convert to PDF for email: `soffice --headless --convert-to pdf report.pptx`

### Verification
After generating the PPTX:
1. Convert to PDF → then to images for visual inspection
2. Check for overlapping text, cut-off content, alignment issues
3. Verify all data points match source logs
4. Confirm client name and period are correct on every slide

## Email Draft

Alongside the PPTX, generate a plain-text email draft:

```markdown
Subject: Your Website Report — {Month Year} | {Agency Name}

Hi {contact_name},

Here's your monthly website performance report for {month}.

**Highlights:**
- Uptime: {X}%
- Page speed improved by {X}%
- Now ranking for {X} keywords in the top 10
- {X} issues found and resolved

The full report is attached. A few things I'd flag:

{1-2 sentences about the most important recommendation}

Happy to jump on a call if you'd like to discuss anything.

Best,
{Founder name}
{Agency name}
```

## Output Files

The skill produces:
1. `clients/{slug}/reports/{YYYY-MM}-report.pptx` — PowerPoint report
2. `clients/{slug}/reports/{YYYY-MM}-report.pdf` — PDF version for email
3. `clients/{slug}/reports/{YYYY-MM}-email-draft.md` — Email draft with summary

## Integration with Workflow

This skill is invoked by:
- `workflows/client-report.sh` — monthly automated report generation
- `scripts/run-agent.sh report-delivery "Generate monthly report" --client {slug}` — manual trigger
- The daily orchestrator (`workflows/daily.sh`) on the 5th of each month

## Data Fallbacks

When data is missing (common for new clients or early months):
- Show "Data collection in progress" rather than empty charts
- Use qualitative descriptions instead of numbers
- Reference the baseline being established
- Never fabricate or estimate metrics — show what you have

## Tone

- **Confident but not arrogant** — show expertise without overselling
- **Positive framing** — lead with wins, frame issues as "opportunities identified"
- **Specific and quantified** — numbers beat adjectives
- **Plain English** — no jargon without explanation
- **Warm close** — always end with an invitation to discuss
- **Never mention AI** — present as "our team" work
