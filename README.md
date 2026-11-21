# Déjà View

> You've seen it before. Now you can find it again.

An iPhone app that saves social media posts and uses on-device Apple Intelligence to summarize, categorize and find them again. Apple Academy Jakarta capstone, Track C.

## Requirements
- Xcode 27, iOS 27
- An Apple Intelligence device (iPhone 15 Pro or later) with Apple Intelligence on and the device language set to English, or the Simulator on a Mac with Apple Intelligence on.
- Translate app: Indonesian and English downloaded (used to translate Indonesian captions on-device).

## Run it
1. Open `DejaView/DejaView.xcodeproj`.
2. Both targets (`DejaView`, `DejaViewShare`) → Signing & Capabilities → our shared team.
3. Choose the iPhone and press ⌘R.

## Repo layout
```
deja-view/
  CLAUDE.md                 instructions Claude Code loads automatically
  .claude/commands/         /person-a, /person-b, /person-c, /checkpoint (installed from setup/claude-commands)
  setup/claude-commands/    source of the slash commands
  docs/                     SPEC-A-Capture.md, SPEC-B-Understand.md, SPEC-C-Find.md (build from these),
                            SPEC.md, DESIGN.md, PROMPTS.md (background)
  Reference/                course sample WorkspaceAssistant-Lite (read only, not in any target)
  DejaView/                 Xcode project folder (created by A)
    DejaView.xcodeproj
    DejaView/               app: DejaViewApp.swift, Shared/, Services/, Agent/, Views/
    DejaViewShare/          share extension
```

## Building with Claude Code
First time only (A, before the first commit): `mkdir -p .claude/commands && cp setup/claude-commands/*.md .claude/commands/`

Open Terminal in `deja-view`, switch to your branch, run `claude`, then type your command:
| Person | Command |
|---|---|
| A · Capture | `/person-a` |
| B · Understand | `/person-b` |
| C · Find | `/person-c` |
At 12:30 and 14:30 run `/checkpoint` before merging.

## Team workflow (please follow, it keeps us from colliding)
**Ownership:** each person edits only the files listed in their spec (`docs/SPEC-A/B/C-*.md`). Need a change in someone else's file? Ask them.

**Branches:** `main` always builds. Work on your own branch:
| Person | Branch |
|---|---|
| A · Capture | `a-capture` |
| B · Understand | `b-understand` |
| C · Find | `c-find` |

**Xcode project file:** only A changes project settings (targets, capabilities, build settings, Info.plist keys). Folders sync with disk, so creating a new `.swift` file in your folder doesn't change `project.pbxproj`. If `git status` shows `project.pbxproj` changed and you didn't mean to change settings, don't commit it (`git restore DejaView.xcodeproj/project.pbxproj`).

**Daily rhythm**
```bash
git switch your-branch
git pull origin main          # at least every hour
# work, build, test
git add <your files>
git commit -m "B: processor handles empty captions"
git push
```

**Merging (at 11:20, 12:30 and 14:30, more often if you like)**
1. Pull `main` into your branch, build, fix anything broken.
2. Open a pull request into `main` and merge it. Order: A → B → C.
3. The integrator (B) pulls `main` and runs it on the iPhone. A broken `main` is fixed before anything else.

**Safe points**
```bash
git tag safe-1230 && git push --tags     # before lunch
git tag demo-ready && git push --tags    # at 15:00 freeze
git checkout demo-ready                  # emergency: back to the last working version
```

**Never commit:** `xcuserdata/`, `DerivedData/`, `.DS_Store`, `Local.xcconfig`, screen recordings. `.gitignore` handles these.
