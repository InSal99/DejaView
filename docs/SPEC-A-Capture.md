# Déjà View — Spec for Person A: Capture

> You've seen it before. Now you can find it again.

**Your mission:** get posts into the app. You own the Xcode setup, the shared data model, link fetching, the Add sheet and the share extension. B and C depend on your shared files, so **push `Shared/` first.**

**Give your agent:** run Claude Code in the `deja-view` folder and type `/person-a` (it loads `CLAUDE.md` and this file). Agents also use `Reference/WorkspaceAssistant-Lite` for SwiftUI style.

**Jobs you deliver:** J1 save from any app (share sheet) · J2 paste a link · J3 save a screenshot (picker) · J4 works for TikTok, Instagram, Threads, X, Facebook and the web · J8 no interruptions while saving.

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
  DejaViewApp.swift
  Shared/            ← membership in BOTH targets
    SavedPost.swift
    PostCategory.swift
    Platform.swift
    SharedContainer.swift
    ImageTools.swift
  Services/
    LinkFetcher.swift
  Views/
    AddLinkView.swift
DejaViewShare/
  ShareViewController.swift
  ShareView.swift
```

## What you need from others
- `PostProcessor` (B) and `RootView` (C): they push stubs by 11:20. Until then, keep `DejaViewApp` compiling with a temporary `Text("Déjà View")` root if needed, and remove it when you pull their stubs.

## Your timeline
| Time | Do |
|---|---|
| 10:45–11:00 | Xcode setup (below) |
| 11:00–11:20 | A1 shared files + `LinkFetcher`/`AddLinkView` stubs → **push** |
| 11:20–12:00 | A2 link fetcher |
| 12:00–12:30 | A3 Add sheet; merge; check the paste flow end to end with B's processor |
| 13:30–14:15 | A4 share extension (stop rule: drop at 14:15 if not working) |
| 14:15–14:45 | A5 screenshot picker |
| 15:00 | Freeze |

## Xcode setup (by hand, ~15 min)
The `deja-view` folder already has `CLAUDE.md`, `README.md`, `.gitignore`, `docs/`, `setup/claude-commands/` and `Reference/`.
1. Terminal, in `deja-view`: `mkdir -p .claude/commands && cp setup/claude-commands/*.md .claude/commands/` (installs `/person-a`, `/person-b`, `/person-c`, `/checkpoint`), then `git init && git add . && git commit -m "Docs and setup"`. Create the GitHub repo and push `main`.
2. Xcode 27 → New Project → iOS App → Product Name `DejaView`, SwiftUI, Storage: None. **Save location: the `deja-view` folder.** Uncheck "Create Git repository" (the repo already exists). Xcode creates `deja-view/DejaView/` with the `.xcodeproj` inside.
3. Target → General → Display Name `Déjà View`; Minimum Deployments iOS 27.
4. Signing & Capabilities → the shared team.
5. File → New → Target → Share Extension → `DejaViewShare`, same team, iOS 27, Display Name `Déjà View`. Activate its scheme when asked.
6. **App Groups** on both targets: `group.com.TEAMID.dejaview` (real team ID; tell B and C, and replace TEAMID in the docs).
7. Both targets: Swift 6.0, Approachable Concurrency Yes.
8. Check the source folders are synced folders (blue icons; right-click shows "Convert to Group"). If they're grey groups, right-click → "Convert to Folder".
9. In `DejaView/DejaView/` create folders Shared, Services, Agent, Views. Select `Shared` → File inspector → Target Membership: tick **both** `DejaView` and `DejaViewShare`.
10. Run the empty app on the iPhone once.
11. Commit and push: `git add . && git commit -m "A: Xcode project" && git push`. B and C clone and create their branches.

## Requirements

### Shared files
- Exactly the data model in the shared contract, including `displayName`, `color` and `symbol` on `PostCategory`, and `displayName` on `Platform`.
- `SharedContainer.container`: `ModelContainer(for: SavedPost.self, configurations: ModelConfiguration(groupContainer: .identifier("group.com.TEAMID.dejaview"), cloudKitDatabase: .none))`. If creating it fails, crash with a clear message in DEBUG (it's a setup error).
- `ImageTools.downscaledJPEG`: decode with ImageIO, longest side ≤ 1600 px, JPEG quality 0.8.

### LinkFetcher (J4)
- `LPMetadataProvider` (LinkPresentation): `title` and the image (`imageProvider` → `Data` → `ImageTools.downscaledJPEG`).
- Backup: download the HTML with `URLSession` and read `og:title` and `og:description` meta tags.
- `caption` = og:description if present, else the LP title. `title` = LP title or og:title.
- 10-second timeout. **Never throw**: return empty fields on any failure (B's processor turns empty text into Needs review).
- Write down which platforms return a caption (Instagram, TikTok, Threads, X, Facebook). The team needs this for the demo.

### AddLinkView (J2, J3)
Design: `.sheet` with `.presentationDetents([.medium])`, title "Save a post".
- Link field prefilled from the clipboard if it contains a URL (`UIPasteboard.general.url` / `.string`).
- Inline error in `.caption` red: "That doesn't look like a link". Clear it when the text changes.
- Save → `SavedPost(urlString:platform: Platform.detect(from:))`, status `.pending`, insert, dismiss, then `await processor.processPending(in: modelContext)`.
- In-app toast is C's job; you just dismiss.
- Sprint 2 (A5): `PhotosPicker` button "Pick a screenshot" (`photo.on.rectangle`, images only) → `SavedPost(platform: .screenshot, imageData: ImageTools.downscaledJPEG(...))`, `.pending`, insert, dismiss, process.

### Share extension (J1, J8) — Sprint 2
- Accepts one web URL, one image, or plain text containing a URL (`NSItemProvider` with `UTType.url`, `.image`, `.plainText`).
- Saves a `.pending` `SavedPost` into `SharedContainer.container` (images downscaled). Does **not** run any model.
- UI: small centred card, `.regularMaterial`, corner radius 20, `checkmark.circle.fill` in green with `.symbolEffect(.bounce)`, text "Saved to Déjà View". Closes itself after ~1 s (`extensionContext?.completeRequest`). No buttons, no questions.
- Info.plist `NSExtensionActivationRule`: web URL max count 1, image max count 1, text max count 1. Ask the agent for the exact keys.
- The main app processes the post the next time it becomes active (already wired in `DejaViewApp`).

## Prompts for your agent (in order)
**Start every session with:**
> Read docs/SPEC-A-Capture.md. You are Person A. Only create or edit the files listed under "Your files". Don't edit Xcode project files; tell me what to add in Xcode. Don't guess APIs; ask if unsure. After each step, tell me how to test it.

**A1 — shared files (push by 11:20)**
> Create every type in the shared contract's data model in Shared/ exactly as written (SavedPost with its computed properties, PostStatus, Platform with detect(from:) and displayName, PostCategory with displayName, color and symbol, SharedContainer, ImageTools). Also create Services/LinkFetcher.swift and Views/AddLinkView.swift as compiling stubs with the exact public signatures (fetch returns an empty LinkPreview; the view shows "Coming soon"). Write DejaViewApp.swift exactly as the shared contract's app wiring. Tell me which files need membership in both targets.

**A2 — link fetcher**
> Implement LinkFetcher.fetch per the "LinkFetcher" requirements: LPMetadataProvider for title and image, URLSession + og:title/og:description backup, 10-second timeout, never throw. Add a DEBUG-only helper I can call with five sample links that prints what comes back for each.

**A3 — Add sheet**
> Implement AddLinkView per the "AddLinkView" requirements (link part only for now): clipboard prefill, validation error, save as .pending, dismiss, then await processor.processPending(in: modelContext) using @Environment(PostProcessor.self) and @Environment(\.modelContext).

**A4 — share extension (Sprint 2)**
> Implement DejaViewShare/ShareViewController.swift and ShareView.swift per the "Share extension" requirements. Host the SwiftUI ShareView in the view controller. Read one URL, image, or text containing a URL; save a .pending SavedPost into SharedContainer.container; show the confirmation card for about a second; complete the request. Tell me exactly what to put in the extension's Info.plist.

**A5 — screenshot picker (Sprint 2)**
> Add the PhotosPicker part of AddLinkView per the requirements.

## Done when
- [ ] 11:20: shared files pushed; B and C build against them.
- [ ] Pasting a link from each platform creates a post that B's processor fills in (or sends to Needs review with a reason).
- [ ] You know which platforms return captions.
- [ ] Sprint 2: Share → Déjà View from Instagram saves the post; opening the app processes it.
- [ ] Sprint 2: picking a screenshot creates a post B's OCR reads.

## Demo role
You drive the **save** beat: share (or paste) the Instagram post, show "Saved ✓", and show it appearing processed. Before going on: save one Instagram and one TikTok link while online (fetching needs the network; the rest of the demo runs in Airplane Mode).
