# Payment System — Implementation Plan

> Subscription billing for BeFit AI Premium. Covers the platform decision,
> architecture, backend entitlement sync, and a phased implementation checklist.

**Status:** Planning
**Branch:** `payment`
**Last updated:** 2026-07-08

---

## 1. Platform decision — Apple IAP via RevenueCat

BeFit's premium features (AI workout plans, coaching, analysis) are **digital
content consumed inside the app**. Apple App Store Guideline 3.1.1 **requires
In-App Purchase** for this — a Stripe/PayPal checkout for the subscription would
be rejected at review.

**Stripe is not an option here** (it's only allowed for physical goods or
services consumed outside the app, e.g. booking a real trainer session).

**We use RevenueCat as the IAP wrapper** rather than raw `in_app_purchase`:

| | RevenueCat | Raw `in_app_purchase` |
|---|---|---|
| Receipt validation | ✅ handled | ❌ build yourself |
| Subscription/renewal state | ✅ handled | ❌ build yourself |
| Cross-platform (Android later) | ✅ one API | ❌ per-platform |
| Backend webhooks | ✅ built-in | ❌ build yourself |
| Cost | Free < $2.5k/mo revenue | Free |

**Fee note:** enroll in Apple's **Small Business Program** (< $1M/year) to drop
Apple's cut from 30% → **15%**.

---

## 2. Products

One subscription group (**"BeFit Premium"**) with two auto-renewing products,
matching the monthly/yearly toggle already in `billing_page.dart`:

| Product ID | Price | Period |
|---|---|---|
| `befit_premium_monthly` | $8.99 | 1 month |
| `befit_premium_yearly` | $79.99 | 1 year (~26% saving) |

Both attach to a single RevenueCat entitlement: **`premium`**.

Optionally add an introductory offer (e.g. 7-day free trial) on each product.

---

## 3. Architecture

```
Flutter app                    RevenueCat          Apple           Backend (FastAPI)
───────────                    ──────────          ─────           ─────────────────
1. Init Purchases SDK
   (identify by Supabase uid)
2. Fetch offerings   ─────────► returns products
3. User taps "Upgrade"
4. purchasePackage() ─────────────────────────────► StoreKit
                                                     payment sheet
5. Purchase completes ◄──────── validates receipt ◄─┘
6. Check entitlement
   'premium' active → unlock UI

                    RevenueCat webhook ─────────────────────────────► POST /api/v1/billing/webhook
                    (INITIAL_PURCHASE,                                 update user_profiles.is_premium
                     RENEWAL, CANCELLATION,                            + premium_expires_at in Supabase
                     EXPIRATION)

Backend gates expensive AI endpoints on is_premium (server-side, not just UI).
```

**Why a backend webhook matters:** the UI can check entitlement locally, but the
**backend must independently know** who is premium so it can gate expensive AI
calls (workout generation, form analysis) server-side. Never trust the client
alone for entitlement on paid compute.

---

## 4. Backend changes

### 4.1 Schema (Supabase `user_profiles`)
Add two columns:
```sql
alter table user_profiles
  add column is_premium boolean not null default false,
  add column premium_expires_at timestamptz;
```
(Deliver via an Alembic migration in the backend repo.)

### 4.2 Webhook endpoint
`POST /api/v1/billing/webhook` (new route, mirrors existing route structure):
- Verify the RevenueCat `Authorization` header against a shared secret
  (`REVENUECAT_WEBHOOK_SECRET` env var / Cloud Run secret).
- Map event types → premium state:
  - `INITIAL_PURCHASE`, `RENEWAL`, `UNCANCELLATION` → `is_premium = true`, set `premium_expires_at`
  - `CANCELLATION` → keep premium until expiry (user still paid through period)
  - `EXPIRATION` → `is_premium = false`
- Upsert into `user_profiles` keyed by the app user id (Supabase uid, passed to
  RevenueCat as the App User ID).

### 4.3 Gating
Add a dependency/guard on premium-only endpoints (unlimited plan generation,
form analysis) that reads `is_premium` and returns `402 Payment Required` when
false and the free quota is exhausted.

---

## 5. Flutter changes

### 5.1 Dependencies
```yaml
purchases_flutter: ^8.0.0   # RevenueCat SDK (pin exact version, commit lockfile)
```

### 5.2 Initialization
Init the SDK at app start (after Supabase auth is ready), identified by the
Supabase user id so entitlements follow the account across devices:
```dart
await Purchases.configure(
  PurchasesConfiguration(revenueCatApiKey)..appUserID = supabaseUserId,
);
```

### 5.3 A `SubscriptionService` (data layer)
Wraps the SDK: `fetchOfferings()`, `purchase(package)`, `restore()`,
`isPremium()` (reads `customerInfo.entitlements.active['premium']`), and a
stream/notifier so the UI reacts to entitlement changes.

### 5.4 `billing_page.dart` wiring
Replace the "coming soon" snackbars:
- **"Start Free" / "Upgrade"** → `SubscriptionService.purchase(selectedPackage)`
- **"Restore purchases"** → `SubscriptionService.restore()` — **required by Apple**;
  a subscription app without a visible restore button is rejected.
- Show real prices from RevenueCat offerings (localized), not hardcoded strings.
- On success, reflect premium state in the "Current Plan" card.

### 5.5 Paywall legal requirements (Apple)
The paywall screen must display, or Apple rejects:
- Price, billing period, and **auto-renewal** terms
- Links to **Privacy Policy** and **Terms of Use (EULA)**

### 5.6 Premium gating in the app
A `PremiumProvider` (ChangeNotifier in GetIt) exposing `isPremium`, driven by
the SubscriptionService, so feature screens can gate UI and prompt upgrade.

---

## 6. App Store Connect setup

1. **Agreements, Tax, and Banking** → sign Paid Apps agreement, add bank + tax
   info. **Nothing works until this is "Active".**
2. **Monetization → Subscriptions** → create group "BeFit Premium" + the two
   products with pricing and (optional) intro offers.
3. Create an **App Store Connect API key** for RevenueCat (Users and Access →
   Integrations).
4. Enroll in the **Small Business Program** (15% fee tier).

---

## 7. RevenueCat setup

1. Create project → add iOS app (bundle id `com.betfit.ai.app`).
2. Connect the App Store Connect API key.
3. Create entitlement `premium`, attach both products.
4. Create a default **Offering** with monthly + yearly packages.
5. Configure the **webhook** → point at `POST /api/v1/billing/webhook`, set the
   shared secret.

---

## 8. Testing (Sandbox)

- Create a **Sandbox tester** in App Store Connect → Users and Access.
- On a real device: Settings → App Store → Sandbox Account → sign in.
- Verify: purchase, restore, cancel, and renewal (sandbox renews on an
  accelerated clock — monthly ≈ 5 min).
- Confirm the backend webhook flips `is_premium` in Supabase for each event.

---

## 9. Implementation checklist

### Backend
- [ ] Alembic migration: `is_premium` + `premium_expires_at` on `user_profiles`
- [ ] `POST /api/v1/billing/webhook` with signature verification
- [ ] Event → premium-state mapping + Supabase upsert
- [ ] `REVENUECAT_WEBHOOK_SECRET` as a Cloud Run secret
- [ ] Premium gate on unlimited plan generation / form analysis endpoints

### Flutter
- [ ] Add `purchases_flutter`, pin version, commit lockfile
- [ ] SDK init identified by Supabase uid
- [ ] `SubscriptionService` (offerings, purchase, restore, isPremium stream)
- [ ] `PremiumProvider` in GetIt
- [ ] Wire `billing_page.dart` to real purchase/restore + live prices
- [ ] Paywall legal text + Privacy/Terms links
- [ ] Gate premium features + upgrade prompts

### Store / dashboard
- [ ] App Store Connect: agreements, subscription products, API key
- [ ] Small Business Program enrollment
- [ ] RevenueCat: project, entitlement, offering, webhook
- [ ] Sandbox tester + full purchase/restore/renew test
- [ ] Update App Privacy nutrition label (Purchases data type)

---

## 10. Rollout sequencing

Because v1 hasn't shipped yet, recommended order:

1. Ship **v1.0 free** to the App Store first (decouples first-app review from
   subscription review).
2. Land this payment work behind the `payment` branch; merge when store setup
   is complete.
3. Release **v1.1** with Premium enabled once subscription products are approved.

If premium is core to the launch model, do it now — but expect the first review
to scrutinize the paywall (legal text + restore button are the usual rejections).

---

## 11. Open questions

- Free trial? (7-day intro offer boosts conversion but adds review scrutiny.)
- Free-tier quota — what exactly is metered (e.g. 1 AI plan/month) and enforced
  server-side via the premium gate?
- Android/Play Billing timing — RevenueCat makes this a small addition later.
