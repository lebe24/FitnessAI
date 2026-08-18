# Subscription setup — single group

App: **BeFit AI** · Bundle `com.betfit.ai.app`

Replaces the current two-group setup (`yearly` and `monthly` as separate
groups) with one group holding both durations.

## Why this change

Apple enforces "one active subscription per group". With two groups that rule
does nothing for you:

| | Two groups (current) | One group |
|---|---|---|
| User holds both at once | **Possible — double charged** | Impossible |
| Monthly → yearly | Two unrelated purchases | Real upgrade, Apple prorates |
| Free trial | **One per group — two trials claimable** | One, correctly |
| Cancel/resubscribe history | Split across groups | Single timeline |

Nothing is live yet, so this costs a few minutes now instead of refunds and
support tickets later.

---

## 1 · Product IDs

**Product IDs are permanent and globally unique.** The existing ones are burned
even if you remove them, so the new group needs fresh IDs. These drop the
`.app` segment, which keeps them clean rather than adding a `v2` suffix:

| Duration | Product ID |
|---|---|
| Monthly | `com.betfit.ai.pro.monthly` |
| Yearly | `com.betfit.ai.pro.yearly` |

Pick them carefully — they cannot be changed or reused, ever.

---

## 2 · Create the group

App Store Connect → **Subscriptions** → **Subscription Groups** → **+**

| Field | Value |
|---|---|
| Reference Name | `BeFit Pro` |
| Localized Display Name (English) | `BeFit Pro` |

The reference name is internal. The display name is shown in the user's
Subscriptions settings, so it should read like a product, not a SKU.

---

## 3 · Create both subscriptions inside it

### Monthly
| Field | Value |
|---|---|
| Reference Name | `BeFit Pro Monthly` |
| Product ID | `com.betfit.ai.pro.monthly` |
| Subscription Duration | 1 Month |
| Display Name | `BeFit Pro — Monthly` |
| Description | Adaptive AI training plans, coach chat, nutrition scanning and progress analytics. |

### Yearly
| Field | Value |
|---|---|
| Reference Name | `BeFit Pro Yearly` |
| Product ID | `com.betfit.ai.pro.yearly` |
| Subscription Duration | 1 Year |
| Display Name | `BeFit Pro — Yearly` |
| Description | Everything in BeFit Pro, billed once a year. |

**Set the yearly rank above monthly** in the group's upgrade/downgrade order,
so moving monthly → yearly counts as an upgrade and Apple prorates it.

---

## 4 · Pricing

Your sandbox transaction came back at **₦129,900/year ≈ US$85**. Check that is
the tier you meant — if you intended roughly ₦12,990, the tier is off by 10×.

Set the base price in your home territory and let App Store Connect generate
the rest. A yearly price around 8–10× the monthly is the usual shape: it reads
as "two months free" and is what the paywall's savings badge will compute from.

---

## 5 · Introductory offer — on BOTH subscriptions

Open each subscription, scroll past *Subscription Prices* to
**Introductory Offers** → **+**

| Field | Value |
|---|---|
| Territories | All |
| Start / End | Start today, no end date |
| Type | **Free Trial** |
| Duration | **1 Week** |

Must be set on both. If only one has it, the paywall offers a trial on one
package and charges immediately on the other — and the app will now correctly
say so, which looks inconsistent.

---

## 6 · RevenueCat wiring

**Products** → add both new IDs:
- `com.betfit.ai.pro.monthly`
- `com.betfit.ai.pro.yearly`

**Entitlements** → `Befit AI - fitness Pro` → attach **both** new products, and
**detach the two old ones** so a stale offering cannot grant access.

**Offerings** → the current offering (`Befit AI Package`):

| Package | Product |
|---|---|
| `$rc_monthly` | `com.betfit.ai.pro.monthly` |
| `$rc_annual` | `com.betfit.ai.pro.yearly` |

Remove the old products from the offering and confirm it is still marked
**Current**. Nothing in the app changes — `kProEntitlement` is unchanged, and
the packages are addressed by their standard identifiers.

---

## 7 · Retire the old products

The old subscriptions cannot be deleted once submitted. In each old group,
open the subscription and set **Availability → Remove from Sale**. Leave the
empty groups alone; they are harmless once nothing sells from them.

---

## 8 · Verify

1. **Clear sandbox history** — Settings → App Store → Sandbox Account →
   Manage → clear purchases. An Apple ID can consume an introductory offer
   only once per subscription group, and yours has already used one.
2. **Run the app.** The debug log should print the offering with both packages:
   ```
   SubscriptionService: offering "…" loaded with packages [$rc_annual, $rc_monthly]
   ```
3. **Open the onboarding sheet.** It should now read
   **"Start my 1-week free trial"** — that text is derived from the store, so
   seeing it is proof the introductory offer is attached and readable.
   If it says "Unlock everything", the offer is missing or not yet propagated.
4. **Buy in sandbox and decode the transaction.** The signed payload must now
   contain `offerType` and `offerDiscountType: FREE_TRIAL`. Their absence is
   what proved the last purchase charged instead of starting a trial.
5. **Check the database** once the webhook fires:
   ```sql
   select access_tier, trial_ends_at from user_profiles where id = '<user>';
   ```
   Expect `trial`.

Propagation from App Store Connect to StoreKit can take a few minutes to a few
hours. If step 3 still says "Unlock everything" straight after saving, wait
before assuming it is broken.
