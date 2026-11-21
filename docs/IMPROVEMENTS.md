# Déjà View — Improvement round (14:05 → 15:00 freeze)

We have ~45 minutes of build time. Everything below is sized for that. **15:00 is still the freeze.** Anything not working at 14:50 gets reverted, not finished.

## Verdicts

| # | Improvement | Verdict | Time | Owner |
|---|---|---|---|---|
| 1 | Ask tab first, styled like the mockup's Search home | **Do** | 15 min | C |
| 2 | Better categorization | **Do, the cheap way:** keep the 8 categories internally (the tool needs them), add clear definitions to the instructions, and stop showing the category as the main label. Show tags instead. | 10 min | B (instructions) · C (UI) |
| 3 | `title` + `summaryDescription` (+ key points) | **Do. Biggest quality win.** | 20 min | A (model fields) · B (analyzer) · C (UI) |
| 4 | User refines a post's context with the agent | **Only if 3 is done by 14:35.** Otherwise next session. | 15 min | B |
| 5 | Camera + photo library | Library picker **already exists**. Camera: **do** (needs one Info.plist key). | 15 min | A |
| 6 | Search finds similar words, not only exact | **Do:** model adds related words to the tool's keywords + on-device word-embedding neighbours + search title/description. Skip sentence embeddings (reported iOS 27 device bug). | 20 min | A (takes over `SearchEngine.swift` for this round) |
| 7 | Delete the sample (mock) posts button | **Do** | 2 min | C |
| 8 | Remove the play button on video thumbnails | **Try for 10 min only.** The icon is probably baked into the preview image itself; using the page's `og:image` instead of LinkPresentation's image may avoid it. If not, leave it. | 10 min | A |
| 9 | Add note / attachment hidden behind "Add" | **Note: do.** Attachments: **not today** (new data model + storage + UI). | 10 min | C |
| 10 | User adds / removes categories | **Not today.** Custom categories break the fixed `@Generable` enum that guided generation and the tool rely on; doing it properly needs dynamic schemas. Today: users can still change a post's category, and edit tags if there's time. | — | — |
| 11 | Static timestamp instead of live counting | **Do** | 2 min | C |
| 12 | Full-screen screenshot viewer | **Do** | 10 min | A (new file) + C (one tap gesture) |
| Mockup | Library as list rows with source filter (All · Posts · Screenshots · Links), detail with AI Summary + Key Points | **Do the list + filter + detail sections.** Skip Collections/Profile tabs, grid/list toggle, notification bell, Find/Recall/Summarize chips, platform logos (trademarks; keep text labels). | in 1, 3 | C |

## Ownership changes for this round (announce in chat)
- **A** also owns `Services/SearchEngine.swift` (search relevance) and the new `Views/FullImageView.swift` and `Views/CameraPicker.swift`.
- **A** adds the new `SavedPost` fields **first** (by 14:12) and pushes; B and C pull.
- Everyone else keeps their files.

## Order
| Time | A | B | C |
|---|---|---|---|
| 14:05–14:12 | A0 new model fields → push | B1 analyzer (wait for A0 to build) | C1 Ask first + static time + remove samples |
| 14:12–14:35 | A1 search relevance | B1 + B2 processor/tool text | C2 Library list + filter |
| 14:35–14:50 | A2 camera · A3 full image · A4 thumbnail (10 min max) | B3 refine (only if B1–B2 done) | C3 detail: summary card, key points, hidden note |
| 14:50 | Merge A → B → C, build on iPhone | | |
| 14:50–15:00 | **Delete the app on the demo iPhone, reinstall, save 6–8 real posts while online** (store changed + samples removed) | | |
| 15:00 | Freeze, tag `demo-ready`, rehearse | | |

---

## Prompts

### A0 — new model fields (first, push by 14:12)
> In Shared/SavedPost.swift add stored properties with default values so SwiftData can migrate: `var title: String = ""`, `var summaryDescription: String = ""`, `var keyPoints: [String] = []`. Keep `summary` for compatibility. Add a computed `displayTitle: String` (title, else summary, else the first 60 characters of caption, else "Untitled post") and `sourceKind: SourceKind` where `enum SourceKind { case post, screenshot, link }` (screenshot if platform == .screenshot; link if platform == .web; otherwise post). Build and push.

### A1 — search relevance (Services/SearchEngine.swift, now A's)
> Improve SearchEngine so similar words match, not only exact prefixes:
> 1. Search fields with weights: tags 3, title 3, summaryDescription 2, keyPoints 2, summary 2, caption 1, ocrText 1, englishText 1, userNote 1.
> 2. Expand each keyword with up to 3 related words from NaturalLanguage's NLEmbedding.wordEmbedding(for: .english) using neighbors(for:maximumCount:) with distance below 1.0 (skip if the embedding is nil). Related-word matches score half (round down, minimum 1). Cache the embedding in a static.
> 3. Also match simple stems: a keyword matches a word if either starts with the other and the shorter one has at least 4 letters (so "design" matches "designer", "recipes" matches "recipe").
> 4. Reason text: say "related: 'interior' for 'room'" when a related word matched.
> 5. Raise the keyword cap from 5 to 8 (C's tool now sends related words too).
> Keep the public signatures unchanged. Add or update tests: "room" finds a post whose title says "living room"; "recipes" finds "recipe"; "cooking" finds a post tagged "food" or "recipe" if the embedding relates them (skip that assertion if the embedding is nil).

### A2 — camera
> Create Views/CameraPicker.swift: a UIViewControllerRepresentable wrapping UIImagePickerController with sourceType .camera, returning a UIImage. In AddLinkView add a "Take a photo" button (camera symbol) next to "Pick a screenshot", shown only when UIImagePickerController.isSourceTypeAvailable(.camera). Save it like a screenshot (platform .screenshot, downscaled JPEG, .pending, then process). Tell me the Info.plist key to add in Xcode (NSCameraUsageDescription, text: "Take a photo of something you want Déjà View to remember.").

### A3 — full-screen image
> Create Views/FullImageView.swift: a full-screen view showing the post's image with pinch to zoom and double-tap to zoom (ScrollView-based is fine), black background, a close button, and a share button (ShareLink). C will present it from the detail view with .fullScreenCover.

### A4 — thumbnail without play button (10 minutes max)
> In LinkFetcher, also read the og:image URL from the HTML and download that image (downscaled). Prefer the og:image over LinkPresentation's imageProvider image when both exist. Keep everything else the same. If it doesn't help, I'll revert.

### B1 — better analysis (Services/PostAnalyzer.swift)
> Change PostAnalysis to, in this order:
> ```swift
> @Guide(description: "A specific title of 3 to 7 words naming the topic, like a saved article title. Not generic, not a full sentence.")
> var title: String
> @Guide(description: "One or two sentences: what the post is and the main takeaway. For tutorials or tips, say what you can learn or do.")
> var summaryDescription: String
> @Guide(description: "Up to 4 short key points or steps from the post. Empty if the post has none.", .maximumCount(4))
> var keyPoints: [String]
> @Guide(description: "The single best category, using the definitions in the instructions.")
> var category: PostCategory
> @Guide(description: "Short lowercase English tags, including the topic and the type of post.", .count(4))
> var tags: [String]
> @Guide(description: "True if the text is too vague to tell what the post is about.")
> var needsReview: Bool
> ```
> Add category definitions to the instructions: "Categories: design = UI, graphic, interior and product design, creative inspiration. foodRecipes = recipes, cooking, food places. travel = places, trips, itineraries. tech = software, coding, gadgets, AI, game development. tipsLearning = tutorials, how-tos, productivity, career, fitness and life tips that aren't tech or food. shopping = products to buy, deals. entertainment = music, movies, memes, humour. other = anything else. If a post is a tutorial about a topic, choose the topic's category." Keep the POST START/END rule. Write all fields in English.

### B2 — processor and tool text
> In PostProcessor, fill title, summaryDescription, keyPoints and also set summary = summaryDescription (old screens keep working). Fallback: title = first 6 words of the text, summaryDescription = first 120 characters. In SearchSavedPostsTool's result sentence, describe each post as "<title>: <summaryDescription>" instead of the summary. Tell C when pushed. (SearchSavedPostsTool.swift is C's file: coordinate, or ask C to make this one-line change.)

### B3 — refine with the agent (only if B1–B2 are done by 14:35)
> Add `static func refine(post text: String, current: PostAnalysis, instruction: String) async throws -> PostAnalysis` to PostAnalyzer: a new session with the same model and instructions; the prompt contains the current title, description, key points, category and tags, the user's instruction between "USER REQUEST START/END", and the post text between POST START/END; it returns a full new PostAnalysis. Expose a helper on PostProcessor `refine(_ post: SavedPost, instruction: String) async -> String?` that applies the result and returns a user-facing error from ModelErrors on failure. C adds the UI: a "Refine with AI" button in detail that opens a sheet with a text field ("e.g. Focus on the ingredients") and example chips.

### C1 — Ask first, static time, no samples
> In RootView, make Ask the first tab and the default selection. Label it "Search" with symbol "magnifyingglass" (mockup). Remove the DEBUG "Add sample posts" button and its function from LibraryView. Everywhere a date shows, replace live relative text (Text(date, style: .relative)) with a static string: "Today", "Yesterday", or "Saved 2 weeks ago" via date.formatted(.relative(presentation: .named)) computed once.
> Restyle AskView's empty state like the mockup: app logo image (asset "AppLogo" if it exists, else the sparkle symbol), "Déjà View", the tagline, a large rounded search field "Ask or search your saved library…", and a "Try asking…" list of 4 rows with leading symbols: "Find the room design post I saved", "Show me my screenshots", "What were the key takeaways from that tutorial?", "Find the travel plan I saved last month". Results: an "AI Answer" card (sparkles symbol) with the streamed answer, then "Saved in your library (N)" with list rows.

### C2 — Library as a list with source filter
> Change LibraryView to a list (mockup): large title "Library", "+" button, a segmented-style filter row "All · Posts · Screenshots · Links" using post.sourceKind, and rows: 72×72 thumbnail (radius 12), displayTitle (.headline, 2 lines), "<platform> · <static date>" (.caption, secondary), and a "…" menu (Open original, Delete with confirmation). Ask results use the same row plus up to 3 tag chips. Remove the category chip from rows; keep categories only as a small chip in detail.
> Also in SearchSavedPostsTool.Arguments, change keywords to `@Guide(description: "Topic words from the request plus a few closely related words, e.g. room → interior, furniture, layout", .maximumCount(8))` and keep LibrarySearch's cleaning consistent with 8.

### C3 — detail like the mockup
> PostDetailView: hero image (tap → .fullScreenCover(FullImageView) for any post with an image), displayTitle in .title2 bold, "<platform> · Saved <static date>", an "AI Summary" card (sparkles symbol, summaryDescription), "Key Points" bullets (hide if empty), tag chips, category as a small menu chip, "Open original" button. Hide the note field: show an "Add note" button (plus symbol); tapping it reveals the note field (and shows the field automatically if a note already exists). Keep "What Déjà View read", Retry with AI and Delete. If B3 lands, add "Refine with AI" to the toolbar menu.

---

## Not today (say this if judges ask)
- **Custom categories:** the category is a `@Generable` enum, so the model can only pick valid values; user-defined categories need dynamic generation schemas. Next step.
- **Attachments:** needs a new data model and storage. Next step.
- **Collections / Profile tabs, platform logos, grid/list toggle:** design polish for later.
- **Sentence-embedding semantic search:** reported unreliable on iOS 27 devices; word embeddings + model-expanded keywords cover most of it today.
