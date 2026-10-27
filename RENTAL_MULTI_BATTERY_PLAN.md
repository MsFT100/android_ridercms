# Rider App Plan — Multiple Batteries + Rental Battery Flow

Companion to `PARITY_PLAN.md`. This document is scoped to the two rider
features that currently exist in the web app (`RIDERCMS3/`) and are missing or
broken in the Flutter app (`android_ridercms/`):

1. **Multiple deposited batteries** — a rider can deposit N of their own
   batteries (different slots/booths) and manage each one independently.
2. **Rental batteries** — the full 15-step rental lifecycle
   (issue → collect → use → return → bill → pay → unlock own battery).

The backend (`ridercmsV1/`) already implements everything. **No backend
changes are required.** This is a client parity effort.

---

## 1. Source of truth (web implementation)

| Concern | Web file |
|---|---|
| Multi-battery state + deposit polling | `RIDERCMS3/components/UserDashboard.tsx` |
| Multi-battery list UI | `RIDERCMS3/components/user/MultiBatteryStatus.tsx` |
| Single-battery charging UI | `RIDERCMS3/components/user/ChargingStatusView.tsx` |
| Rental bootstrap / resume | `RIDERCMS3/components/user/RentalPage.tsx` |
| Rental state machine (15 steps) | `RIDERCMS3/components/user/RentalFlow.tsx` |
| Rental step screens | `RIDERCMS3/components/user/rental/*.tsx` |
| API contracts | `RIDERCMS3/services/boothService.ts` |
| Entry-point state | `RIDERCMS3/types.ts` → `ActiveBatteryEntry` |

Web model, for reference:

```ts
interface ActiveBatteryEntry {
  battery: Battery;   // chargeLevel, temperature, voltage
  slot: Slot;         // identifier, doorStatus, status
  sessionId: number;
  boothUid?: string;
}
```

`UserDashboard` keeps `activeBatteries: ActiveBatteryEntry[]` plus
`activeBatteryIndex`, and renders either `MultiBatteryStatus` (N > 1) or
`ChargingStatusView` (N === 1).

---

## 2. Verified API contract (what the app must send/receive)

All routes are under `/api/booths` and require `Authorization: Bearer <token>`.

| # | Method + path | Request | Response (shape that matters) |
|---|---|---|---|
| 1 | `GET /my-battery-status` | – | **ARRAY** of `{ sessionId, boothUid, slotIdentifier, chargeLevel, lastChargeLevel, sessionStatus, telemetry }`. `200 null` when none. May return `304` (ETag) with empty body. |
| 2 | `POST /initiate-deposit` | `{ boothUid }` | `{ slot: { identifier, … }, sessionId }` |
| 3 | `GET /deposit-sessions/:sessionId/status` | – | `{ sessionId, sessionStatus }` (terminal states `cancelled` / `failed`) |
| 4 | `POST /stop-charging` | `{ sessionId }` | `{ message, boothUid, slotIdentifier, socAtStopRequest, relayAlreadyOff, recommendedWaitSeconds }` |
| 5 | `POST /initiate-withdrawal` | `{ sessionId }` | `{ sessionId (withdrawal), amount, durationMinutes, soc, … }` |
| 6 | `POST /sessions/:sessionId/pay` | – | `{ checkoutRequestId }` |
| 7 | `GET /withdrawal-status/:checkoutRequestId` | – | `{ paymentStatus }` |
| 8 | `POST /cancel-session` / `POST /sessions/:id/cancel` | – | – |
| 9 | `GET /rentals/status` | – | `{ enabled, requireBoothScanBeforeIssue, requireReturnScan, allowRentalWhileOwnBatteryCharging, maxRentalBatteriesPerUser, minimumSocPercent }` |
| 10 | `GET /rentals/available?boothUid=` | – | `{ boothUid, rentals: [{ slotId, slotIdentifier, batteryId, batteryUid, chargeLevel }], hasPendingRental, rentalLimit, activeRentalCount }` |
| 11 | `POST /rentals/issue` | `{ boothUid, slotIdentifier }` | `{ sessionId, batteryUid, chargeLevel, status, ownDeposit }` |
| 12 | `GET /rentals/active` | – | active rental object, or `204` when none |
| 13 | `POST /rentals/:sessionId/return` | `{ boothUid }` | `{ returnSlot: { boothUid, slotIdentifier }, batteryUid, … }` |
| 14 | `GET /rentals/:sessionId/bill` | – | `{ amount, consolidation: { ownCharging, rentalEnergy, rentalTime, durationMinutes, … } }` |
| 15 | `POST /rentals/:sessionId/pay` | – | `{ checkoutRequestId, amount, paymentStatus? }` |
| 16 | `GET /rentals/status/:checkoutRequestId` | – | `{ paymentStatus }` |
| 17 | `POST /rentals/:sessionId/unlock-own` | – | `{ ownSlot: { boothUid, slotIdentifier } }` |

Rider-facing gates enforced by the server (the app must mirror them):
`enabled === false` → hide rental entry; `requireBoothScanBeforeIssue` → booth
QR gate before issue; `requireReturnScan` → booth QR gate before return;
`maxRentalBatteriesPerUser`; `minimumSocPercent`.

---

## 3. Gap analysis — Android today

### 3.1 Blocking contract bugs (fix first, they break even single-battery)

| # | Bug | Where | Impact |
|---|---|---|---|
| B1 | `getMyBatteryStatus()` decodes **one object**, but `/my-battery-status` returns an **array**. `MyBatteryStatus.fromJson(List)` throws → caught → `null`. | `lib/services/booth_service.dart:52-76` | App **never** detects an active session. Multi-battery is impossible. |
| B2 | `MyBatteryStatus.batteryUid` is not in the API response → always `''`. | `lib/models/booth_models.dart:63-90` | No usable battery identity. |
| B3 | `stopCharging(token)` and `initiateWithdrawal(token)` send **no body**, but the backend requires `{ sessionId }`. | `lib/services/booth_service.dart:99-141` | Withdrawal always 400s. Blocks per-battery collect. |
| B4 | `initiateDeposit` result parsed as `depositResult['slotIdentifier']`; real shape is `{ slot: { identifier }, sessionId }`. | `lib/controllers/scan_controller.dart:52-65` | Slot screen can show `null`; wrong slot. |
| B5 | `getPendingWithdrawal()` returns a *withdrawal* session; `PaymentController` falls back to `initiateWithdrawal(token)` without a session id. | `lib/controllers/payment_controller.dart:44-49` | Payment cannot resume correctly with multiple batteries. |
| B6 | No `deposit-sessions/:id/status` call → a booth-side auto-cancel leaves the app stuck on "waiting for confirmation". | `slot_assigned_controller.dart` | UX dead end. |

### 3.2 Missing features

| Feature | Android status | Work |
|---|---|---|
| Multiple deposits | Single-slot model in `ChargingController` (`Rxn<MyBatteryStatus>`, one Firebase listener), single "Active Session" route. | Multi-list state, per-battery listener, multi-status screen, "Add another battery". |
| Rental flow | **Zero** rental references in `lib/`. | Models, service, controller, 15 screens, routes, dashboard entry, resume. |
| Rental availability / gates | Absent. | Fetch `/rentals/status` + `/rentals/available`, auto-pick highest SOC, honour scan gates. |
| Transaction history | "Coming Soon". | Optional follow-up (see `PARITY_PLAN.md` Phase 3). |

### 3.3 Web-side (RIDERCMS3) issues found while reviewing the changes

These are small but worth fixing so both clients agree:

| # | Finding | Location |
|---|---|---|
| W1 | Temperature is read as `telemetry?.temperatureC` only. Real device payloads may carry only `temperature`. Use `telemetry?.temperature ?? telemetry?.temperatureC` (same rule just applied to the admin booths API). | `UserDashboard.tsx:741-744, 964-967, 1161-1164` |
| W2 | `openRental` ignores `maxRentalBatteriesPerUser`; a rider at the limit gets a toast from a 409 instead of a disabled button. | `UserDashboard.tsx:344-471` |
| W3 | `lastChargeLevel` from `/my-battery-status` is never used as a fallback when `telemetry` is `null`. | `UserDashboard.tsx:723-800` |
| W4 | `battery.id` is set to the **slot** identifier (`s.slotIdentifier`), so the UI prints `ID: slot001`. Show "Own battery" / booth + slot instead. | `UserDashboard.tsx:730-751` |
| W5 | `rentalBatteries` state is written but never rendered (dead state). Either use it for the availability badge or remove it. | `UserDashboard.tsx:141-151, 287-331` |
| W6 | Restored entries hardcode `slot.doorStatus = 'locked'` until the first poll (up to 2 s). Derive it from `telemetry.doorLocked`. | `UserDashboard.tsx:753-766` |
| W7 | `handleScanSuccess` appends without de-duping; a repeated deposit on the same slot produces a duplicate card. | `UserDashboard.tsx:1344-1389` |
| W8 | No direct "My Batteries" entry point; the multi-status view is only reachable from the deposit/charging views. | `UserDashboard.tsx` render |

W1 is the same class of bug as the admin fix, so it is worth doing in the same
pass. W2–W8 are polish and can be bundled with the parity work.

---

## 4. Android implementation plan

### Phase 0 — Contract fixes (½ day, unblocks everything)

**`lib/models/booth_models.dart`**
- `MyBatteryStatus`: drop `batteryUid`; add `sessionId` (int), `lastChargeLevel`
  (int), typed `BatteryTelemetry` (`soc`, `temperature`, `temperatureC`,
  `voltage`, `doorLocked`, `batteryInserted`, `relayOn`, …).
- Add `listFromJson(List<dynamic>)`.
- Add `DepositSessionStatus`.

**`lib/services/booth_service.dart`**
- `Future<List<MyBatteryStatus>> getMyBatteryStatuses(token)`:
  - `200` + array → parse; `200` + `null` → `[]`; `204` → `[]`;
  - send `If-None-Match` when an ETag is cached and treat `304` as "unchanged".
- `stopCharging(token, int sessionId)` → body `{ sessionId }`.
- `initiateWithdrawal(token, int sessionId)` → body `{ sessionId }`.
- `cancelActiveSessionById(token, int sessionId)`.
- `getDepositSessionStatus(token, int sessionId)`.
- One shared `_errorMessage(response)` helper that surfaces
  `message` / `error` and known codes (`ACTIVE_RENTAL_EXISTS`,
  `RENTAL_LIMIT_REACHED`, `ACTIVE_WITHDRAWAL_EXISTS`).

**`lib/controllers/scan_controller.dart`** — parse `depositResult['slot']['identifier']`
and pass `sessionId` down to `/slot-assigned`.

**Acceptance:** with one battery deposited, the app shows the charging screen
with live SOC/temperature; "Collect" reaches the payment screen.

### Phase 1 — Multi-battery (1–1.5 days)

**`lib/controllers/charging_controller.dart`** (rewrite)
```dart
var batteries = <MyBatteryStatus>[].obs;      // replaces Rxn<MyBatteryStatus>
var activeIndex = 0.obs;
final Map<String, StreamSubscription> _listeners = {};
```
- `refreshBatteries()` → `getMyBatteryStatuses()`, diff by
  `boothUid + slotIdentifier` (fallback `sessionId`).
- One Firebase listener per battery at `booths/{boothUid}/slots/{slotIdentifier}`;
  cancel listeners for batteries that disappear. Update only that entry.
- `hasAnyBattery()`, `activeBattery`, `stopChargingAt(index)`,
  `collectAt(index)`.
- Poll every **2 s** while the multi/charging screen is visible; pause when the
  app is backgrounded.

**New `lib/screens/home/multi_battery_status_screen.dart`** (port
`MultiBatteryStatus.tsx`)
- Header "Your Batteries" + "+ Add Battery".
- Per battery: SOC ring, `Temp`, `Voltage`, door badge
  (`locked` green / otherwise red+pulse), booth + slot, and
  **Collect Battery & Pay** disabled below 20 % SOC.
- Pull-to-refresh; empty state → dashboard.

**`lib/screens/home/dashboard_screen.dart`**
- "Active Session" → `/batteries` when `batteries.length > 1`, else `/charging`.
- "Scan Battery" stays enabled while batteries are charging (that is how you
  add another); show count badge.
- New "Rent a Battery" action (hidden when `enabled === false`).

**`lib/screens/home/slot_assigned_screen.dart` + `slot_assigned_controller.dart`**
- Keep `sessionId`; poll `getMyBatteryStatuses()` for **that** session and
  `getDepositSessionStatus()` for terminal states.
- On completion: show the deposit-done prompt
  **Add Another Battery** / **View All Batteries** / **Rent a Battery**
  (web `showAddMorePrompt`) instead of jumping straight to `/charging`.

**`lib/screens/home/charging_screen.dart`**
- Read `temperature ?? temperatureC`; render the selected battery from
  `batteries[activeIndex]`; add a "All batteries" affordance.

**`lib/screens/payment/*`**
- `PaymentController` takes the target `sessionId` from route args, calls
  `initiateWithdrawal(token, sessionId)`, then `payForWithdrawal(token, sessionId)`.
- After success, remove **only** that entry from `batteries`.

**Acceptance:** two batteries at different slots → both cards live; collect one
without disturbing the other; add a third while two are charging.

### Phase 2 — Rental battery flow (3–4 days, the bulk)

**`lib/models/rental_models.dart`** (new)
`RentalFeatureStatus`, `RentalBatteryOption`, `AvailableRentalBatteries`,
`AssignedRental`, `IssueRentalResult`, `ActiveRental`, `RentalBill`,
`PayRentalResult`, `RentalPaymentStatus`, `UnlockOwnRental`, `ReturnRentalResult`.

**`lib/services/booth_service.dart`** — add the 11 rental calls from §2
(`getRentalFeatureStatus`, `getAvailableRentalBatteries`, `issueRental`,
`getActiveRental` (204 → `null`), `returnRental`, `getRentalBill`, `payRental`,
`getRentalPaymentStatus`, `unlockOwnRentalBattery`).

**`lib/controllers/rental_controller.dart`** (new, GetxController)
State machine mirroring `RentalFlow.tsx`:

```
booth_scan → issuing → collecting → active → return → verify_return
→ waiting_return → charging_complete → bill → payment → payment_confirmed
→ unlock_own → collected → closed        (error is reachable from any step)
```

- Initial step logic: `getActiveRental()` first → `pending` ⇒ `collecting`,
  `returned` ⇒ `waiting_return`, else `active`. No active rental + assigned
  battery ⇒ `requireBoothScanBeforeIssue ? booth_scan : issuing`. Nothing ⇒
  exit to dashboard.
- Polls: `collecting` 1.5 s, `active` 5 s (own-battery SOC), `waiting_return`
  1.5 s (`returnCompleted`), payment 2.5 s with a 90 s deadline.
- Error extraction identical to the web (`message` → `error` → fallback).

**Screens — `lib/screens/home/rental/`** (new, port the React components)

| File | Step | Web source |
|---|---|---|
| `rental_booth_scan_screen.dart` | `booth_scan` | `BoothScanScreen` in `RentalFlow.tsx` |
| `rental_issuing_screen.dart` | `issuing` | `ProgressScreen` |
| `rental_collecting_screen.dart` | `collecting` | `ProgressScreen` |
| `rental_active_screen.dart` | `active` | `RentalSessionActive.tsx` |
| `return_rental_battery_screen.dart` | `return` | `ReturnRentalBattery.tsx` |
| `verify_rental_return_screen.dart` | `verify_return` | `VerifyRentalReturn.tsx` |
| `rental_waiting_return_screen.dart` | `waiting_return` | `ProgressScreen` |
| `own_battery_charging_complete_screen.dart` | `charging_complete` | `OwnBatteryChargingComplete.tsx` |
| `consolidated_rental_bill_screen.dart` | `bill` | `ConsolidatedRentalBill.tsx` |
| `rental_payment_screen.dart` | `payment` | `RentalPayment.tsx` |
| `rental_payment_confirmed_screen.dart` | `payment_confirmed` | `RentalPaymentConfirmed.tsx` |
| `unlock_own_battery_screen.dart` | `unlock_own` | `UnlockOwnBattery.tsx` |
| `rental_battery_collected_screen.dart` | `collected` | `RentalBatteryCollected.tsx` |
| `rental_session_closed_screen.dart` | `closed` | `RentalSessionClosed.tsx` |
| `rental_error_screen.dart` | `error` | inline in `RentalFlow.tsx` |

Reuse the existing `mobile_scanner` setup from `scan_screen.dart` for the two
QR gates; compare scanned value with `expectedBoothUid` case-insensitively and
show "Wrong booth scanned".

**`lib/main.dart`**
- `Get.lazyPut(() => RentalController(), fenix: true)`.
- Routes: `/rental`, `/rental/batteries` (multi-status), `/rental/active`,
  `/rental/return`, `/rental/bill`, `/rental/payment`, `/rental/unlock-own`,
  `/rental/closed`.

**`lib/screens/home/dashboard_screen.dart` — `openRental()`** (port web logic)
1. `getRentalFeatureStatus()` — if `!enabled`, hide/decline.
2. Booth UID = selected booth (map/QR) or `batteries[0].boothUid`.
3. `getAvailableRentalBatteries(boothUid)` → filter `status == available`
   (server already filters by SOC) → pick **highest SOC**. The rider never
   picks a battery.
4. Navigate to `/rental` with `AssignedRental` + booth name.
5. If `RENTAL_LIMIT_REACHED` → show "You already have a rental" and route to
   the active rental.

**Resume:** splash checks `getActiveRental()` **before** `/dashboard` and
restores `/rental/active` (web `RentalPage` bootstrap).

**Acceptance (dev backend, `dev-` booths):**
issue → collect → active → return → waiting → bill → pay (auto-approved) →
unlock own → closed; restart the app mid-rental and land back on the right
step.

### Phase 3 — Cleanup (½ day, optional)

- `history_screen.dart` → real list via `getHistory` (see `PARITY_PLAN.md` §3).
- Delete dead code: `collect_screen.dart`, `battery_ready_screen.dart`,
  hardcoded values in `session_complete_screen.dart:15-32`.
- `profile_screen.dart` → wire personal info / picture upload (optional).

---

## 5. Web-side (RIDERCMS3) work

Rental + multi-battery are already shipped on web; only the review items in
§3.3 need attention:

1. **W1** temperature fallback (`temperature ?? temperatureC`) in the three
   places in `UserDashboard.tsx`.
2. **W2** disable the rental button when the rider is at
   `maxRentalBatteriesPerUser` (use `/rentals/available`'s
   `activeRentalCount` / `rentalLimit`).
3. **W3–W8** polish: `lastChargeLevel` fallback, battery label, drop dead
   `rentalBatteries` state, derive restored `doorStatus`, de-dupe entries,
   add a "My Batteries" nav entry.

No API additions are proposed, so web and app stay on the same contract.

---

## 6. Sequencing & estimate

| Phase | Work | Estimate |
|---|---|---|
| 0 | Contract fixes (B1–B6) | ½ day |
| 1 | Multi-battery controller + screen + dashboard + deposit prompt | 1–1.5 days |
| 2a | Rental models + service + controller/state machine | 1 day |
| 2b | 15 rental screens + QR gates | 2 days |
| 2c | Entry points, resume, routes | ½ day |
| 3 | Web polish W1–W8 | ½ day |
| — | Manual E2E + `flutter analyze` | ½ day |

Phase 0 must land first: without it the app cannot see even one battery.
Phases 1 and 2 can run in parallel after Phase 0 (they touch different files,
except `booth_service.dart` — land the service additions in one commit).

---

## 7. Risks / decisions

- **ETag / 304.** `/my-battery-status` returns `304` when nothing changed. The
  `http` package does not cache; either store the ETag per request and send
  `If-None-Match`, or add `Cache-Control: no-cache` / ignore 304. Decide before
  Phase 1 (recommend: store ETag, treat 304 as `no change`).
- **Listener churn.** One Firebase listener per battery must be cancelled on
  removal and on controller `onClose()`; otherwise stale streams leak and
  resurrect collected batteries.
- **Per-session withdrawal.** All withdrawal/payment calls must carry the
  battery's `sessionId`; the current single-object flow cannot be patched — it
  must be threaded through `/stop-charging`, `/initiate-withdrawal`, and
  `/sessions/:id/pay`.
- **Multi-rental is out of scope.** `/rentals/active` is singular and the
  default `max_rental_batteries_per_user` is 1. "Multiple batteries" here means
  multiple **deposited** batteries plus **one** active rental. Supporting
  several concurrent rentals would need backend changes.
- **GetX lifecycle.** `ChargingController` is `lazyPut(..., fenix: true)` and
  `RentalController` must survive navigation between rental steps; use
  `Get.put` in the route's binding and clear state only on `closed`.

---

## 8. Verification checklist

1. `flutter analyze` clean in `android_ridercms/`.
2. Backend: `cd ridercmsV1 && npm run dev` (dev schema, `dev-` booths
   auto-simulate hardware + payments). Login `dev@ridercms.test` / `Maxtek2020`.
3. Deposit two batteries at the same booth → both cards, live SOC/temp.
4. Deposit at a second booth → third card; collect one, others unaffected.
5. Cancel an in-flight deposit → app detects `cancelled` and returns cleanly
   (no stuck spinner).
6. Rental happy path end-to-end with both scan gates enabled
   (`require_rental_scan_before_issue`, `require_return_scan`).
7. Restart app: active rental resumes; N deposited batteries resume to the
   multi-status screen.
8. Cross-check every request/response against §2 (and
   `RIDERCMS3/services/boothService.ts`).
