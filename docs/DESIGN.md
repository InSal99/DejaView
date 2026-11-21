# Déjà View — Design guide (native iOS)

> You've seen it before. Now you can find it again.

Read with `SPEC.md`. This file says how the app looks and feels; `SPEC.md` says what it does. Mostly for Person C (UI) and Person A (Add link sheet, share extension).

## Principles
1. **Native first.** Use Apple's system components and let iOS style them. On iOS 26+ tab bars, toolbars and sheets get the Liquid Glass look automatically. Don't draw custom bars, custom fonts or custom navigation.
2. **The posts are the content.** Thumbnails lead; chrome stays quiet.
3. **Brand in the details.** Use the blue accent for primary actions and selection; keep surfaces calm and reserve motion for useful feedback.
4. **Readable on a projector.** Test every screen with large Dynamic Type.

## Rules
- **Components:** `NavigationStack`, `TabView`, `LazyVGrid`, `List`, `.sheet`, `.searchable` / `TextField`, `ContentUnavailableView` for empty states, `PhotosPicker`.
- **Type:** system font with text styles only (`.largeTitle`, `.title2`, `.headline`, `.body`, `.subheadline`, `.caption`). No fixed point sizes.
- **Colour:** use the adaptive AccentColor asset for actions and the Design category, with semantic system surfaces and text so light and dark mode remain legible. Other category colours are system colours below.
- **Icons:** SF Symbols only. **Never use platform logos** (Instagram, TikTok, etc. are trademarks). Show the platform as a short text label.
- **Spacing:** 16 pt screen margins, 12 pt grid gaps, 8 pt inside chips. Cards: corner radius 16, continuous style.
- **Copy:** sentence case, short, friendly, no jargon ("Processing…", not "Inferencing").

## Category system
One colour and one symbol per category, used everywhere: chips, card accents, filters, detail header. Put these in `PostCategory` (`displayName`, `color`, `symbol`).

| Case | Display name | Colour | SF Symbol |
|---|---|---|---|
| `design` | Design | adaptive brand blue (`AccentColor`) | `paintbrush.pointed` |
| `foodRecipes` | Food & Recipes | `.orange` | `fork.knife` |
| `travel` | Travel | `.teal` | `airplane` |
| `tech` | Tech | `.blue` | `laptopcomputer` |
| `tipsLearning` | Tips & Learning | `.yellow` | `lightbulb` |
| `shopping` | Shopping | `.pink` | `bag` |
| `entertainment` | Entertainment | `.red` | `play.rectangle` |
| `other` | Other | `.gray` | `square.grid.2x2` |

**Category chip:** capsule, symbol + name, `.caption.weight(.semibold)`, colour at 15% opacity background with the full colour for text and symbol. Selected filter chip: full colour background, white text.

**Platform label:** `.caption2`, `.secondary`, plain text ("Instagram", "TikTok", "Threads", "X", "Facebook", "Web", "Screenshot").

## App structure
`TabView` with three tabs:

| Tab | Label | SF Symbol | Badge |
|---|---|---|---|
| Library | Library | `square.grid.2x2` | — |
| Ask | Ask | `sparkle.magnifyingglass` | — |
| Review | Review | `tray` | count of `.needsReview` posts (hide when 0) |

Optional: iOS 26 added a search tab role (`Tab(role: .search)`) that shows Ask as a separate search button in the tab bar. Use it only if it compiles first try; otherwise use a normal tab. (Unverified in the course code.)

## Screens

### 1. Library
- Navigation title "Library" (large title). Toolbar: `+` (opens Add sheet).
- Unavailable banner at the top when the model is off (see Components).
- Source and category menus filter together; a no-match state offers to clear both filters.
- A list of saved posts, newest first, shows each category with its symbol. A trailing swipe action asks for confirmation before deletion.
- **Empty state** (`ContentUnavailableView`): symbol `rectangle.on.rectangle`, title "Nothing saved yet", description "You've seen it before. Now you can find it again. Share a post to Déjà View or paste a link.", button "Paste a link".

**Post card**
```
┌───────────────────┐
│                   │  thumbnail, 4:5, fill + clipped
│      image        │  (no image: category colour at 15% + big category symbol)
│                   │
├───────────────────┤
│ Summary, up to 2  │  .subheadline, primary
│ lines             │
│ [◆ Design]  2d    │  category chip · relative date (.caption2, secondary)
│ Instagram         │  platform label
└───────────────────┘
```
- Background `Color(.secondarySystemBackground)`, radius 16.
- No summary yet → show the caption (2 lines) in `.secondary`.
- `.needsReview` → small yellow dot top-right on the image, VoiceOver "Needs review".

**Processing card state** (`.pending`)
- Image area: `.redacted(reason: .placeholder)` look or a soft gray fill with `Image(systemName: "sparkles")` using `.symbolEffect(.pulse)`.
- Text: "Processing…" in `.secondary`.
- When it finishes: animate the change (`.animation(.smooth, value: status)`) and play `.sensoryFeedback(.success, trigger: status)`.

### 2. Ask (the signature screen)
**Empty state**
- Large `sparkle.magnifyingglass` symbol, title "Ask Déjà View", subtitle "Find a post by describing it."
- Three tappable example chips, stacked: "Design posts from this week", "Recipes I saved", "Travel tips on TikTok". Tapping fills the field and submits.
- Text field at the bottom (above the tab bar), placeholder "What are you looking for?", submit button `arrow.up.circle.fill`. Disabled while answering.

**While answering**
- Show a progress indicator while searching and keep the answer card calm and readable as text arrives.
- **Tool chip** appears as soon as the tool is called: capsule with `magnifyingglass` + the label, e.g. "Searched: Design · last 7 days". `.caption`, secondary background. Animate in with `.transition(.scale.combined(with: .opacity))`.
- **Answer card**: the streamed text in `.body`, appearing as it arrives.
- **Results** below: the same post cards (or a compact row version), each with a "why it matched" line in `.caption` `.secondary` ("Design · 'figma' in caption"). Animate results in one by one.

**No match** (the graceful-failure beat; make it look intentional)
- Answer card shows the model's honest reply, plus a small `ContentUnavailableView.search(text:)`-style message: "Nothing saved about that yet."

**Model off**
- The banner, then plain keyword results. No glow, no tool chip.

```
┌─────────────────────────────┐
│ Ask                         │
│ ⌕ Searched: Design · 7 days │  ← tool chip
│ ╭─────────────────────────╮ │
│ │ You saved one design    │ │  ← answer card (glow while streaming)
│ │ post this week, about…  │ │
│ ╰─────────────────────────╯ │
│ ┌─────┐ ┌─────┐             │
│ │card │ │card │             │  ← results
│ └─────┘ └─────┘             │
│ [ What are you looking… ↑ ] │
└─────────────────────────────┘
```

### 3. Review
- Navigation title "Needs review". Subtitle text: "Déjà View wasn't sure about these. Fix them when you have a moment."
- `List` of compact rows: thumbnail 56×56 (radius 10), caption or summary (2 lines), `statusMessage` in `.caption` yellow-orange (e.g. "No text found — add a note").
- Swipe action: "Fix" (opens detail).
- Empty: `ContentUnavailableView`, symbol `checkmark.circle`, "All caught up".

### 4. Post detail
- Hero image full width (max height ~45% of screen), radius 0 at the top.
- Platform label, date, and original link, followed by the editable category chip before AI content.
- Summary in `.title3`.
- Tag chips (neutral, `#tag`).
- Primary button: "Open original" (`.borderedProminent`, symbol `arrow.up.right.square`).
- Category: `Picker` (menu style) using the category symbols.
- Note: `TextField("Add a note…", axis: .vertical)`.
- Collapsible `DisclosureGroup("What Déjà View read")`: original caption, OCR text, English translation (if any). This answers "how did it know?" for users and judges.
- Toolbar menu: "Retry with AI" (`arrow.clockwise`), "Delete" (destructive, `trash`) with a `confirmationDialog`.

### 5. Add sheet (Person A)
- `.sheet` with `.presentationDetents([.medium])`.
- Title "Save a post".
- Section 1: link field (prefilled from clipboard), inline error in `.caption` red ("That doesn't look like a link"), "Save" button.
- Section 2 (Sprint 2): `PhotosPicker` button "Pick a screenshot" with `photo.on.rectangle`.

### 6. Share extension (Person A)
- Small centred card, `.regularMaterial` background, radius 20.
- `checkmark.circle.fill` in green with `.symbolEffect(.bounce)`, text "Saved to Déjà View".
- Closes itself after ~1 second. No buttons.

## Components
| Component | Spec |
|---|---|
| **Unavailable banner** | Rounded rect, `Color.yellow.opacity(0.15)`, symbol `exclamationmark.triangle`, the `unavailableReason` sentence + "Basic save and search still work." `.footnote`. |
| **Category chip** | See Category system. |
| **Tool chip** | Capsule, `magnifyingglass` + label, `.caption`, `Color(.tertiarySystemFill)`. |
| **Example prompt chip** | Full-width capsule button, `.bordered`, `.subheadline`, leading `sparkles` symbol. |
| **Toast** (save confirmation in app) | Capsule at the top, `.regularMaterial`, checkmark + "Saved", auto-dismiss 1.5 s. |

## Motion and haptics
- Default animation: `.smooth`. No bounces except the save checkmark.
- Cards appearing: `.transition(.opacity.combined(with: .scale(scale: 0.96)))`.
- `.sensoryFeedback(.success, …)` when a post finishes processing and when Ask results arrive. `.sensoryFeedback(.warning, …)` on no match.
- Respect Reduce Motion (`@Environment(\.accessibilityReduceMotion)`): no rotating glow, no scale transitions.

## Accessibility
- Dynamic Type everywhere; cards grow taller, never truncate the category chip.
- VoiceOver: card label = "Summary. Category. Platform. Date." Thumbnails are decorative (`accessibilityHidden`) inside cards. Tool chip reads "Searched design posts from the last 7 days."
- Colour is never the only signal: chips always have a symbol and text; Needs review has a dot **and** a VoiceOver label.
- Minimum tap target 44×44.

## App icon
The supplied twin-cat search mark represents seeing something twice and finding it again. Use `brand/deja-view-app-icon.svg` as the source for the opaque 1024 px PNG in the iOS asset catalog. Extend the icon's background to the edges when exporting so iOS can apply its own icon mask. The in-app mark uses the primary logo.

The identity palette is Déjà View Blue `#5FA1ED`, cobalt `#3B7DD8`, sky `#BED7F7`, ice `#E7F1FC`, and obsidian `#313235`. The adaptive accent uses a darker blue `#2866BB` in light mode for contrast and `#7EB8F7` in dark mode. Use blue sparingly for actions, selection, and the Design category; retain semantic system backgrounds, text, and other category colors. The voice is concise, friendly, and centered on search, finding, recall, and assistance. See `brand/brand-identity.html` for the complete identity and asset usage.

## Demo checklist (design)
- [ ] Large text on, iPhone 17 Pro (or Pro Max simulator) for the projector.
- [ ] Library already has the sample posts, with real thumbnails, across several categories.
- [ ] Ask's progress and tool chip visible during the live request.
- [ ] The no-match empty state looks intentional.
- [ ] Dark mode checked once.

## What to skip today
Custom fonts, custom tab bars, onboarding screens, settings, iPad layout, additional app icon variants.
