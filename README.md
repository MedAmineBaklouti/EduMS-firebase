# EduMS

## Architecture overview

The application now follows a production-ready GetX structure where all
features live under the `lib/app` tree. The key directories are:

```
lib/
└── app/
    ├── app.dart                # Root GetMaterialApp widget
    ├── bindings/               # Global dependency bindings
    ├── core/                   # Cross-cutting services, middleware, widgets
    ├── data/                   # Data transfer objects and models
    ├── modules/                # Feature modules (views, controllers, services)
    ├── routes/                 # Centralized navigation definitions
    └── themes/                 # Theming and configuration helpers
```

This layout keeps shared infrastructure under `core` and `data`, while every
domain feature stays self-contained inside `modules`. The structure aligns with
GetX best practices and makes dependency management through bindings explicit.
