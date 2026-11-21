# DejaView project guidance

DejaView is a SwiftUI app. Its architecture references are the three *Architecting Apple Intelligence* interactive modules supplied with the project. Their labs, sample apps, and event activities illustrate the patterns below. DejaView's feature requirements determine where those patterns apply.

## Structure and model integration

- Keep features under `DejaView/` with separate Swift types for generated values, tools, observable feature state, and views. Views render state and send user actions to the feature model. Keep Foundation Models session setup, generation, and error handling in the model layer.
- Use Apple's on-device `SystemLanguageModel` and `LanguageModelSession` as the default for AI features. Evaluate privacy, connectivity, latency, cost, and required capabilities before selecting another model. Check model availability before generation and distinguish unsupported devices, disabled Apple Intelligence, and assets that are still preparing. Keep the manual workflow usable in those states.
- Use `@Generable` for structured output and `@Guide` or enums where the output has meaningful bounds. Validate generated values before applying them to app state. The capstone path calls for at least one generated type and one tool, each tied to a real DejaView workflow.

## Tools and sessions

- Give sessions only the tools needed for the current workflow. Use narrow, typed arguments and concise descriptions that disclose side effects. Have tool calls and manual controls use the same validated commands. Return the actual outcome, including missing or ambiguous matches, and ask for explicit confirmation before deleting, sending, paying, or publishing.
- Keep developer-authored instructions separate from user or imported text. Put external content in the prompt as clearly delimited data. Use the model's default guardrails and validate tool arguments in Swift before any side effect.
- Allow one active request per session. Start a fresh session for independent work and reuse one only when follow-up requests need its transcript. Read the model's context budget at runtime. Budget for instructions, schemas, tools, and output as well as prompts. If the window fills, reset or condense the session and offer a retry while accounting for any tool actions already completed.
- Show progress during generation. When streaming structured output, render the latest `PartiallyGenerated` snapshot and apply persistent changes only after successful completion and validation.

## Error handling and verification

- Map availability and typed Foundation Models errors to actionable UI states. Distinguish guardrail violations and refusals, unsupported language, context exhaustion, transient rate limits or timeouts, concurrent requests, and tool failures. Keep user input available for recovery and report side effects accurately.
- Verify the real feature on an Apple Intelligence-capable target as well as the unavailable-model path. Exercise normal generation, missing or ambiguous tool input, declined confirmations where applicable, and interrupted or overlong requests. Keep representative prompts for regression checks when the model or prompts change.
