# Report Wizard — Handoff to Claude Code

## What this is

A self-service wizard that lets anyone at CorroHealth build a Pulse 2.0 chart-data
export/report request without writing SQL or filing a ticket. It currently lives as a
**single self-contained HTML/JS file** (`pulse-report-wizard.html`) that runs as a
Claude.ai artifact — no build step, no server, vanilla JS.

The goal of moving to Claude Code is to turn this prototype into something that can
actually run outside of Claude.ai and, eventually, talk to real systems.

## How we got here (grounding — read this before changing field names or templates)

Everything in this tool is deliberately **grounded in the real Pulse codebase**,
inspected via a SageTech MCP connection (project key `acs26`, cycle `3`). Nothing in
the current template set is invented. Specifically:

- **`EXPORT_DEFINITION` / `EXPORT_COLUMN` / `EXPORT_FIELD`** — the real SQL Server
  tables Pulse uses for ad-hoc chart data exports. The wizard's whole "spec" output
  (the JSON download) mirrors this schema column-for-column.
- **`ChartDataExportProcessing`** — the real workflow/state machine for running an
  export. The wizard's step rail labels (`EXPORT_REQUESTED`, `CONFIGURATION_LOADED`,
  `DATA_FILTERED`, `FILE_GENERATED`, `EXPORT_COMPLETED`) are lifted directly from it.
- **`REPORT_MAP` / `REPORT_ITEM` / `REPORT_PARAMETER` / `REPORT_SPECIFICATION` /
  `REPORT_SUBSCRIPTION`** — a *separate*, older SSRS-style reporting subsystem we found
  later. `REPORT_SUBSCRIPTION` means **real recurring report subscriptions already
  exist in Pulse** — the wizard's own subscription feature (see below) should
  eventually be positioned as a front-end to this, not a competing system.
- **The CorroHealth QBR deck** (`CorroHealth_Generic_QBR_Template.pptx`, uploaded
  earlier) is the ground truth for what reports clients actually see today: Account
  Activity Overview, Quality Performance by Facility, Level of Service Summary
  (Urgent Care / Emergency Department), Infusion & Injection (Overview + Medication
  Detail), Pended Chart History.
- **Named stored procedures** confirmed real report generators: `BILLING_DETAIL_
  FACILITY_REPORT`, `MISMATCH_CHARGE_REPORT`, `REPORT_Auditor_Productivity_by_
  Facility`, `REPORT_Average_RVUs_per_Visit_by_Time_of_Day`.
- **`BillingFinance-1.xlsx`** (uploaded earlier) — a real exported report. The
  "Billing Finance" template matches its 30 columns exactly, in order (facility
  identity → all 6 rate columns → all 5 channel count/revenue pairs → totals).

**Known blind spot:** the static seed data for `EXPORT_FIELD` and `REPORT_MAP`
(the actual ~100-row report catalog) is stored in a binary-encoded format Sage
could not decode. We could see the table structure and descriptions but not the
literal row values. If you get real database access in Claude Code, pulling those
tables directly would let the template set grow to match 100% of what's real,
instead of the 11 we could verify by other means.

## Current feature set (as of the artifact version)

1. **Quick-start template picker** — 11 templates, each tagged "✓ Official Pulse
   report," each pre-filling name/description/format/scope/filters/columns to match
   a real report exactly:
   Account Activity Overview, Quality Performance by Facility, Level of Service
   Summary (UC and ED separately), Infusion & Injection (Overview + Medication
   Detail), Pended Chart History, Auditor Productivity by Facility, Billing Detail
   Facility Report, Mismatch Charge Report, Billing Finance.
2. **"Build off of" tracking** — picking a template snapshots its original field IDs
   (`TEMPLATE_BASE_FIELD_IDS`). Any column added beyond that snapshot gets a visible
   "+ Added" tag, and `BASED_ON_REPORT` is carried through the whole state, the
   inspector panel, the review screen, and the exported JSON spec.
3. **"I'll build it myself" decision tree** — a short branching Q&A (what's this
   report about → facility/physician scope → chart stages → PHI masking) that sets
   filters without requiring schema knowledge.
4. **Report-matching engine** (`bestMatchFor`, `getPresetSignatures` in the JS) —
   compares whatever scope/status the person has configured against all 11 real
   report signatures. After the decision tree, if there's a strong match (score
   ≥ 4.5/5), it offers to switch to that template. While building columns, if
   there's a partial match, it suggests specific missing fields from the closest
   real report ("💡 Reports like this usually include...").
5. **Field library** — grouped by real source: Chart Demographics, Coding & Billing,
   Status & Workflow, Auditing, Finance & Rates (the BillingFinance columns),
   Productivity, Quality Metrics (Accuracy Score / Audit Rate — both literally on the
   Quality Performance by Facility report), Level of Service, Infusion & Injection,
   Pended Charts, Reconciliation (Mismatch Charge fields).
6. **Columns step** — checkboxes (not buttons) with select-all per group and
   globally, plus native HTML5 drag-and-drop reordering (grab the ⠿ handle).
7. **Subscriptions** — recurring delivery setup (frequency, day, recipients, start/
   end date) persisted via the **Claude.ai artifact `window.storage` API**
   (personal, non-shared). This is real persistence *inside Claude.ai* but **will
   not work as-is outside the artifact sandbox** — see "What needs to change" below.
8. **Review & Generate** (final step — just merged from a separate "Report Basics"
   step) — name/description/format fields live here now, plus a completion
   checklist, data preview, and three outputs: download sample file (xlsx/csv/json
   via SheetJS), download the full JSON spec, or copy a plain-text summary for a
   Jira/RAP ticket.
9. Branded to CorroHealth's actual QBR deck palette (deep purple `#502E6D`, near-
   black purple `#1A0E35`, teal `#1C6A7C`, gold `#E8B626` — extracted from the real
   template's theme/slide fills, not guessed).

## What's explicitly NOT real (be upfront about this with anyone who sees it)

- **No live database or API connection.** This has been said clearly throughout the
  project and should stay true in messaging even after moving to Claude Code,
  until it's actually built.
- Sample data in every preview table is hand-written mock data, not real chart data.
- The JSON "spec" download is meant to be handed to a human/engineer to build the
  real thing — it doesn't submit anywhere.
- Subscriptions don't send anything on a schedule; they just persist the *setup*.

## What moving to Claude Code should actually accomplish

Pick based on what you want next — these are options, not a mandate:

1. **Make it runnable outside Claude.ai.** The biggest blocker is `window.storage`
   (used for subscriptions) — that API only exists inside Claude.ai artifacts. A
   real app needs either `localStorage`/IndexedDB (client-only, still a prototype)
   or a real backend with a database (actual product).
2. **Split the single 2,200-line HTML file into a real project structure** —
   separate JS modules for the field library/templates data, the matching engine,
   the wizard UI, and the subscriptions feature. Right now everything is one
   `<script>` block.
3. **Add real backend integration** — if/when there's appetite to actually submit
   to Pulse instead of producing a spec, that's a new service talking to the real
   `EXPORT_DEFINITION` tables (or ideally the newer API if one exists), with
   whatever auth Pulse already requires.
4. **Expand the template set** — if real DB access becomes available, read the
   actual `REPORT_MAP` static data (not just its SQL schema) to see the full ~100
   report catalog and decide which additional ones are worth templating.
5. **Testing** — the current validation was all manual (Node scripts simulating a
   DOM to exercise the preset/matching logic). A real project should have an actual
   test suite.

## Files in this handoff

- `pulse-report-wizard.html` — the current, working artifact. Open it directly in a
  browser to see exactly where things stand.
- This file (`HANDOFF.md`).

Two other deliverables exist from earlier in the project but aren't code:
`ReportWizard_InternalOnePager.docx` (internal pitch) and
`CorroHealth_QBR_ReportWizard_Slide.pptx` (client-facing "coming soon" slide, built
into the real QBR template). Not needed for the Claude Code work, just context.

---

## Update: pivot to a raw-data self-service station

Direction change: this is now a self-service station for **raw data only**. No formulas or calculations — columns come back exactly as stored, and filters only choose which rows/columns return.

What changed in `index.html` (this folder):
- **Field library trimmed to stored values.** Removed every aggregate/derived field: channel counts and revenue, Total Count/Billed, Blended Rate, Charts Coded/Audited, turnaround, charts/day, utilization %, Accuracy Score, Audit Rate, LOS month/count/percent, infusion counts and avg days, pended totals/revenue/avg days, medication volume. Configured rate values (CCS Rate, Pro Fee Rate, etc.) stay because they are stored facility attributes. "Finance & Rates" is now "Facility & Contract".
- **Templates are row-level views, not report replicas.** The old aggregate reports (Account Activity, Quality Performance, Infusion Overview, Auditor Productivity, Billing Finance rollup, LOS summaries) are gone. Replaced by 8 raw views: Billing Detail, Mismatch Charges, Facility & Rate Setup, Audit Detail, Urgent Care Visits, ED Visits, Infusion & Injection Medications, Pended Charts. They are no longer tagged "Official Pulse report" — column sets for the new ones are *not* verified against Pulse, only the field names carry over.
- **Spec JSON** now includes `AGGREGATION: "none"`.
- **Subscriptions** work outside Claude.ai via a localStorage shim for `window.storage` (still client-only).
- Still no live DB/API; preview rows are mock data.

Open questions: confirm which field IDs map to real EXPORT_FIELD rows; decide whether Facility & Rate Setup rates count as "raw"; add real timestamp fields (coded date, audit date) if wanted — none were invented here.
