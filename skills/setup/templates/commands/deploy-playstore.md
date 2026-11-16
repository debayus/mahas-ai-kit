---
description: Build and upload the Android app to Google Play (confirm build number → signed AAB → upload). Publishes a release.
argument-hint: "[track] [version+build]"
allowed-tools: Task, Bash, Read, Edit, AskUserQuestion
---

Deploy **{{PROJECT_NAME}}** to Google Play. Invoking this command authorizes the upload to the chosen track.

Arguments: $ARGUMENTS

1. **Settle the build number before anything changes.** Read the current version from `{{VERSION_FILE}}`. If the arguments name an explicit version+build, use it. Otherwise ask with AskUserQuestion: show the current value and the proposed bump (build + 1), and let the user accept, keep the current number, or enter another. Do not edit `{{VERSION_FILE}}` before the user answers.
2. **Delegate** the whole deploy to the `playstore-deployer` agent, passing the track (default `internal`) and the confirmed explicit version+build.
3. **If the agent stops on a blocker** (missing fastlane, service account key, keystore, or a taken version code), relay its setup steps verbatim and ask how to proceed. Do not work around a missing credential.
4. **Report** in the user's language: version, track, release status, the manual next steps in Play Console, and that `{{VERSION_FILE}}` is changed and uncommitted.

`production` uploads as a draft; the user rolls it out in Play Console.
