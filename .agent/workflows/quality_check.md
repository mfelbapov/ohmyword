---
description: Runs code quality and safety checks
---

1. Run `mix format --check-formatted` to ensure code style compliance.
2. Run `mix compile --warnings-as-errors` to catch any compilation warnings.
3. Run `mix test` to ensure all tests pass.
4. (Optional) If you have `credo` or `dialyxir` installed, run `mix credo --strict` and `mix dialyzer`.
