---
name: new-feature
description: Scaffolds a new feature following project guidelines
---

1. Read `docs/archive/ai_phoenix_rules.md` to ensure compliance with project standards.
2. Ask the user for the specific feature requirements if not already provided.
3. Create the necessary database migrations.
4. Generate the Context and Schema files.
5. Create LiveView files (Index, Show, Form) following the patterns in `docs/archive/ai_phoenix_rules.md`.
6. Make sure edit and new Liveviews use pattern of code sharing.
7. Ensure all new routes are added to `router.ex` within the appropriate scope.
8. Ensure comprehensive tests are written.
9. Run `mix precommit` to verify everything is correct.
