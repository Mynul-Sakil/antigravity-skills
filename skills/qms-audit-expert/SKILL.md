---
name: qms-audit-expert
description: "ISO 13485 medical-device QMS internal & external audit management: optimize risk-based schedules (audit_schedule_optimizer.py), classify nonconformities, verify CAPA & DHF traceability, and run pre-launch/MDR/QMSR forcing questions."
---

# QMS Audit Expert

ISO 13485 internal audit methodology for medical device quality management systems.

---

## Table of Contents

- [Audit Planning Workflow](#audit-planning-workflow)
- [Audit Execution](#audit-execution)
- [Nonconformity Management](#nonconformity-management)
- [External Audit Preparation](#external-audit-preparation)
- [Reference Documentation](#reference-documentation)
- [Tools](#tools)

---

## Audit Planning Workflow

Plan risk-based internal audit program:

1. List all QMS processes requiring audit
2. Assign risk level to each process (High/Medium/Low)
3. Review previous audit findings and trends
4. Determine audit frequency by risk level
5. Assign qualified auditors (verify independence)
6. Create annual audit schedule
7. Communicate schedule to process owners
8. **Validation:** All ISO 13485 clauses covered within cycle

### Risk-Based Audit Frequency

| Risk Level | Frequency | Criteria |
|------------|-----------|----------|
| High | Quarterly | Design control, CAPA, production validation |
| Medium | Semi-annual | Purchasing, training, document control |
| Low | Annual | Infrastructure, management review (if stable) |

### Audit Scope by Clause

| Clause | Process | Focus Areas |
|--------|---------|-------------|
| 4.2 | Document Control | Document approval, distribution, obsolete control |
| 5.6 | Management Review | Inputs complete, decisions documented, actions tracked |
| 6.2 | Training | Competency defined, records complete, effectiveness verified |
| 7.3 | Design Control | Inputs, reviews, V&V, transfer, changes |
| 7.4 | Purchasing | Supplier evaluation, incoming inspection |
| 7.5 | Production | Work instructions, process validation, DHR |
| 7.6 | Calibration | Equipment list, calibration status, out-of-tolerance |
| 8.2.2 | Internal Audit | Schedule compliance, auditor independence |
| 8.3 | NC Product | Identification, segregation, disposition |
| 8.5 | CAPA | Root cause, implementation, effectiveness |

### Auditor Independence

Verify auditor independence before assignment:

- [ ] Auditor not responsible for area being audited
- [ ] No direct reporting relationship to auditee
- [ ] Not involved in recent activities under audit
- [ ] Documented qualification for audit scope

---

## Audit Execution

Conduct systematic internal audit:

1. Prepare audit plan (scope, criteria, schedule)
2. Review relevant documentation before audit
3. Conduct opening meeting with auditee
4. Collect evidence (records, interviews, observation)
5. Classify findings (Major/Minor/Observation)
6. Conduct closing meeting with preliminary findings
7. Prepare audit report within 5 business days
8. **Validation:** All scope items covered, findings supported by evidence

### Evidence Collection

| Method | Use For | Documentation |
|--------|---------|---------------|
| Document review | Procedures, records | Document number, version, date |
| Interview | Process understanding | Interviewee name, role, summary |
| Observation | Actual practice | What, where, when observed |
| Record trace | Process flow | Record IDs, dates, linkage |

### Audit Questions by Clause

**Document Control (4.2):**
- Show me the document master list
- How do you control obsolete documents?
- Show me evidence of document change approval

**Design Control (7.3):**
- Show me the Design History File for [product]
- Who participates in design reviews?
- Show me design input to output traceability

**CAPA (8.5):**
- Show me the CAPA log with open items
- How do you determine root cause?
- Show me effectiveness verification records

See `references/iso13485-audit-guide.md` for complete question sets.

### Finding Documentation

Document each finding with:

```
Requirement: [Specific ISO 13485 clause or procedure]
Evidence: [What was observed, reviewed, or heard]
Gap: [How evidence fails to meet requirement]
```

**Example:**
```
Requirement: ISO 13485:2016 Clause 7.6 requires calibration
at specified intervals.

Evidence: Calibration records for pH meter (EQ-042) show
last calibration 2024-01-15. Calibration interval is
12 months. Today is 2025-03-20.

Gap: Equipment is 2 months overdue for calibration,
representing a gap in calibration program execution.
```

---

## Nonconformity Management

Classify and manage audit findings:

1. Evaluate finding against classification criteria
2. Assign severity (Major/Minor/Observation)
3. Document finding with objective evidence
4. Communicate to process owner
5. Initiate CAPA for Major/Minor findings
6. Track to closure
7. Verify effectiveness at follow-up
8. **Validation:** Finding closed only after effective CAPA

### Classification Criteria

| Category | Definition | CAPA Required | Timeline |
|----------|------------|---------------|----------|
| Major | Systematic failure or absence of element | Yes | 30 days |
| Minor | Isolated lapse or partial implementation | Recommended | 60 days |
| Observation | Improvement opportunity | Optional | As appropriate |

### Classification Decision

```
Is required element absent or failed?
├── Yes → Systematic (multiple instances)? → MAJOR
│   └── No → Could affect product safety? → MAJOR
│       └── No → MINOR
└── No → Deviation from procedure?
    ├── Yes → Recurring? → MAJOR
    │   └── No → MINOR
    └── No → Improvement opportunity? → OBSERVATION
```

### CAPA Integration

| Finding Severity | CAPA Depth | Verification |
|------------------|------------|--------------|
| Major | Full root cause analysis (5-Why, Fishbone) | Next audit or within 6 months |
| Minor | Immediate cause identification | Next scheduled audit |
| Observation | Not required | Noted at next audit |

See `references/nonconformity-classification.md` for detailed guidance.

---

## External Audit Preparation

Prepare for certification body or regulatory audit:

1. Complete all scheduled internal audits
2. Verify all findings closed with effective CAPA
3. Review documentation for currency and accuracy
4. Conduct management review with audit as input
5. Prepare facility and personnel
6. Conduct mock audit (full scope)
7. Brief personnel on audit protocol
8. **Validation:** Mock audit findings addressed before external audit

### Pre-Audit Readiness Checklist

**Documentation:**
- [ ] Quality Manual current
- [ ] Procedures reflect actual practice
- [ ] Records complete and retrievable
- [ ] Previous audit findings closed

**Personnel:**
- [ ] Key personnel available during audit
- [ ] Subject matter experts identified
- [ ] Personnel briefed on audit protocol
- [ ] Escorts assigned

**Facility:**
- [ ] Work areas organized
- [ ] Documents at point of use current
- [ ] Equipment calibration status visible
- [ ] Nonconforming product segregated

### Mock Audit Protocol

1. Use external auditor or qualified internal auditor
2. Cover full scope of upcoming external audit
3. Simulate actual audit conditions (timing, formality)
4. Document findings as for real audit
5. Address all Major and Minor findings before external audit
6. Brief management on readiness status

---

## Reference Documentation

### ISO 13485 Audit Guide

`references/iso13485-audit-guide.md` contains:

- Clause-by-clause audit methodology
- Sample audit questions for each clause
- Evidence collection requirements
- Common nonconformities by clause
- Finding severity classification

### Nonconformity Classification

`references/nonconformity-classification.md` contains:

- Severity classification criteria and decision tree
- Impact vs. occurrence matrix
- CAPA integration requirements
- Finding documentation templates
- Closure requirements by severity

---

## Tools

### Audit Schedule Optimizer

```bash
# Generate optimized audit schedule
python scripts/audit_schedule_optimizer.py --processes processes.json

# Interactive mode
python scripts/audit_schedule_optimizer.py --interactive

# JSON output for integration
python scripts/audit_schedule_optimizer.py --processes processes.json --output json
```

Generates risk-based audit schedule considering:
- Process risk level
- Previous findings
- Days since last audit
- Criticality scores

**Output includes:**
- Prioritized audit schedule
- Quarterly distribution
- Overdue audit alerts
- Resource recommendations

### Sample Process Input

```json
{
  "processes": [
    {
      "name": "Design Control",
      "iso_clause": "7.3",
      "risk_level": "HIGH",
      "last_audit_date": "2024-06-15",
      "previous_findings": 2
    },
    {
      "name": "Document Control",
      "iso_clause": "4.2",
      "risk_level": "MEDIUM",
      "last_audit_date": "2024-09-01",
      "previous_findings": 0
    }
  ]
}
```

---

## Audit Program Metrics

Track audit program effectiveness:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Schedule compliance | >90% | Audits completed on time |
| Finding closure rate | >95% | Findings closed by due date |
| Repeat findings | <10% | Same finding in consecutive audits |
| CAPA effectiveness | >90% | Verified effective at follow-up |
| Auditor utilization | 4 days/month | Audit days per qualified auditor |

## More in this skill

Load these only when the task needs them.

- [references/iso13485_audit_playbook.md](references/iso13485_audit_playbook.md) — ISO 13485:2016 Internal Audit Playbook


---

## ISO 13485 DHF, CAPA & Traceability Readiness Gate (`iso13485-audit-prep`)

# /compliance-os:iso13485-audit-prep — ISO 13485 QMS Forcing Questions

**Command:** `/compliance-os:iso13485-audit-prep <scope>`

The ISO 13485 QMS auditor pressure-tests any medical-device QMS work. Six traceability-obsessed questions before any internal audit, MDR / FDA QSR review, or product launch.

## When to Run

- Before annual Clause 8.2.4 internal audit
- Before MDR / FDA QSR alignment review (substantially harmonized post Feb 2026)
- Before new-device commercial launch (DHF closure audit)
- After significant CAPA closure event (effectiveness verification audit)
- Post-recall event (root cause + corrective action audit)
- Quarterly during regulatory submission preparation

## The Six QMS Questions

### 1. Pull three random DHFs. Are design verification + validation evidence complete?
**Most-cited finding area.**
- DHF must include: design plan + inputs + outputs + verification + validation + transfer + changes
- Sample stratified by product class (I, IIa, IIb, III per MDR)
- Reference `iso13485_audit_playbook.md` for the per-DHF checklist
- Verify traceability matrix from user needs through clinical evidence

### 2. Show me the last 5 CAPAs with effectiveness verification evidence.
**Second-most-cited finding area.**
- Containment / correction / corrective action distinction documented
- Root cause analysis depth: 5 Why minimum
- Effectiveness verification = measurable evidence, not "we updated the procedure"
- Closure approved by appropriate authority
- Repeat CAPAs across products = systemic issue trigger

### 3. When was process validation (IQ/OQ/PQ) last revalidated?
**Clause 7.5.6 — often stale.**
- Initial validation at process introduction
- Revalidation triggers: process change, equipment change, material change, periodic schedule
- Trend monitoring (SPC) where statistical techniques apply per Clause 8.4
- Cross-check with cs-fda-qsr-auditor for 21 CFR 820.75 alignment

### 4. Show me the risk management file for the highest-risk product.
**Clause 7.1 + ISO 14971:2019.**
- Risk management plan exists per product
- Hazard identification covers reasonable foreseeable misuse
- Risk control hierarchy applied: inherent safety > protective measures > information for safety
- Residual risk evaluated + accepted with rationale
- Post-production information feeds back into RMF
- For AI-enabled medical devices: layer ISO 42001 A.5 impact assessment on top

### 5. Show me post-market surveillance evidence — last 6 months.
**Clause 8.2.1 — high-stakes for MDR + FDA.**
- Customer complaint log + investigation closure
- Vigilance reports (serious incident / FSCA) submitted per applicable regulation
- Trend analysis evidence + management review input
- Post-market clinical follow-up (PMCF) for MDR high-risk devices
- MDR reports per 21 CFR 803 for US-marketed devices (cross-check with cs-fda-qsr-auditor)

### 6. Where's the management review evidence covering all Clause 5.6 inputs?
**Annual minimum; semi-annual for mature programs.**
- Required inputs per Clause 5.6.2: audit results, customer feedback, process performance, product conformity, status of preventive + corrective actions, follow-up from prior reviews, changes that could affect QMS, recommendations for improvement, regulatory requirements
- Outputs per Clause 5.6.3: improvement decisions, product requirement changes, resource needs
- Integrated review across frameworks (per `multi_framework_audit_playbook.md`) preferred

## Workflow

```bash
# 1. Audit programme optimization
python scripts/audit_schedule_optimizer.py audit_scope.json

# 2. Mock audit for readiness check
python ../compliance-os/scripts/audit_simulator.py iso13485_scope.json

# 3. CAPA system review
# Route to ../capa-officer/ tools

# 4. Risk management file review
# Route to ../risk-management-specialist/ tools
```

## Output Format

```markdown
# ISO 13485 Audit Prep: <scope>
**Date:** YYYY-MM-DD

## The Decision Being Made
[programme-plan | DHF-closure | CAPA-health | post-market-trend | pre-cert | MDR-FDA-alignment]

## Design Control Status (sampled DHFs)
- DHFs sampled: <list product IDs>
- Verification evidence: pass/fail per DHF
- Validation evidence: pass/fail per DHF
- Clinical evidence (per MDR Annex XIV / FDA 510(k)): pass/fail
- Traceability matrix complete: yes/no per DHF

## CAPA Health
- CAPAs sampled: N
- Root cause analysis depth: adequate/inadequate per CAPA
- Effectiveness verification: complete/incomplete per CAPA
- Aging CAPAs > 90 days: N
- Repeat issues across products: <list>

## Process Validation Status
- Validations on schedule: %
- Stale validations (> 12 months since revalidation): <list>
- Statistical techniques applied per Clause 8.4: yes/no

## Risk Management File Status
- Sampled product RMFs: <list>
- Post-production updates in last 12 months: <count per product>
- Residual risk acceptance signed: yes/no

## Post-Market Surveillance
- Complaint trending: stable/rising
- MDR / vigilance reports filed timely: %
- PMCF on schedule (where required): yes/no

## Management Review Status
- Last review date: YYYY-MM-DD
- Required Clause 5.6.2 inputs present: yes/no
- Open action items past due: N

## Cross-Framework Impact
- EU MDR alignment: clean / gaps in <list>
- FDA QSR alignment (post-Feb 2026): substantially harmonized; FDA-specific overlays per cs-fda-qsr-auditor
- ISO 42001 AIMS overlay (if AI-enabled device): pass/fail per Annex A

## Verdict
🟢 READY | 🟡 CLOSE-DHF-GAPS-FIRST | 🔴 NOT-READY

## Top 3 Actions
[3 concrete next steps with owner + corrective-action timeline]
```

## Routing

- `/compliance-os:compliance-readiness` — for multi-framework view
- `/compliance-os:fda-qsr-audit-prep` — for FDA-specific overlay
- `/compliance-os:aims-audit` — for AI-enabled medical device ISO 42001 layer
- `/compliance-os:gdpr-audit-prep` — for personal-data overlap (clinical data, customer data)
- `/c-level-agents:cpo-review` — for executive product strategy decisions
- `/c-level-agents:decide` — to log the verdict

## Related

- Agent: [`cs-cqm-iso13485`](../../agents/cs-cqm-iso13485.md)
- Skill: [`qms-audit-expert`](SKILL.md)
- Playbook: [iso13485_audit_playbook.md](references/iso13485_audit_playbook.md)
- Adjacent: `../fda-qsr-audit-prep/`, `../aims-audit/`, `../compliance-readiness/`

---

**Version:** 1.0.0
