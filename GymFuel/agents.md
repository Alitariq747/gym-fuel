# Codex Working Rules

## Scope
- Start with files explicitly named in the task.
- Read direct dependencies only when needed.
- Do not scan the entire repository unless explicitly asked.
- Do not modify unrelated files.
- Keep changes small and focused.
- Always explain code changes and additions

## Verification
- Do not run xcodebuild.
- Do not run tests.
- Do not open Simulator.
- Do not install packages or update dependencies.
- Do not clean the build folder.
- Do not change Xcode project settings, signing, entitlements, package versions, or build configuration unless explicitly asked.

## My workflow
- I will build and run the app manually in Xcode.
- I will test the Simulator manually.
- If there is a compiler error, I will provide the relevant error message.
- Do not attempt broad automatic retries after an error.

## Completion
After each task, report:
1. Files changed
2. What changed
3. Manual Xcode steps I should test
4. Any likely compile risks or remaining TODOs
