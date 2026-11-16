---
description: Build and upload the iOS app to App Store Connect (confirm build number → archive → validate → upload). Publishes to Apple.
argument-hint: "[version+build]"
allowed-tools: Task, Bash, Read, Edit, AskUserQuestion
---

Deploy **{{PROJECT_NAME}}** to App Store Connect. Invoking this command authorizes the upload.

Arguments: $ARGUMENTS

1. **Settle the build number before anything changes.** Read the current version from `{{VERSION_FILE}}`. If the arguments name an explicit version+build, use it. Otherwise ask with AskUserQuestion: show the current value and the proposed bump (build + 1), and let the user accept, keep the current number, or enter another. Do not edit `{{VERSION_FILE}}` before the user answers.
2. **Delegate** the whole deploy to the `appstore-deployer` agent, passing the confirmed explicit version+build.
3. **If the agent stops on a blocker** (missing API key or Issuer ID, a signing or validation error, a build number Apple already has), relay it verbatim and ask how to proceed. Do not work around a missing credential.
4. **Report** in the user's language: version+build, the Delivery UUID, the manual next steps in App Store Connect (processing, Export Compliance, submit for review), and that `{{VERSION_FILE}}` is changed and uncommitted.
