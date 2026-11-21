Run a checkpoint for Déjà View (use at 12:30 and 14:30, or before merging).

1. Read `CLAUDE.md` and the person spec for this session (ask which person if unknown).
2. `git status` and `git diff --stat main...HEAD`: list changed files and flag any that this person doesn't own, and any `.xcodeproj` changes.
3. Build with the `xcodebuild` command in `CLAUDE.md` and report errors.
4. Go through the spec's "Done when" list: mark each item done, not done, or needs the human to test on the iPhone.
5. Tell me what to finish, what to drop (per the spec's stop rules), and whether the branch is ready to merge into `main`.

$ARGUMENTS
