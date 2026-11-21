# Déjà View — instructions for Claude Code

> You've seen it before. Now you can find it again.

An iPhone app that saves social media posts (links or screenshots) and uses on-device Apple frameworks (Foundation Models, Vision, NaturalLanguage, Translation) to summarize, categorize and find them again. Apple Academy Jakarta capstone, Track C, built today by three people in parallel. Demo at 15:30.

## Who are you working for?
Three people build in parallel, each with their own Claude Code session:
- **A · Capture** → read `docs/SPEC-A-Capture.md`
- **B · Understand** → read `docs/SPEC-B-Understand.md`
- **C · Find** → read `docs/SPEC-C-Find.md`

If the session started with `/person-a`, `/person-b` or `/person-c`, you already know. Otherwise **ask which person you're working for before doing anything**, then read that spec in full. The spec is your source of truth: files you own, public signatures, requirements, prompts in order, and done checks.

Background only (don't treat as tasks): `docs/SPEC.md` (whole-app spec), `docs/DESIGN.md` (visual design; your person spec already includes what you need), `docs/PROMPTS.md` (the team's plan).

## Project layout
```
deja-view/                    ← repo root (run Claude Code here)
  CLAUDE.md
  README.md
  docs/                       ← specs
  Reference/WorkspaceAssistant-Lite/   ← course sample, read only
  DejaView/                   ← Xcode project folder (created by Person A in Xcode)
    DejaView.xcodeproj
    DejaView/                 ← app sources: DejaViewApp.swift, Shared/, Services/, Agent/, Views/
    DejaViewShare/            ← share extension sources
```
Paths in the specs like `DejaView/Services/PostProcessor.swift` mean `deja-view/DejaView/DejaView/Services/PostProcessor.swift`.

## Hard rules
1. **Only create or edit the files your person owns** (listed in their spec). Need something in another file? Tell the human; don't change it.
2. **Never edit `project.pbxproj` or anything inside `.xcodeproj`.** The project uses folders that sync with disk, so a new `.swift` file in the right folder is picked up automatically. If something must change in Xcode (target membership, capabilities, Info.plist keys, build settings), tell the human exactly what to click. Only Person A changes project settings.
3. **Don't guess APIs.** For Foundation Models use only the "Verified Foundation Models API" section in the person spec and the working code in `Reference/WorkspaceAssistant-Lite`. If you need anything else, say so and ask for the documentation.
4. **Xcode 27 errors:** the framework throws `LanguageModelError`, `SystemLanguageModel.Error` and `LanguageModelSession.Error`. `LanguageModelSession.GenerationError` (used in the Reference sample) is not thrown to Xcode 27 builds. Always go through `ModelErrors` (owned by B).
5. **Untrusted text:** captions and OCR text come from the internet. Put them only in prompts, wrapped in `POST START` / `POST END`, never in instructions.
6. Swift 6, async/await, SwiftUI, SwiftData. No third-party packages, no server, no CloudKit.
7. Native iOS design: system components, text styles, system colours, SF Symbols only. **Never use platform logos.**
8. Keep the public signatures from the shared contract exactly as written; other people build against them.

## Build and check your work
Compile after every change. List simulators first if the name below doesn't exist:
```bash
xcrun simctl list devices available | grep -i iphone
xcodebuild -project DejaView/DejaView.xcodeproj -scheme DejaView \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -30
```
Run tests (if any):
```bash
xcodebuild -project DejaView/DejaView.xcodeproj -scheme DejaView \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test 2>&1 | tail -30
```
Foundation Models only answers on an Apple Intelligence device or a simulator on a Mac with Apple Intelligence on. Real model behaviour is checked by the human on the iPhone. After each step, tell the human in one or two lines how to test it.

## Git
- Work on your person's branch: `a-capture`, `b-understand` or `c-find`. Never commit to `main` directly.
- Commit small, with a prefix: `A: link fetcher reads og:description`.
- Stage only your own files. If `project.pbxproj` shows as changed and you didn't intend a settings change, don't stage it.
- Pull `main` into your branch at least every hour, and before merging.

## Today's clock
| Time | Goal |
|---|---|
| 11:00–11:20 | Stubs with the exact public signatures, pushed |
| 11:20–12:30 | Sprint 1: paste link → analyzed → found by asking |
| 12:30 | Safe to fail; merge; tag `safe-1230` |
| 13:30–14:15 | Sprint 2 items; drop anything not working at 14:15 |
| 14:30 | Readiness; demo request works three times in a row |
| 15:00 | Feature freeze; tag `demo-ready` |

When the human says it's past freeze, only fix bugs.
