# Déjà View — build plan and agent prompts (capstone, Plan B)

> You've seen it before. Now you can find it again.

Three people (A: Capture, B: Understand, C: Find). Each person drives their own AI agent with the prompts in their section, in order. Every prompt assumes the agent has read `SPEC.md`.

## Today's clock

| Time | Goal |
|---|---|
| 10:45–11:00 | Setup (manual, together) — project builds on the iPhone, everyone on git |
| 11:00–12:30 | **Sprint 1:** paste link → analyzed → found by asking (tool + streamed answer) |
| **12:30** | **Safe to fail:** availability banner, error handling, Submit disabled while answering. **Commit / zip a working copy before lunch.** |
| 13:30–14:15 | **Sprint 2, in parallel:** A share extension · B screenshot OCR · C Needs review. At 14:15 drop whatever isn't working. |
| **14:30** | **Readiness:** readiness targets in SPEC.md met, demo request works three times in a row |
| **15:00** | **Feature freeze** — only bug fixes |
| 15:00–15:30 | Demo script, two timed rehearsals, backup recording |
| 15:30 | Demo |

## Setup checklist (one person, ~15 min, by hand)
1. Xcode 27 → New Project → iOS App → name `DejaView` (no accent), SwiftUI, Storage: None, iOS 27. General tab → Display Name `Déjà View`.
2. Signing & Capabilities → your team.
3. File → New → Target → Share Extension → `DejaViewShare`, iOS 27, same team, Display Name `Déjà View`.
4. **App Groups** capability on both targets: `group.com.H747JY2BA4.dejaview`. Put the real ID in `SPEC.md`.
5. Build settings for both targets: Swift 6.0, Approachable Concurrency Yes (match the sample).
6. Create groups Shared, Services, Agent, Views. Files in `Shared/` get membership in **both** targets.
7. Copy `WorkspaceAssistant-Lite` into `Reference/` next to the project (not in any target). Copy `SPEC.md` and `DESIGN.md` into the project root.
8. Build and run the empty app on the iPhone once.
9. iPhone: Apple Intelligence on, language English. **Translate app: download Indonesian and English** (needed if B0 fails).
10. git: one branch per person, only edit your own files, merge at least every hour.

## Prompt to start every agent session
> Read SPEC.md and DESIGN.md in the project root (DESIGN.md for anything visual). You are working on the parts owned by person [A/B/C]. Only create or edit the files listed for [A/B/C]. Don't edit Xcode project files; tell me what to add in Xcode instead. For Foundation Models use only the APIs in SPEC.md's "Verified Foundation Models API" section and the working code in Reference/WorkspaceAssistant-Lite. Its error handling is the old Xcode 26 style; we build with Xcode 27, so use ModelErrors as described in SPEC.md. If you need any API that isn't listed, say so instead of guessing. After each step, tell me how to test it.

---

## Person A — Capture

**A1 (Sprint 1, first). Shared model**
> Create Shared/SavedPost.swift, PostCategory.swift, Platform.swift and SharedContainer.swift exactly as in SPEC.md, with the computed properties and Platform.detect(from:). SharedContainer stores data in the App Group container with no CloudKit. Wire it into DejaViewApp.swift with .modelContainer. Tell me which files need membership in both targets.

*Done when:* a test `SavedPost` persists after relaunch. **Push immediately; B and C depend on it.**

**A2 (Sprint 1). Link fetcher**
> Implement Services/LinkFetcher.swift conforming to LinkFetching (struct LinkPreview { title, caption, imageData }). Use LPMetadataProvider for the title and image (load imageProvider into Data, downscale to max 1600 px JPEG). Also download the page HTML with URLSession and read og:title and og:description as a backup caption; ignore failures. 10-second timeout. Never throw; return empty fields on failure.

*Done when:* a debug button prints captions for one Instagram, TikTok, Threads, X and Facebook link. **Write down which platforms return a caption.**

**A3 (Sprint 1). Add link screen** (J2)
> Create Views/AddLinkView.swift: a sheet with a text field prefilled from the clipboard if it holds a URL, inline validation error, and Save. Save creates a SavedPost with the detected platform and status .pending, inserts it, dismisses, then calls PostProcessor.processPending. Leave a placeholder section for "Pick screenshot" (A5).

**A4 (Sprint 2). Share extension** (J1)
> Implement DejaViewShare/ShareViewController.swift and ShareView.swift per SPEC.md: read one URL, one image, or text containing a URL from extensionContext; save a .pending SavedPost into SharedContainer; show "Saved to Déjà View ✓" for about a second; complete the request. Downscale images to 1600 px JPEG. Tell me exactly what to put in the extension's Info.plist (NSExtensionActivationRule for one web URL and one image).

*Stop rule:* not working by 14:15 → drop it; demo with paste.

**A5 (Sprint 2, if A4 is done or dropped). Pick screenshot** (J3)
> In AddLinkView, add "Pick screenshot" with PhotosPicker (images only): create a SavedPost with platform .screenshot, the image downscaled to 1600 px JPEG, status .pending; insert, dismiss, call processPending.

---

## Person B — Understand

**B0 (first 20 minutes). Indonesian test — decides the plan**
> In Playground/IndonesianTest.swift, write a minimal async test (or an Xcode #Playground block) that prints SystemLanguageModel.default.availability, then for each input below creates a LanguageModelSession with SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations) and the analyzer instructions from SPEC.md, and calls respond(to:generating: PostAnalysis.self) with the text wrapped in POST START / POST END. Print the result, or the error and its type.
> 1. "Diera sekarang, kamu gagal jadi designer kalau hasilnya kalah sama AI"
> 2. "Resep ayam geprek sambal bawang, cuma 15 menit! #resep #masakanrumahan"
> 3. "Winter 2026 | Conceptual Design. Prompts & full project link on Behance #design #ad"
> 4. "wait for it 😂"
> 5. "Tips hemat tiket pesawat ke Bali: beli hari Selasa #traveltips"

*Decision:* if 1, 2 or 5 throw `unsupportedLanguageOrLocale` or give poor results → build **B2b (translation)** in Sprint 1. If they're good → skip B2b. Tell the team the result.

**B1 (Sprint 1). Errors**
> Implement Services/ModelErrors.swift exactly as SPEC.md's "Errors: Xcode 27 changed them": a ModelFailure enum, classify(_:) using LanguageModelError, SystemLanguageModel.Error, LanguageModelSession.Error and LanguageModelSession.ToolCallError inside #available(iOS 27.0, *), and message(for:) with the user-facing sentences. If any case name doesn't compile, tell me the exact compiler error instead of guessing a replacement.

**B2 (Sprint 1). Analyzer**
> Implement Services/PostAnalyzer.swift: unavailableReason (from SPEC.md), isAvailable, prewarm() (called at launch), and analyze(text:) that creates a new LanguageModelSession with SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations) and the analyzer instructions, wraps the text in POST START / POST END, and returns try await session.respond(to:generating: PostAnalysis.self).content. Add a debug flag forceUnavailable. Let errors propagate.

**B2b (Sprint 1, only if B0 failed). Language**
> Implement Services/LanguageService.swift: detectLanguage(_:) with NLLanguageRecognizer returning a language code, and translateToEnglish(_:) using the Translation framework's TranslationSession with Indonesian as the installed source and English as the target. If the languages aren't installed or translation fails, return nil. If you're not sure of the exact TranslationSession initializer for iOS 27, say so and ask me for the documentation.

**B3 (Sprint 1). Processor**
> Implement Services/PostProcessor.swift following SPEC.md's "Processing rules" exactly: fetch, (OCR later), empty-text case, language step (use LanguageService if it exists), trim, analyze, classify errors with ModelErrors, translate-and-retry once on unsupportedLanguage, fallback. One post at a time; never leave a post in .pending. Call processPending when the app becomes active (scenePhase .active). Skip OCR with a TODO for now.

*Done when:* pasted links get summaries and categories; with `forceUnavailable` (or the scheme's simulated availability) they get the fallback and land in Needs review. **Push and tell C.**

**B4 (Sprint 2). OCR** (J3)
> Implement Services/OCRService.swift with Vision text recognition (accurate, language correction on; English plus Indonesian if supported, checked at runtime). Return lines joined by newlines. Enable step 2 in PostProcessor.

**B5 (14:30, readiness owner).** Walk through SPEC.md's production-readiness table and Definition of done with the team; fix gaps.

---

## Person C — Find

**C1 (Sprint 1). Library UI**
> Create Views/LibraryView.swift, PostRowView.swift and PostDetailView.swift per SPEC.md's UI section, using @Query for SavedPost sorted by savedAt descending. Include the unavailable banner, the empty state with the tagline, a "+" button for AddLinkView, a Needs review count, row animations and .sensoryFeedback when a post finishes processing. Add a DEBUG-only "Add sample posts" button that inserts 8 processed posts across categories and platforms, some with Indonesian captions, saved over the last 10 days. Use the SavedPost from SPEC.md until A pushes.

**C2 (Sprint 1). SearchEngine**
> Implement Services/SearchEngine.swift following SPEC.md's "SearchEngine rules": pure Swift, no Foundation Models, filter + score + relax + reason strings. Write it so the fallback can call it with raw query words. Add 4–5 quick checks (Swift Testing or a debug function) using the sample posts.

**C3 (Sprint 1). The tool and Ask** (J11, J13)
> Implement Agent/SearchSavedPostsTool.swift exactly as SPEC.md's "The tool", with the CategoryFilter, DateRangeOption and PlatformFilter enums, and a @MainActor @Observable LibrarySearch that runs SearchEngine over the current posts, stores the results and a label like "Searched: Design · last 7 days", and returns the honest result sentence. Then implement Agent/AskService.swift: for each question, create a new LanguageModelSession(model: SystemLanguageModel.default, tools: [tool], instructions: <Ask instructions from SPEC.md>), stream the answer with streamResponse(to:), and expose answerText, isResponding and a user-facing error via ModelErrors. If the model is unavailable, call SearchEngine directly with the raw words. Then build Views/AskView.swift: 3 tappable example prompts, a text field, Submit disabled while responding, the tool chip, results with reasons, and the streamed answer. Follow the streaming pattern in Reference/.../TaskAgent.swift send(_:).

*Done when:* with the sample posts, "Design posts from this week", "Recipes I saved", "Travel tips on TikTok" and "resep" give the right posts with a one-sentence answer; "Travel posts from yesterday" gives an honest "nothing found"; with the model forced off, keyword search still works.

**C4 (Sprint 2). Needs review** (J9, J10)
> Create Views/ReviewListView.swift (posts with .needsReview). In PostDetailView, changing the category or saving a non-empty note sets status .processed. Add "Retry with AI" (reset to .pending, call processPending) and delete with a confirmation dialog.

**C5 (stretch, only after 14:30 readiness). UI the model can change**
> Add a second tool showLibrary(category: CategoryFilter) that sets the library's visible category filter with animation and returns an honest sentence ("Showing 4 Design posts." / "Already showing Design."). Register it alongside searchSavedPosts.

---

## Merge order
1. A1 → everyone pulls.
2. B1 + B2 + B3 (+ B2b), A2 + A3, C1 + C2 + C3 → **12:30 safe to fail**, commit before lunch.
3. A4/A5, B4, C4 → 14:15 keep or drop → 14:30 readiness → 15:00 freeze.

## 3-minute demo (four beats, per the course)
**Before going on:** one Instagram and one TikTok link already saved (link fetching needs the network), sample library loaded, one request sent to warm up, Do Not Disturb on, large text, Xcode open at `SearchSavedPostsTool.swift` and `PostAnalysis`.

1. **0:00–0:20 · The problem.** "We all save posts and never find them again. Déjà View: you've seen it before, now you can find it again."
2. **0:20–2:00 · Live demo.**
   - Share an Instagram post (or paste the link) → "Saved ✓" → the Indonesian design post now has an English summary and the Design category.
   - Turn on **Airplane Mode**. Ask "Design posts from this week" → the "Searched: Design · last 7 days" chip, the post appears, the answer streams in.
   - Ask "resep" → the Indonesian recipe post.
   - **Graceful failure:** ask "Travel posts from yesterday" → the tool honestly reports nothing, and the answer says so. (Optional: show a vague post sitting in Needs review.)
3. **2:00–2:35 · Under the hood.** Show `SearchSavedPostsTool` in Xcode: a clear verb name, one-sentence description, typed enum arguments with `.any`, and what it returns when nothing matches. Show `PostAnalysis` and the POST START/END markers that keep captions from being treated as instructions.
4. **2:35–3:00 · Why on-device, and what's next.** Saved posts reveal your interests, so they never leave the phone; it works offline (Airplane Mode just proved it) and costs nothing per request. Next: save screenshots automatically with the iOS 27 screenshot automation, and ask Siri.

**Backup:** a screen recording of the full demo, demo prompts saved in Notes, a way to reset the library to the demo state.

**Judges' likely questions, and our answers**
- *iPhone without Apple Intelligence?* Banner; saving, fallback summaries and keyword search still work.
- *What does your tool return when nothing exists?* An honest "Nothing was found" sentence; the model only describes posts the tool returned.
- *Which tool could do damage?* None: the only tool is read-only, arguments are enums, keywords are capped. Delete is a user action with confirmation.
- *After 30 messages?* There's no long chat: each question and each post gets a fresh session, so the context window never fills.
- *Why on-device?* Privacy, offline, no per-request cost. And Indonesian: translated on-device, never sent to a server.

## If you fall behind
- 12:30 and the Ask flow isn't working end to end → everyone fixes it; Sprint 2 shrinks to OCR only.
- Share extension not working by 14:15 → drop it, demo with paste.
- Indonesian results poor even after translation → show it honestly; the original caption still makes "resep" findable.
