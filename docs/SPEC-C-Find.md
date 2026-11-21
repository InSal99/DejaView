# Déjà View — Spec for Person C: Find

> You've seen it before. Now you can find it again.

**Your mission:** the screens, and finding posts again. You own all the main UI, the search engine, the required `Tool` (`SearchSavedPostsTool`) and the Ask flow with a streamed answer. The Ask screen is the heart of the demo.

**Give your agent:** run Claude Code in the `deja-view` folder and type `/person-c` (it loads `CLAUDE.md` and this file). Agents also use `Reference/WorkspaceAssistant-Lite` (its `Tools.swift` and `TaskAgent.send(_:)` show the tool and streaming patterns).

**Jobs you deliver:** J10 fix mistakes · J11 ask in plain language · J12 Indonesian query words work · J13 trust results · J14 works without Apple Intelligence (the search side) · J15 search works in Airplane Mode · J9 Review list (Sprint 2).

## Shared contract (identical in all three specs; change it only after telling the team)

**App:** Déjà View ("You've seen it before. Now you can find it again."). Code name `DejaView` (no accent). Targets `DejaView` (app) and `DejaViewShare` (share extension), both with display name `Déjà View`. App Group `group.com.TEAMID.dejaview`. Xcode 27, iOS 27, Swift 6, Approachable Concurrency on. No third-party packages, no server, no CloudKit.

**Capstone rules:** Track C. At least one `@Generable` type (B: `PostAnalysis`) and one `Tool` (C: `SearchSavedPostsTool`). Demo at 15:30, three minutes.

**Team:** A = Capture · B = Understand · C = Find. Each person edits only their own files.

### Clock
| Time | Everyone |
|---|---|
| 10:45–11:00 | Setup (A does the Xcode setup; B and C read their spec) |
| **11:00–11:20** | **Stub-first:** each person creates their public types below with the exact signatures, returning dummy values, and pushes. After this, everyone builds against the real names. |
| 11:20–12:30 | Sprint 1: the demo path (paste link → analyzed → ask finds it) |
| **12:30** | Safe to fail; merge; commit or zip a working copy before lunch |
| 13:30–14:15 | Sprint 2 items; drop anything not working at 14:15 |
| **14:30** | Readiness; demo request works three times in a row |
| **15:00** | Feature freeze; 15:00–15:30 rehearse |

### Data model (A writes these in `Shared/`, membership in both targets)
```swift
import SwiftData
import SwiftUI
import FoundationModels

enum PostStatus: String, Codable { case pending, processed, needsReview }

enum Platform: String, Codable, CaseIterable {
    case instagram, tiktok, threads, x, facebook, web, screenshot
    static func detect(from url: URL) -> Platform  // instagram.com, tiktok.com, threads.net/threads.com, x.com/twitter.com, facebook.com/fb.watch, else .web
    var displayName: String                        // "Instagram", "TikTok", "Threads", "X", "Facebook", "Web", "Screenshot"
}

@Generable
enum PostCategory: String, CaseIterable, Codable {
    case design, foodRecipes, travel, tech, tipsLearning, shopping, entertainment, other
    var displayName: String  // Design, Food & Recipes, Travel, Tech, Tips & Learning, Shopping, Entertainment, Other
    var color: Color         // .purple, .orange, .teal, .blue, .yellow, .pink, .red, .gray
    var symbol: String       // paintbrush.pointed, fork.knife, airplane, laptopcomputer, lightbulb, bag, play.rectangle, square.grid.2x2
}

@Model
final class SavedPost {
    @Attribute(.unique) var id: UUID
    var urlString: String?
    var platformRaw: String
    var savedAt: Date
    var caption: String              // original text from the link preview
    var ocrText: String              // text read from the image
    var detectedLanguage: String     // "en", "id", …
    var englishText: String          // translation sent to the model ("" if not needed)
    @Attribute(.externalStorage) var imageData: Data?
    var summary: String
    var categoryRaw: String
    var tags: [String]
    var statusRaw: String
    var statusMessage: String        // e.g. "No text found — add a note"
    var userNote: String
    var processedWithAI: Bool
    init(urlString: String? = nil, platform: Platform, imageData: Data? = nil)  // defaults: empty strings, .other, .pending, false
    var platform: Platform { get }
    var category: PostCategory { get set }
    var status: PostStatus { get set }
}

enum SharedContainer {
    static let container: ModelContainer   // App Group store, cloudKitDatabase: .none
}

enum ImageTools {
    static func downscaledJPEG(_ data: Data, maxPixel: CGFloat = 1600) -> Data?
}
```

### Public signatures each person provides
| Owner | Type | Signature |
|---|---|---|
| A | `LinkPreview` | `struct LinkPreview { var title: String; var caption: String; var imageData: Data? }` |
| A | `LinkFetcher` | `enum LinkFetcher { static func fetch(_ url: URL) async -> LinkPreview }` (never throws) |
| A | `AddLinkView` | `struct AddLinkView: View` (no init arguments; reads `PostProcessor` and `modelContext` from the environment) |
| A | `DejaViewApp` | wires everything (below) |
| B | `PostProcessor` | `@MainActor @Observable final class PostProcessor { init(); private(set) var isProcessing: Bool; func processPending(in context: ModelContext) async }` |
| B | `PostAnalyzer` | `@MainActor enum PostAnalyzer { static var forceUnavailable: Bool; static var unavailableReason: String? { get }; static var isAvailable: Bool { get }; static func prewarm() }` |
| B | `ModelErrors` | `enum ModelFailure { case tooLong, unsafe, refused, unsupportedLanguage, busy, notReady, toolFailed, other }` · `enum ModelErrors { static func classify(_ error: Error) -> ModelFailure; static func message(for failure: ModelFailure) -> String }` |
| C | `RootView` | `struct RootView: View` (the `TabView`: Library, Ask, Review) |

### App wiring (A writes `DejaViewApp.swift` exactly like this)
```swift
@main
struct DejaViewApp: App {
    @State private var processor = PostProcessor()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(processor)
                .task { PostAnalyzer.prewarm() }
        }
        .modelContainer(SharedContainer.container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await processor.processPending(in: SharedContainer.container.mainContext) }
            }
        }
    }
}
```
Anyone who changes a post's status to `.pending` (A after saving, C on "Retry with AI") then calls `await processor.processPending(in: modelContext)`.

### Git
One branch per person. Merge into `main` at 11:20 (stubs), 12:30 and 14:30, more often if you like. Never edit another person's file; ask them.

### Coding rules for agents
- Swift 6, async/await, no third-party packages.
- Don't edit `.xcodeproj` / `.pbxproj` files; tell the human what to add in Xcode (new files, target membership, capabilities).
- Don't guess APIs. If something isn't in your spec or `Reference/WorkspaceAssistant-Lite`, say so and ask for the documentation.
- After each step, say how to test it in one or two lines.

## Your files
```
DejaView/
  Services/
    SearchEngine.swift
  Agent/
    SearchSavedPostsTool.swift   ← tool + LibrarySearch
    AskService.swift
  Views/
    RootView.swift
    LibraryView.swift
    PostCardView.swift
    PostDetailView.swift
    AskView.swift
    ReviewListView.swift
    Components.swift             ← chips, banner, toast
```

## What you need from others
- Shared model (A, by 11:20). Until then, use the shared contract's types in a scratch file you delete after pulling.
- `PostAnalyzer.isAvailable` / `unavailableReason` and `ModelErrors` (B, stubs by 11:20).
- `AddLinkView` (A, stub by 11:20): present it from the `+` button.
- `PostProcessor` (B) from the environment for "Retry with AI".
- You don't need real posts to build: use your DEBUG "Add sample posts" button.

## Your timeline
| Time | Do |
|---|---|
| 11:00–11:20 | `RootView` stub (TabView with three placeholder tabs) → **push** |
| 11:20–11:50 | C1 Library, card, detail, sample posts |
| 11:50–12:10 | C2 SearchEngine |
| 12:10–12:30 | C3 tool + AskService + AskView (keep going after lunch if needed; this is the demo) |
| 13:30–14:15 | Finish/polish Ask; C4 Review list |
| 14:30 | C5 stretch only if readiness is met |
| 15:00 | Freeze |

## Verified Foundation Models API (use only these)
```swift
import FoundationModels

// Tool shape (from the sample's Tools.swift)
struct SomeTool: Tool {
    let name = "verbName"
    let description = "One sentence: when to use it."
    @Generable struct Arguments { @Guide(description: "…") var x: String }
    func call(arguments: Arguments) async throws -> String { /* honest result sentence */ }
}

// Session with tools (from the sample's TaskAgent)
let session = LanguageModelSession(model: SystemLanguageModel.default, tools: [tool], instructions: instructions)
session.isResponding     // one request at a time: disable Submit while true

// Streaming text (from the sample's TaskAgent.send)
for try await snapshot in session.streamResponse(to: question) { answerText = snapshot.content }

// @Guide: description:, .range(…), .count(…), .maximumCount(…), .anyOf([…]); @Generable enums with String raw values
```
Errors: use B's `ModelErrors.classify` and `message(for:)`. `LanguageModelSession.ToolCallError` (your tool threw) maps to `.toolFailed`. The sample's `catch … as GenerationError` doesn't work with Xcode 27.

## Requirements

### SearchEngine (pure Swift, no model; also the fallback)
```swift
struct SearchQuery { var category: CategoryFilter = .any; var dateRange: DateRangeOption = .any; var platform: PlatformFilter = .any; var keywords: [String] = [] }
struct SearchResult: Identifiable { let post: SavedPost; let reason: String; var id: UUID { post.id } }
enum SearchEngine {
    static func search(_ query: SearchQuery, in posts: [SavedPost], now: Date = .now) -> (results: [SearchResult], relaxedNote: String?)
    static func keywords(fromRaw text: String) -> [String]   // lowercase words, drop stop words ("the", "my", "posts", "saved", "i", "a", "from", "on", "about"), max 5
}
```
1. Filter by category, platform and date range (`.any` = no filter; `today`, `last7Days`, `last30Days` from `savedAt`).
2. Score: +3 per keyword in tags, +2 in summary, +1 in caption, ocrText, englishText or userNote (case-insensitive, prefix match on words).
3. With keywords: drop score 0, sort by score then date. Without keywords: all filtered posts, newest first.
4. Nothing found → relax: drop the date filter, then the category; then keywords only. Record `relaxedNote` (e.g. "No exact match; showing results from any date.").
5. `reason` per result, e.g. "Design · 'figma' in caption" or "Design · this week".
6. Keep results to 20 for the UI.

### The tool (required by the capstone)
```swift
@Generable enum CategoryFilter: String, CaseIterable { case any, design, foodRecipes, travel, tech, tipsLearning, shopping, entertainment, other }
@Generable enum DateRangeOption: String, CaseIterable { case any, today, last7Days, last30Days }
@Generable enum PlatformFilter: String, CaseIterable { case any, instagram, tiktok, threads, x, facebook, web, screenshot }

struct SearchSavedPostsTool: Tool {
    let name = "searchSavedPosts"
    let description = "Finds posts the user saved, by category, date, platform and keywords."
    let library: LibrarySearch

    @Generable
    struct Arguments {
        @Guide(description: "Category only if the user clearly names one, otherwise any")
        var category: CategoryFilter
        @Guide(description: "Time range the user mentions, otherwise any")
        var dateRange: DateRangeOption
        @Guide(description: "Platform only if the user names one, otherwise any")
        var platform: PlatformFilter
        @Guide(description: "Up to 5 topic words from the request", .maximumCount(5))
        var keywords: [String]
    }

    func call(arguments: Arguments) async throws -> String { await library.run(arguments) }
}
```
`.any` cases are used instead of optionals (optionals inside `@Generable` aren't shown in the course code).

**`LibrarySearch`** — `@MainActor @Observable final class`, created per question with the current posts (fetched from `modelContext`):
- `run(_:)`: clean keywords (trim, lowercase, drop empty, max 5; also add `SearchEngine.keywords(fromRaw: question)` so Indonesian words in the question still match the original caption), call `SearchEngine.search`, store `results`, store `label` like "Searched: Design · last 7 days" (or "Searched: all posts · 'resep'"), and return an **honest sentence**:
  - Found: `"Found 3 saved posts: 1) <summary> (Design, Instagram, 2 days ago). 2) … Only describe these posts."` (top 5 summaries only, to save tokens)
  - Relaxed: `"No posts matched all filters. <relaxedNote> Found 2: …"`
  - None: `"No saved posts match <label>. Nothing was found."`
- The tool is read-only: it never changes or deletes anything.

### AskService
`@MainActor @Observable final class AskService`: `answerText`, `results`, `label`, `isResponding`, `errorMessage`, `func ask(_ question: String, posts: [SavedPost]) async`.
- Ignore if `isResponding` or the question is empty.
- **Model available:** create a `LibrarySearch` and a **new** `LanguageModelSession(model: .default, tools: [SearchSavedPostsTool(library:)], instructions: askInstructions)` per question. Stream with `streamResponse(to:)` into `answerText`. Mirror `library.results` and `library.label` so the UI shows the tool chip and posts as soon as the tool runs (like the sample's `liveActions`).
- **Errors:** `errorMessage = ModelErrors.message(for: ModelErrors.classify(error))`; still show any results the tool found; if the tool never ran, run the keyword fallback.
- **Model unavailable:** `SearchEngine.search(SearchQuery(keywords: SearchEngine.keywords(fromRaw:)), …)`, no answer text, label "Keyword search".

**Ask instructions:** "You help the user find posts they saved. Always call searchSavedPosts to look before answering. Only mention posts the tool returned. If it found nothing, say so plainly. Reply in one or two short English sentences."

### UI (native iOS; system components, text styles, system colours, SF Symbols only, never platform logos)
**RootView:** `TabView` — Library (`square.grid.2x2`), Ask (`sparkle.magnifyingglass`), Review (`tray`, badge = count of `.needsReview`, hidden at 0). Optional: `Tab(role: .search)` for Ask, only if it compiles first try.

**Components.swift**
- Category chip: capsule, symbol + displayName, `.caption.weight(.semibold)`, colour at 15% background, full colour text. Selected filter: full colour background, white text.
- Unavailable banner: rounded rect, yellow at 15%, `exclamationmark.triangle`, `PostAnalyzer.unavailableReason` + "Basic save and search still work.", `.footnote`.
- Tool chip: capsule, `magnifyingglass` + label, `.caption`, `Color(.tertiarySystemFill)`.
- Toast: capsule at the top, `.regularMaterial`, checkmark + "Saved", 1.5 s.

**LibraryView**
- Large title "Déjà View"; toolbar `+` → `AddLinkView` sheet. Banner when unavailable.
- Horizontal filter chips: "All" + categories that have posts.
- 2-column `LazyVGrid` (12 pt gaps, 16 pt margins) of `PostCardView`, newest first (`@Query`).
- Empty: `ContentUnavailableView` with `rectangle.on.rectangle`, "Nothing saved yet", "You've seen it before. Now you can find it again. Share a post to Déjà View or paste a link.", button "Paste a link".
- DEBUG toolbar button "Add sample posts": 8 processed posts across categories and platforms over the last 10 days, some with Indonesian captions (include "Resep ayam geprek sambal bawang…" as Food & Recipes, and "Diera sekarang, kamu gagal jadi designer kalau hasilnya kalah sama AI" as Design), plus one `.needsReview` post "wait for it 😂".

**PostCardView**
- Thumbnail 4:5 fill, clipped (no image: category colour at 15% with a large category symbol). Summary (2 lines, `.subheadline`; caption in `.secondary` if no summary), category chip, relative date (`.caption2`), platform label (`.caption2`, `.secondary`). Background `Color(.secondarySystemBackground)`, radius 16 continuous.
- `.pending`: soft gray image area with `sparkles` + `.symbolEffect(.pulse)`, "Processing…".
- `.needsReview`: small yellow dot on the image + VoiceOver "Needs review".
- Animate status changes (`.animation(.smooth, value:)`) and `.sensoryFeedback(.success, trigger:)` when processing finishes.
- VoiceOver label: "Summary. Category. Platform. Date."; thumbnail `accessibilityHidden`.

**PostDetailView**
- Hero image (max ~45% height), category chip + platform + date, summary in `.title3`, tag chips, "Open original" (`.borderedProminent`, `arrow.up.right.square`).
- Category `Picker` (menu) with symbols; note `TextField(axis: .vertical)`. Changing the category or saving a non-empty note on a `.needsReview` post → `.processed`.
- `DisclosureGroup("What Déjà View read")`: caption, OCR text, English translation if any.
- Toolbar menu: "Retry with AI" (`arrow.clockwise`; set `.pending`, call `processor.processPending`) and "Delete" (destructive, `confirmationDialog`).

**AskView** (the signature screen)
- Empty state: `sparkle.magnifyingglass`, "Ask Déjà View", "Find a post by describing it.", three example chips (full-width `.bordered` capsules with `sparkles`): "Design posts from this week", "Recipes I saved", "Travel tips on TikTok". Tapping fills and submits.
- Bottom text field "What are you looking for?" + `arrow.up.circle.fill`; disabled while `isResponding`.
- While answering: tool chip (animate in with `.scale.combined(with: .opacity)`), answer card with the streamed text, and a slowly rotating `AngularGradient` stroke around it (purple, blue, teal, orange, pink). Reduce Motion → static gradient.
- Results below as cards, each with its `reason` in `.caption` `.secondary`, animating in.
- No match: the honest answer plus "Nothing saved about that yet." Make it look intentional (it's the graceful-failure beat). `.sensoryFeedback(.warning, …)`.
- `errorMessage` shown as a friendly line, never a raw error.
- Unavailable: banner, keyword results only.

**ReviewListView** (Sprint 2)
- Title "Needs review", subtitle "Déjà View wasn't sure about these. Fix them when you have a moment."
- `List` rows: 56×56 thumbnail (radius 10), caption or summary (2 lines), `statusMessage` in `.caption` orange. Tap → detail. Empty: `ContentUnavailableView` "All caught up" with `checkmark.circle`.

**Accessibility:** Dynamic Type everywhere (test the largest sizes for the projector), 44×44 tap targets, colour never the only signal.

## Prompts for your agent (in order)
**Start every session with:**
> Read docs/SPEC-C-Find.md. You are Person C. Only create or edit the files listed under "Your files". Don't edit Xcode project files; tell me what to add in Xcode. For Foundation Models, use only the "Verified Foundation Models API" section and Reference/WorkspaceAssistant-Lite (Tools.swift, TaskAgent.swift), and use B's ModelErrors for errors. Don't guess APIs; ask if unsure. After each step, tell me how to test it.

**Stub (push by 11:20)**
> Create Views/RootView.swift: a TabView with Library, Ask and Review tabs (symbols from the spec) showing placeholder text.

**C1 — Library, cards, detail**
> Build Components.swift (category chip, unavailable banner, tool chip, toast), LibraryView, PostCardView and PostDetailView per the UI requirements, using @Query for SavedPost. Include the DEBUG "Add sample posts" button with the exact samples described. Present AddLinkView from the + button. Use @Environment(PostProcessor.self) for "Retry with AI".

**C2 — SearchEngine**
> Implement Services/SearchEngine.swift exactly per the "SearchEngine" requirements (SearchQuery, SearchResult, search, keywords(fromRaw:), relax steps, reasons). Add a few Swift Testing tests using in-memory sample posts: "design" + last7Days finds the design post; "resep" finds the Indonesian recipe; a travel query with none saved returns nothing after relaxing.

**C3 — Tool, AskService, AskView**
> Implement Agent/SearchSavedPostsTool.swift (the filter enums, the tool, and LibrarySearch with the honest result sentences) and Agent/AskService.swift exactly per the requirements, following the streaming pattern in Reference/WorkspaceAssistant-Lite/WorkspaceAssistant/Agent/TaskAgent.swift send(_:). Then build Views/AskView.swift per the AskView requirements.

**C4 — Review list (Sprint 2)**
> Build ReviewListView per the requirements and the Review tab badge.

**C5 — stretch, only after 14:30 readiness**
> Add a second tool showLibrary(category: CategoryFilter) that switches the Library tab to that category filter with animation and returns an honest sentence ("Showing 4 Design posts." / "Already showing Design."). Register it with searchSavedPosts in AskService.

## Done when
- [ ] 11:20: `RootView` stub pushed.
- [ ] Sample posts look good in Library and detail, in light and dark mode, at large text sizes.
- [ ] "Design posts from this week" → tool chip, the design post, a streamed one-sentence answer — **three times in a row**.
- [ ] "Recipes I saved" and "resep" find the Indonesian recipe post.
- [ ] "Travel posts from yesterday" → honest "nothing found", intentional-looking empty state.
- [ ] Model unavailable: banner + keyword results.
- [ ] Ask works in Airplane Mode.
- [ ] Sprint 2: Review list fixes a post by category or note.

## Demo role
You drive the **Ask** beat (the centre of the demo): Airplane Mode on, "Design posts from this week", "resep", then the graceful failure "Travel posts from yesterday". Then show `SearchSavedPostsTool` in Xcode: verb name, one-sentence description, typed enum arguments with `.any`, and the honest "Nothing was found" result. Be ready for: "What does your tool return when nothing exists?" and "Which tool could do damage?" (none: read-only, enums, capped keywords).
