# EVC — Electric Vehicle Cab Platform (Dubai)

A green, all-electric ride-hailing platform. **Three Flutter apps on one shared
backend**, built as a Flutter **pub workspace** (monorepo).

See [APP_CONCEPT.md](APP_CONCEPT.md) for the product and [PLAN.md](PLAN.md) for
the phased roadmap.

## Layout

```
evc/                      # pub workspace root (this is NOT an app)
├── apps/
│   ├── rider/            # EVC Rider  — passenger app   -> dev.needforge.evcrider
│   ├── driver/           # EVC Driver — partner app     -> dev.needforge.evcdriver
│   └── admin/            # EVC Admin  — ops app         -> dev.needforge.evcadmin
└── packages/
    ├── core/             # models, Supabase client, auth, config, DI  (evc_core)
    ├── ui_kit/           # theme, widgets, brand          (evc_ui_kit)
    ├── maps/             # map + location abstraction      (evc_maps)
    └── realtime/         # trip-state / realtime client    (evc_realtime)
```

**Two kinds of "shared":** the apps share **code** at compile time (the
`packages/`, pulled in via path deps) and share **data** at runtime (one
Supabase backend — a `trips` row created by Rider is fulfilled by Driver and
monitored by Admin). Edit a shared package once and all three apps pick it up.

## Setup

```bash
flutter pub get          # run once at the repo root — resolves the whole workspace
```

One `flutter pub get` at the root resolves every app and package together (a
single root `pubspec.lock`).

## Building the three apps

There is **no app at the repo root** — each app is built from its own directory,
producing its own APK with its own application ID:

```bash
cd apps/rider  && flutter build apk   # -> dev.needforge.evcrider
cd apps/driver && flutter build apk   # -> dev.needforge.evcdriver
cd apps/admin  && flutter build apk   # -> dev.needforge.evcadmin
```

APKs land in `apps/<app>/build/app/outputs/flutter-apk/app-release.apk`.

Run one in dev: `cd apps/rider && flutter run`.

## Workspace scripts (melos)

Config lives under the `melos:` key in the root [pubspec.yaml](pubspec.yaml).

```bash
dart run melos run analyze     # analyze every package
dart run melos run test        # test every package
dart run melos run build:apk   # build release APKs for all three apps
```