# OfflineTaskTracker

A native iOS task and work tracker built with **SwiftUI, SwiftData, MVVM, and Swift Concurrency**. The app is designed around local-first task management: core task workflows use on-device persistence and do not require a network connection.

## Current functionality

- Overview dashboard with task counts
- Create, edit, complete, and delete tasks
- Priority levels: Low, Medium, High, Urgent
- Categories: Work, Personal, Learning
- Optional due dates and overdue indicators
- Search by task title and description
- Filter by status and category
- Local persistence with SwiftData

## Architecture

- **Views:** SwiftUI screens and reusable components
- **ViewModel:** `TaskViewModel` owns presentation state and task actions
- **Repository:** `TaskRepository` abstracts persistence; `SwiftDataTaskRepository` implements it
- **Model:** `TaskItem` is a SwiftData model

## Requirements

- Xcode with iOS 26 SDK
- iOS 26.0 deployment target
- Swift 6-compatible toolchain

## Run

1. Open `OfflineTaskTracker.xcodeproj`.
2. Select the `OfflineTaskTracker` scheme.
3. Choose an iOS 26 simulator.
4. Build and run.

## Offline behavior

Tasks are persisted locally using SwiftData. Creating, editing, completing, deleting, searching, and filtering tasks are local operations. No backend or account is required.

## Current project status

This is the initial application foundation. Automated tests, accessibility review, broader device validation, and additional polish should be completed before describing the app as fully production-ready.
