# OpenAlex Flutter Architecture

This document is the source of truth for contributors and AI coding agents.
Read it before moving files, adding a feature, or changing dependencies.

## Chosen architecture

The application uses a **layer-first MVVM structure**. Do not create a parallel
`features/`, `data/`, or `core/` tree unless the whole project is intentionally
migrated in one reviewed change. A half layer-first / half feature-first layout
makes ownership and imports ambiguous.

```text
lib/
├── app/          # Application-wide composition and dependency registration
├── mappers/      # Mapping between external/domain models
├── models/       # Immutable domain/data models, grouped by domain
├── routes/       # Route names, arguments, and route factory
├── screens/      # Route-level UI, grouped by domain
├── services/     # OpenAlex, persistence, export, and external integrations
├── utils/        # Small stateless helpers and stable application keys
├── viewmodels/   # ChangeNotifier state and presentation orchestration
├── widgets/      # Reusable UI, grouped by domain
└── main.dart     # Bootstrap only
```

Tests mirror the production concepts under `test/`.

## Dependency direction

```text
screens/widgets → viewmodels → services → external APIs/storage
       │              │           │
       └──────────────┴──────────→ models
```

- Models must not import screens, widgets, viewmodels, or services.
- Services must not depend on Flutter UI or a `BuildContext`.
- ViewModels own loading/error/cache state and call services.
- Screens bind ViewModels to route-level UI.
- Widgets receive data and callbacks; they do not start dashboard API calls.
- `app/app_providers.dart` is the single dependency-registration boundary.
- `routes/app_router.dart` is the single route-construction boundary.

## Folder and naming rules

- Use `snake_case.dart` and spell names correctly.
- Service files end in `_service.dart`.
- ViewModel files end in `_view_model.dart`.
- Route-level widgets end in `_screen.dart`.
- Put domain-specific reusable widgets in `widgets/<domain>/`.
- Do not add empty placeholder directories.
- Do not create duplicate classes with the same responsibility in different
  folders. Prefer migrating callers and deleting the legacy implementation.
- Prefer package imports across layers and consistent relative imports within a
  small local group. Never import a deleted legacy path.

## Keyword feature rules

- `KeywordDashboardViewModel` owns dashboard state and cache behavior.
- The dashboard loads lazily when the Keywords tab is selected.
- Widget construction and rebuilds must not trigger OpenAlex requests.
- Returning to the Keywords tab reuses loaded data.
- Refresh and Try Again are explicit network actions.
- Trend ranges must be passed to OpenAlex and normalized to one point per year.
- Top-N controls are UI-only and stay bounded to 5, 10, 15, or 20.

## Adding a feature

1. Add or reuse models under `models/<domain>/`.
2. Put network/storage logic in a service.
3. Register the service and ViewModel in `app/app_providers.dart`.
4. Put state transitions and error handling in a ViewModel.
5. Add route-level UI under `screens/<domain>/`.
6. Extract reusable pieces to `widgets/<domain>/`.
7. Register navigation in `routes/`.
8. Add service, ViewModel, and widget tests as appropriate.
9. Run `flutter analyze` and `flutter test`.

## Prompt handoff template

Use this context when asking another developer or AI agent to continue work:

```text
Read ARCHITECTURE.md before editing.
This project uses layer-first MVVM; do not introduce a parallel feature-first
tree. Preserve the dependency direction and existing business logic.

Task: <describe the requested outcome>
In scope: <files/features allowed to change>
Out of scope: <business logic or integrations that must not change>
Acceptance criteria:
- <criterion 1>
- <criterion 2>

Before finishing:
- remove stale imports and conflict markers
- run dart format on changed Dart files
- run flutter analyze
- run relevant tests, then flutter test when practical
- report files changed and any remaining warnings
```

## Refactor safety checklist

- Check `git status` first; preserve unrelated work.
- Search all imports before renaming or deleting a file.
- Resolve every merge marker (`<<<<<<<`, `=======`, `>>>>>>>`).
- Avoid changing API queries, ranking formulas, or Firebase behavior during a
  structure-only refactor.
- Do not silently stage or commit unrelated files.
