# BeFit AI — Brand Concept

---

## 1. Brand Essence

| | |
|---|---|
| **Name** | BeFit AI |
| **Tagline** | *Your body. Your plan. Your AI.* |
| **Mission** | To make elite, personalised fitness coaching accessible to everyone — powered by AI that sees you, understands you, and moves with you. |
| **Vision** | A world where every person carries a world-class fitness coach in their pocket, one that adapts in real time and never stops learning. |
| **Core Promise** | No generic plans. No guesswork. Just a living, breathing fitness system built around *you*. |

---

## 2. Brand Personality

BeFit AI is not a sterile fitness tracker. It is a confident, smart training partner — equal parts scientist and coach.

| Trait | What it means in practice |
|---|---|
| **Intelligent** | Every interaction feels considered — the AI reads your photo, analyses your food, coaches in real-time. The brand never dumbs things down. |
| **Direct** | Short sentences. No filler. The app speaks the way a great coach does: clear, purposeful, no fluff. |
| **Energetic** | The visual language is high-contrast and kinetic — lime on black, animated transitions, glowing accents. |
| **Warm** | Despite the dark aesthetic, onboarding is white and conversational. The AI coach greets you by first name. Progress is celebrated. |
| **Precise** | Macro breakdowns, physique ratings, weekly splits — details matter. The brand signals exactness without being clinical. |
| **Progressive** | Always pushing forward: streaks, new analyses, evolving plans. The brand rewards consistency. |

---

## 3. Brand Narrative

> Most fitness apps give everyone the same plan. BeFit AI gives you *your* plan.
>
> Take a photo — the AI reads your physique, your goals, your starting point. Scan your meal — it breaks down every macro and micro in seconds. Open the chat — a coach is ready, 24/7, with no judgment and no hold music.
>
> BeFit AI isn't a database you scroll through. It's an intelligence that sees you as an individual and builds around you, day after day.

This narrative drives every piece of copy, every micro-interaction, and every design decision.

---

## 4. Target Audience

### Primary — The Self-Optimiser (22–38)
- Exercises 3–5× per week but plateaus frequently
- Distrust generic plans; wants specificity
- Comfortable with AI/tech; expects app intelligence to match daily-use apps
- Motivated by data, progress stats, and streaks
- Pain point: no personal trainer budget; too busy for the gym learning curve

### Secondary — The Starter (18–28)
- New to structured training; overwhelmed by options
- Needs guidance, not just content
- Responds to encouragement and a clear next step
- Will onboard fully if the experience feels like it *knows* them

### Shared values
- Ownership of their own health decisions
- Distaste for one-size-fits-all
- Appreciation for design quality — they notice bad UI
- Mobile-first; rarely on desktop for personal health

---

## 5. Colour System

The palette is split across two tonal worlds: **Dark (primary)** for immersive, AI-first experiences, and **Light (onboarding)** for welcoming, human moments.

### Primary — Dark World

| Token | Hex | Usage |
|---|---|---|
| `surface-top` | `#060705` | Top-half dark background; near-black with a warm tint |
| `surface-bottom` | `#0D0F14` | Bottom-half; slightly cooler, creates cinematic gradient split |
| `surface-sheet` | `#0A0C12` | Bottom sheets, modals |
| `surface-card` | `#1A2332` | Chat bubbles, input fields, cards on dark backgrounds |
| `surface-elevated` | `#121620` | App bars, elevated surfaces |
| `border-subtle` | `#2A2F3D` | Dividers, borders in dark context |
| `border-card` | `#2A3A4D` | Card outlines, input borders |

### Accent — The Lime

| Token | Hex | Meaning |
|---|---|---|
| `accent-lime` | `#CCFF00` | The brand's electric heartbeat. Selection states, CTAs, highlights, glow effects. Always on dark. Never overused. |
| `accent-lime-glow` | `#CCFF00` at 25% opacity | Box shadow for selected states — makes elements feel charged |
| `accent-lime-tint` | `#CCFF00` at 15% opacity | Icon circles in selected cards, subtle fills |

**Rule:** Lime appears *only* on dark or black backgrounds. Never on white or light surfaces. One lime element per visual cluster maximum.

### Secondary Accents

| Token | Value | Usage |
|---|---|---|
| `status-online` | `#4CAF50` | Connection indicators, streak markers |
| `status-warning` | Amber | Connecting/pending states |
| `error` | `Colors.redAccent` | Errors, disconnected states, destructive actions |
| `progress-bar` | `Colors.lightGreen` | Onboarding progress — softer than lime, appropriate on white |

### Light World (Onboarding)

| Token | Value | Usage |
|---|---|---|
| `background` | `#FFFFFF` | Onboarding scaffold — clean, no noise |
| `card-unselected` | `#F5F5F5` | Option cards, inactive states |
| `card-selected` | `#000000` + lime border | Selected states — inverts to dark with lime glow |
| `text-primary` | `#1A1A1A` / `Colors.black87` | Body, labels |
| `text-secondary` | `Colors.grey` / `Colors.black45` | Subtitles, hints |
| `text-disabled` | `Colors.black38` | Footer hints, inactive labels |
| `back-button` | `#000000` rounded 12 | Navigation — high contrast, always visible |

---

## 6. Typography

BeFit AI uses a deliberate two-font system: one for authority, one for readability.

### Font Pairing

| Font | Role | Weights used |
|---|---|---|
| **Poppins** (Google Fonts) | Headings, buttons, display text, labels, app bars, titles | `w600`, `w700`, `bold` |
| **Inter** (Google Fonts) | Body text, captions, descriptions, data readouts | `regular`, `w500` |

Poppins is geometric and confident — it commands attention. Inter is neutral and highly legible — it gets out of the way.

### Type Scale

| Level | Font | Size | Weight | Usage example |
|---|---|---|---|---|
| Display | Poppins | 28–32px | Bold | Onboarding headlines ("Choose Your Path!") |
| Heading | Poppins | 20–24px | SemiBold / Bold | Screen titles, section headers |
| Subheading | Poppins | 16–18px | SemiBold (w600) | Card labels, list headers |
| Body | Inter / Poppins | 13–15px | Regular / w500 | Descriptions, explanations |
| Caption | Inter / Poppins | 11–13px | Regular | Metadata, timestamps, secondary labels |
| Micro | Poppins | 10–12px | w500 | Status indicators, badges |

### Highlight Convention

Key words in headlines receive the lime background highlight treatment:

```
"Choose Your"
[Path]    ← Text on lime background (#CCFF00), black text
"!"
```

Use this sparingly — one highlighted word per headline maximum. It signals the *most* important concept in the screen's narrative.

---

## 7. Iconography

- **Style:** Rounded, filled Material Icons (`_rounded` suffix variants)
- **Signature icons:**
  - `Icons.smart_toy_rounded` — AI Coach identity
  - `Icons.camera_alt_rounded` — Photo analysis entry point
  - `Icons.fitness_center_rounded` — Workout context
  - `Icons.restaurant_rounded` — Nutrition context
  - `Icons.arrow_back_ios_new_rounded` — Navigation (consistent everywhere)

Icons on dark backgrounds use white or lime depending on selection state. Icons on light backgrounds use `Colors.black87`.

Icon containers (circles) follow the pattern:
- Unselected: `Colors.black.withValues(alpha: 0.06)` fill, black87 icon
- Selected: `_lime.withValues(alpha: 0.15)` fill, lime icon

---

## 8. Motion & Animation

Animation is intentional — it communicates state, not decoration.

| Pattern | Library | Values |
|---|---|---|
| Screen entrance | `flutter_animate` | `fadeIn` + `slideY(begin: 0.1–0.15)`, 350–400ms, `Curves.easeOut` |
| Staggered content | `flutter_animate` | Delays 0ms → 70ms → 100ms → 300ms per element |
| Selection feedback | `AnimatedContainer` | 250ms, `Curves.easeOut` — bg, border, shadow transition |
| Check indicator | `AnimatedContainer` | 200ms — circle scales and fills with lime |
| Keyboard avoidance | `AnimatedPositioned` | Bottom positioning shifts smoothly with `viewInsets.bottom` |
| Typing indicator | `AnimationController` | 800ms repeat/reverse, `Curves.easeInOut`, 3-dot fade stagger |
| Hero image fade | `ShaderMask` + `LinearGradient` | Static — top opaque → bottom transparent |

**Rule:** No animation should feel gratuitous. If removing it doesn't hurt usability or delight, remove it.

---

## 9. Voice & Tone

### Principles

**Confident, never arrogant.** The AI knows what it's doing — it doesn't hedge with "maybe" or "possibly". But it never talks down to the user.

**Personal, never generic.** Always use the user's first name where available. Respond to *their* data, not a template.

**Motivating, never preachy.** Encourage without lecturing. "You're on a 5-day streak" hits harder than "Consistency is the key to success."

**Concise, never cold.** Short sentences, but not robotic. The app has warmth — it just doesn't waste words.

### Tone by Context

| Context | Tone | Example |
|---|---|---|
| Onboarding | Warm, inviting, clear | "What's your main fitness goal? We'll build everything around it." |
| AI Coach chat | Conversational, expert | "Your squat form looks solid — let's push the reps to 12 this week." |
| Workout plan | Precise, directive | "Day 1 — Push. Bench Press 4×10. Focus: chest activation." |
| Nutrition analysis | Clinical-but-friendly | "High protein hit — 42g. Watch the sodium at 1,200mg." |
| Error states | Calm, actionable | "Couldn't connect. Check your signal and tap Retry." |
| Motivation quote | Poetic, punchy | One strong sentence. No clichés. Personalised to name and tone. |
| Empty states | Encouraging, directional | "Your plan is waiting. Take a photo to get started." |

### Words to avoid

- "Amazing!" / "Awesome!" (generic enthusiasm)
- "Please" in CTA buttons (weakens the action)
- "Try to…" / "Maybe…" (hedging)
- Wall-of-text explanations (use bullets or shorter sentences)
- Third-person references to the AI ("The AI will…") — the coach speaks in first person

---

## 10. Photography & Imagery

### Style
- **Cinematic:** High contrast, moody lighting, real bodies (not stock-perfect physiques)
- **Action-oriented:** Movement, effort, real gym environments
- **Dark-warm:** Imagery sits on dark backgrounds; should not fight with the lime accent
- **Authentic:** Avoid overly staged compositions — BeFit AI is for real people

### Hero Images
- Entry screens (login, welcome) use full-bleed images with `ShaderMask` gradient fade
- Images fade from opaque (top) to transparent (bottom) to allow text overlay
- Gradient: `Alignment.topCenter` to `Alignment.bottomCenter`, colours: `[transparent, black]`

### In-app Imagery
- Food photos: user-generated, shown as square cards with subtle rounded corners
- Exercise GIFs: sourced via ExerciseDB, displayed in detail pages with hero transitions
- Physique photos: user-uploaded, treated with privacy sensitivity — never shown publicly

---

## 11. Logo & App Icon

### Logotype
- Text: **BeFit AI** — Poppins Bold
- "Be" and "AI" in white; "Fit" potentially highlighted in lime (on dark)
- No icon required alongside the wordmark; the wordmark stands alone

### App Icon
- Source: `assets/icon/app_icon.png`
- Should work at all sizes from 20×20 to 1024×1024
- Dark background with lime accent element — must read at small sizes
- No text in the icon

### Splash / Loading Logo
- Source: `assets/logo/splash-logo.png`
- Used on the dark splash screen
- Should be centred, white or lime-accented, no detailed gradients

### Usage Rule
Logo appears in the auth screen top bar, centred, `height: 36px`. No app name text alongside it — the logo carries the brand without words in this context.

---

## 12. UI Component Brand Signatures

These recurring elements form the visual identity in the product:

### Cards
Two states — always animated between them:
```
Unselected: #F5F5F5 bg, transparent border, soft shadow
Selected:   #000000 bg, 2px lime border, lime glow shadow (blurRadius 16, offset y6)
```

### Buttons (Primary CTA)
- Rounded rectangle, black fill, white Poppins text
- Defined in `AppWidgets.roundbtnText()`
- On dark screens: may use lime fill for maximum contrast

### Back Button
- Black rounded square (borderRadius 12), white arrow icon
- Consistent across all screens — onboarding, auth, detail pages
- Size: `padding: 8`, icon: `Icons.arrow_back_ios_new_rounded, size: 18`

### Progress Bar
- Thin 6px bar, full width
- `Colors.lightGreen` fill on `Colors.black12` background
- Used throughout onboarding; value maps 0.05 → 1.0 across steps

### Input Fields
- On dark screens: `#1A2332` bg, `#2A3A4D` border, rounded 24px (chat) or 14px (forms)
- On light screens: standard Material outlined style
- Hint text: `Colors.grey[600]` on dark, standard grey on light

### Snackbar / Toast
- Dark: `#1A1A2E` background, floating, `borderRadius 14`, Poppins 13px white
- Error variant: red-accented icon prefix
- Never blocks critical UI — `SnackBarBehavior.floating` always

---

## 13. Experience Principles

**1. First impression is cinematic.**
Auth and welcome screens use the full visual power of the brand — dark gradient, ShaderMask hero, lime accents. The user should feel they've entered something premium.

**2. Onboarding earns trust through lightness.**
The moment the user starts giving personal data (gender, goals, measurements), the UI switches to white and conversational. The dark aesthetic would feel interrogative. White feels safe.

**3. The AI always feels present.**
The `smart_toy_rounded` icon, the green connection dot, the typing indicator — the AI coach has a personality and a visible status. It never feels like a black box.

**4. Data is never raw.**
Macros, ratings, and splits are always framed with guidance ("High protein — great for your goal"). Numbers without context are noise.

**5. Progress is the product.**
Streaks, completion states, saved plans — every interaction leaves a visible artefact. The user always knows where they are and how far they've come.

**6. Speed is respect.**
Optimistic UI, local persistence, cached data. The app never makes the user wait when it doesn't have to.

---

## 14. Brand Don'ts

| Don't | Why |
|---|---|
| Use lime on white or light backgrounds | Lime is a dark-surface accent — on white it reads as neon and clashes with the onboarding tone |
| Stack more than one lime element in a single view | Lime works because it's rare. Abundance kills the accent effect. |
| Use emoji as decoration in dark UI | Emoji carry light-world energy; keep them to onboarding/chat contexts |
| Write headlines longer than 6 words | BeFit AI is a coach, not an essay writer |
| Show loading states without the AI "thinking" metaphor | Use the typing dot animation or coach avatar — not a bare spinner |
| Use generic stock photography of perfect bodies | Authenticity over aspiration — real people build trust |
| Ship a screen without micro-animation on entrance | Bare, static transitions undercut the premium feel the brand promises |

---

## 15. Brand Summary Card

```
NAME          BeFit AI
TAGLINE       Your body. Your plan. Your AI.
ACCENT        #CCFF00 (Electric Lime)
DARKS         #060705 / #0D0F14 / #0A0C12
LIGHTS        #FFFFFF / #F5F5F5
TYPE          Poppins (display) + Inter (body)
ICONS         Material Rounded
MOTION        flutter_animate — fast, eased, purposeful
VOICE         Confident · Precise · Warm · Concise
AI PERSONA    Expert coach — present, named, always connected
```
