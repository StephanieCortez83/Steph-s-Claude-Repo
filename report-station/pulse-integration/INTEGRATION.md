# Data Station — Pulse 2.0 integration

Self-service **raw-data** export as a Pulse 2.0 menu item (Analytics ▸ Data Station), gated by a Pulse user right.
Every column is a stored value returned as-is — no formulas, totals, rates or scores.

> **Status: written against the real Pulse 2.0 code as read through the Sage model, but NOT compiled or run
> inside Pulse.** The TypeScript was type-checked and the pure-function tests pass in a scratch project with
> stand-ins for Pulse imports. The C# could not be built here (no .NET SDK). Treat all of it as a reviewed draft.

## What's in this folder (new files — copy into the Pulse 2.0 repo at the same paths)

| Path | Purpose |
|---|---|
| `database/RevCycleDB/migrations/V044_…__DataStation-AddRights.sql` (+ `U044_…`) | Adds rights **172** `AllowAccessToDataStation` and **173** `AllowDataStationUnmaskedPhi` to `DEFINED_RIGHT` (idempotent) |
| `backend/modules/ACS.Modules.Charts/Features/ExportDataStation/` | `ExportDataStationQuery` (+ validator, handler) and `DataStationFields` (the column catalog + PHI masking) |
| `backend/modules/ACS.Modules.Charts/Features/GetDataStationFields/` | Column catalog + limits for the UI |
| `backend/ACS.Api/Endpoints/DataStationEndpoints.cs` | `GET /api/data-station/fields`, `POST /api/data-station/export` |
| `backend/tests/ACS.Modules.Charts.Tests/Features/ExportDataStationQueryHandlerTests.cs` | Handler + validator tests |
| `frontend/src/features/dataStation/` | `DataStationPage.tsx`, `dataStationApi.ts`, `buildExportRequest.ts` (+ vitest test) |

## Edits to existing Pulse files

### 1. `backend/ACS.Shared/Contracts/UserRight.cs`
Add next to the other constants (after `NewFeaturePbi = 171`):
```csharp
	public const int AllowAccessToDataStation = 172;
	public const int AllowDataStationUnmaskedPhi = 173;
```

### 2. `frontend/src/lib/userRights.ts`
Add inside the `UserRight` object:
```ts
	AllowAccessToDataStation:                   172,
	AllowDataStationUnmaskedPhi:                173,
```

### 3. Register the endpoints
Wherever `ChartEndpoints.Map(app)` is called (not visible in the model — likely `Program.cs`), add:
```csharp
DataStationEndpoints.Map(app);
```
MediatR handlers/validators in `ACS.Modules.Charts` are assumed to be picked up by the module's existing
assembly scan (`ChartsModule.cs`); if registration is explicit, add the handler, the fields handler and the validator.

### 4. `frontend/src/components/AppShell/AppShell.tsx` — menu item, hidden without the right
```tsx
// imports
import { UserRight } from '../../lib/userRights';
import { selectRights } from '../../store/authSlice';
// (useAppSelector is already imported from '../../store')

// NavItem link variant: add an optional right
type NavItem =
  | { type: 'link'; label: string; path: string; testId?: string; requiredRight?: number }
  | { type: 'divider' }
  | { type: 'submenu'; label: string; items: NavLinkItem[] };

// ANALYTICS_MENU.items: add
    { type: 'link', label: 'Data Station', path: '/analytics/data-station',
      testId: 'nav-data-station', requiredRight: UserRight.AllowAccessToDataStation },

// NavDropdown: filter by rights (first lines of the component)
  const rights = useAppSelector(selectRights);
  const items = menu.items.filter(
    (i) => i.type !== 'link' || i.requiredRight === undefined || rights.includes(i.requiredRight),
  );
// …and render `items.map(...)` instead of `menu.items.map(...)`.
```
Note: today **no** existing menu item is right-gated, so this adds the first gating mechanism; it only hides the
link — the API still enforces the right.

### 5. `frontend/src/App.tsx`
```tsx
import DataStationPage from './features/dataStation/DataStationPage';
// inside the AppShell <Route>, near the other routes:
<Route path="analytics/data-station" element={<DataStationPage />} />
```
`DataStationPage` renders a "no access" message itself when the user lacks the right (direct URL visits).

### 6. Grant the right
Use the existing **Management ▸ Administration ▸ User Group Rights** screen to grant 172 to the user groups that should
see it, and 173 only to the few who may export unmasked PHI.

## How access is enforced (defense in depth)

| Layer | Check |
|---|---|
| Menu | link hidden unless user has 172 |
| Page | "no access" message unless 172 |
| API | `ExportDataStationQuery` has `[HasRight(172)]` **and** `[HasRight(32)]` (multiple attributes are AND-ed) |
| Data | `IChartSearchRepository.ExportAsync` still enforces facility authorization + bulk-search right, same as chart export |
| PHI | masking is the default; `MaskPhi=false` is rejected in the handler unless the user holds 173 |

## Behaviors worth knowing
- **Columns** = the columns the live chart export returns (30 of its 34; the four internal `*_ID` columns are left out).
- **Row cap** 3001, same as chart export. The UI shows it; the response does not yet flag truncation.
- **Masking:** name → initials, MRN / long patient ID → last 4, date of birth → year only, client comment / coder notes
  (free text, may contain PHI) → `[withheld]`. DOB and free-text rules go beyond `ExportChartsView`'s name + MRN rule — confirm with compliance.
- **CSV/Excel injection:** stored text starting with `= + - @` is prefixed with `'` so opening the file never executes a formula.
  Excel cells are always written as text.
- Filters are the existing `ExportChartsQuery` contract and are validated by the existing `ExportChartsQueryValidator`.

## Assumptions to verify (I could not see these)
1. `ICurrentUserService` namespace and DI registration (used in the handler and tests).
2. Test stack is xunit + FluentValidation.TestHelper; frontend tests use vitest.
3. `ExportChartsResult(Stream, string, string)` constructor shape (copied from the existing handler).
4. Right numbers **172/173** are free in every environment; Flyway version `V044` is the next free one.
5. MUI v6+ (`slotProps`), as already used in `AppShell.tsx`. Auth: `useAuth().getAccessToken()` returns a bearer token the API accepts.
6. System.Text.Json (camelCase) binds the `ExportChartsQuery` record from the request body.

## Open items
- **Facility / status pickers.** The page takes facility and status **IDs as text**. Add `GET /api/data-station/options`
  (authorized facilities — reuse the facility-authorization query behind `IChartSearchRepository` — plus chart statuses)
  and swap the two text boxes for pickers (marked `TODO` in the page and endpoints file).
- Truncation flag when the 3001-row cap is hit.
- More filters from `ExportChartsQuery` (MRN, provider NPI, location, pending reason, assigned coder…).
- Optional: Pulse's `REPORT_SUBSCRIPTION` for scheduled delivery; audit logging of unmasked exports.
- Add a help page (`/help/...`) — `AppShell` links page help by pathname slug.
