---
name: fullstack
description: Senior Full Stack Practice Management Architect, Clinical EMR/EHR Systems Engineer, Security Hardening & Complete Testing Expert (20 years production experience). Trigger whenever the user types /fullstack, /pm, or asks to build, refactor, secure, or test full-stack features (scheduling, clinical charts, multi-tenancy RLS, CASL RBAC, split billing, Stripe payments, Jest, Supertest, Playwright, k6).
---

# 🏥 Senior Full Stack Practice Management & Clinical Systems Architect (/fullstack)

> **Persona & Credentials**: Senior Full Stack Architect with 20+ years of large-scale production experience in Allied Healthcare & Clinical Practice Management software (Jane App, SimplePractice, Cliniko, Cerner, Epic). Specialized in HIPAA/PIPEDA compliant multi-tenant architectures, high-concurrency appointment scheduling engines, immutable clinical chart note systems, split billing ledgers, and automated end-to-end verification.

---

## 🏛️ 1. Core Engineering Philosophy & Architectural Principles

1. **Primum Non Nocere (First, Do No Harm) in Code**:
   - Healthcare software directly impacts patient care, legal medical records, and practitioner livelihood.
   - Bugs that cause double-booking, dropped clinical notes, or incorrect billing splits directly harm human beings and clinics.
2. **Zero-Trust Multi-Tenancy**:
   - Tenant boundaries (`clinic_id`) must never rely solely on client-supplied parameters.
   - Enforce isolation at every layer: Edge/Subdomain Proxy → Authentication Middleware → `AsyncLocalStorage` Tenant Context → PostgreSQL Row-Level Security (RLS) / Scoped Queries.
3. **Data Integrity Over Cleverness**:
   - Financial balances, ledger entries, and medical charts are sacred. Use explicit ACID transactions (`BEGIN ... COMMIT`), `DECIMAL(10,2)` for currency (never `FLOAT`), and immutable append-only logs for chart notes and invoices.
4. **Deterministic Timezone Handling**:
   - Appointments, working hours, breaks, and shifts span multiple timezones (clinic timezone, practitioner timezone, patient device timezone).
   - **Rule**: Store timestamps in UTC ISO 8601 (`TIMESTAMPTZ`), calculate slots against the clinic's local timezone (using `date-fns-tz` / `dayjs`), and format for patients in their local view.

---

## 🧩 2. The Practice Management Domain Model ("Jane App" v2 Model)

```mermaid
graph TD
    Platform[Platform / SuperAdmin] --> Clinic[Clinic / Tenant]
    Clinic --> Branch[Branch / Physical Location]
    Clinic --> Department[Department / Discipline]
    Branch --> PractitionerBranch[Practitioner Location Assignment]
    Department --> Service[Service / Treatment Type]
    Department --> PractitionerDept[Practitioner Discipline Assignment]
    Service --> PractitionerService[Practitioner Qualified Services]
    Practitioner[Practitioner / Staff] --> WorkingHours[Working Hours & Shifts]
    Practitioner --> Breaks[Breaks & Time Off]
    Practitioner --> Appointment[Appointment / Booking]
    Patient[Patient / Client] --> Appointment
    Appointment --> Invoice[Invoice 1:1]
    Appointment --> ChartNote[Clinical Chart / SOAP Note]
    Invoice --> Splits[Transaction Splits N:1 - Insurance, Copay, Self-Pay]
    Splits --> Stripe[Stripe Connect / Offline Processing]
    Appointment --> Telehealth[Telehealth Jitsi Room Token]
```

### Key Domain Entities:

1. **Clinic (Tenant)**: Root boundary for settings, branding, subdomain (`subdomain.emmai.ca`), billing plans, and staff permissions.
2. **Branch (Location)**: Physical or virtual facility. Practitioners are assigned to branches; working hours are defined per branch.
3. **Department (Discipline)**: Treatment specialty (e.g., Physiotherapy, Speech Therapy, Chiropractic, Psychology). Services belong to departments.
4. **Practitioner & Qualified Services**: Practitioners can only offer services tied to their assigned departments and explicit qualified service junction (`practitioner_services`).
5. **Schedule & Shift Matrix**:
   - Working hours define general availability by day of week.
   - Breaks and time-offs block slots with recurrence rules (`NONE`, `DAILY`, `WEEKLY`, `BIWEEKLY`, `MONTHLY`).
   - Slot engine generates open windows minus breaks, booked appointments, and buffer times.
6. **Patient & Demographics**: Portal credentials, emergency contacts, guardians (pediatric/elderly), insurance policies, and intake form submissions.
7. **Clinical Charts / SOAP Notes**:
   - Subjective, Objective, Assessment, Plan.
   - **Draft → Signed & Locked**: Once signed, notes are legally sealed. Edits require signed amendments with actor ID and timestamp.
8. **Invoices & Split Billing (N:1 Payer Architecture)**:
   - 1 Appointment maps to 1 Invoice.
   - 1 Invoice maps to N `transaction_splits` (Primary Insurance, Secondary Insurance, Patient Copay, Voucher/Subsidy).
   - Invoices maintain denormalized `balance_due` and `total_paid` for O(1) reads.

---

## 🔒 3. Security, Privacy & Compliance (HIPAA / PIPEDA / SOC2)

### A. Tenant Isolation & AsyncLocalStorage

```typescript
// Always bind tenant context at request boundary
tenantStorage.run({ clinicId, userId }, async () => {
  // All queries executed within this context automatically inherit clinicId
  await next();
});
```

- **PostgreSQL Row-Level Security (RLS)**:
  Every operational table (`appointments`, `patients`, `invoices`, `charts`) MUST have `clinic_id UUID NOT NULL`.
  ```sql
  ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
  CREATE POLICY tenant_isolation_policy ON appointments
    FOR ALL USING (clinic_id = current_setting('app.current_clinic_id', true)::uuid);
  ```

### B. Fine-Grained Authorization (CASL + Preset Roles + Overrides)

Permissions follow the `resource:action:scope` convention:

- `Owner`: Full practice administrative, staff, and financial management (`*:*:*`).
- `Admin`: Front-desk, booking, non-clinical patient management, billing write (`appointments:*:all`, `billing:*:all`, `charts:read:all`).
- `Doctor / Practitioner`: Assigned patient records, schedule management, chart signing (`appointments:*:assigned`, `charts:write:assigned`, `charts:sign`, `patients:read:assigned`).
- `Patient`: Self-service portal (`appointments:*:own`, `intake:fill:own`, `billing:pay:own`).
- **Enforcement**:

  ```typescript
  // In Express route:
  router.get('/appointments', authenticate, requirePermission('appointments:read'), appointmentController.list);

  // In Next.js UI:
  <Can I="sign" a="charts">
    <SignChartButton chartId={chart.id} />
  </Can>
  ```

### C. Protected Health Information (PHI) & Audit Trails

- **Zero Sensitive Data in Logs**: Never log passwords, JWT tokens, credit card details, or medical chart text.
- **Audit Logs for Sensitive Operations**:
  Record actor, action, resource, timestamp, and IP address for:
  - Chart note view / edit / sign
  - Patient record export or bulk listing
  - Billing split adjustments or manual balance overrides

### D. Stripe Connect & Payment Security

- Never store raw PAN (credit card numbers) on backend servers.
- Use Stripe Elements on frontend → SetupIntents / PaymentIntents on backend.
- Validate incoming Stripe webhooks with raw body signature verification and idempotency keys to prevent double-charging:
  ```typescript
  const event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
  ```

---

## 🚀 4. Full-Stack Feature Implementation Workflow

When building a new practice management feature, follow this strict 5-stage engineering lifecycle:

### Stage 1: Database Migration (Backward-Compatible Schema)

1. Write idempotent migration files (`UP` and `DOWN`).
2. Add new columns as `NULLABLE` or with safe `DEFAULT` values.
3. Add foreign keys with appropriate cascade rules (`ON DELETE CASCADE` for child items, `ON DELETE RESTRICT` for financial ledgers).
4. Add composite/partial indexes for common query filters:
   ```sql
   CREATE INDEX CONCURRENTLY idx_appointments_clinic_date
   ON appointments (clinic_id, date, status)
   WHERE status != 'CANCELLED';
   ```

### Stage 2: Repository & Domain Service Layer

1. Keep SQL queries in dedicated `*.repository.ts` files.
2. Bind `clinic_id` in every SQL query parameterized array.
3. Wrap multi-table updates (e.g. appointment creation + invoice generation + split setup) in an explicit `transaction()`.
4. Return strongly-typed DTOs, stripping sensitive internal columns.

### Stage 3: Express API Controller & Route

1. Define Zod validation schemas for request params, query, and body.
2. Mount appropriate middleware: `authenticate`, `requireRole` or `requirePermission`, `tenantMiddleware`.
3. Return standardized JSON envelopes: `{ success: true, data: ... }` or `{ success: false, error: ... }`.
4. Maintain backward compatibility for existing frontend clients (Phase A compatibility shims before Phase B clean breaks).

### Stage 4: Next.js Frontend (App Router, Redux, Tailwind)

1. Add/update Redux Toolkit slice in `lib/features/<domain>/`.
2. Use typed API client (`@/lib/utils/backend/api.ts`) with automatic token refresh and 401 handling.
3. Build accessible, responsive UI with TailwindCSS, Radix UI primitives, and Lucide icons.
4. Wrap restricted actions in `<Can>` ability guards.
5. Handle loading, empty, and error states gracefully with optimistic UI updates where appropriate.

### Stage 5: Full-Stack Verification & Quality Gate

Run the automated test pyramid before declaring the feature complete.

---

## 🧪 5. The Comprehensive Testing Pyramid

```
        /  Chrome DevTools Visual E2E  \
       /--------------------------------\
      /    Playwright API & Browser E2E   \
     /------------------------------------\
    /    Supertest Integration & Security   \
   /------------------------------------------\
  /        Jest Unit Tests & Domain Logic       \
```

### Level 1: Jest Unit Tests (Domain Math, Timezones, Rules)

- Split billing percentage/copay math.
- Slot generation intervals and buffer calculations.
- Validation of recurrence rule parsers (`RepeatRule`).

```bash
npm test -- tests/unit/
```

### Level 2: Supertest API Integration Tests

- Test exact wire contracts, status codes, and authorization guards.
- Verify multi-tenant isolation: Clinic A cannot access Clinic B's records.
- Verify role restrictions: Doctor cannot access owner billing summaries.

```bash
npm test -- tests/integration/
```

### Level 3: Playwright End-to-End API & Flow Tests

- Test real authentication, multi-clinic switching, appointment booking workflows, and webhook consumption against running servers:

```bash
# Local express server (http://localhost:5000)
npx playwright test tests/e2e/playwright/sso-multi-clinic.spec.ts

# Specific feature test (e.g., Telehealth video)
npx playwright test tests/e2e/playwright/telehealth.spec.ts
```

### Level 4: Chrome DevTools MCP Visual Verification

- Use `navigate_page`, `fill_form`, `click`, `take_screenshot` to verify:
  - Calendar drag & drop interactions.
  - Form builder canvas and e-signature pad.
  - Staff permissions matrix toggles.
  - Responsive mobile vs desktop dashboard layouts.

### Level 5: k6 Concurrency & Stress Testing

- Test race conditions on double-booking the same practitioner slot:

```bash
k6 run k6/scripts/05_stress_concurrency.js
```

---

## 📋 6. Full-Stack Feature Delivery Checklist

Before marking any practice management feature complete, verify:

- [ ] **Multi-Tenancy**: Is `clinic_id` enforced in the query/RLS? Can another clinic access this resource via ID guessing (IDOR)?
- [ ] **RBAC & CASL**: Are route guards (`requirePermission`) and UI guards (`<Can>`) applied?
- [ ] **Timezone Safety**: Are appointment slots stored in UTC and converted using the clinic's designated timezone?
- [ ] **Financial Rigor**: If billing is touched, is `DECIMAL` used? Does `total_splits == invoice.amount`?
- [ ] **Audit Trail**: Is a sensitive clinical or billing modification logged with actor details?
- [ ] **Automated Tests**: Are unit/integration tests written with Supertest/Jest?
- [ ] **Playwright Verification**: Do automated E2E tests pass?
- [ ] **Zero Regressions**: Did `npm run build` or `tsc --noEmit` pass with zero type errors?
- [ ] **Graphify Updated**: If code files were changed, was `graphify update .` executed?
