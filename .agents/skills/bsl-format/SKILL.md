---
name: bsl-format
description: Format or reformat 1C:Enterprise BSL (.bsl) code to match my style. Use when asked to format BSL files or snippets in this repo, or to normalize indentation/spacing/keyword casing for BSL.
---

# BSL Format

## Overview
Apply the project BSL style to files or snippets while preserving behavior and content.

## Workflow
1. Identify the target style for the file.
   - Default to the project style in `references/style.md`.
   - If the file clearly follows the outlier pattern (see `references/style.md`), preserve its local style unless the user asks to normalize it.
2. Apply formatting rules: indentation, spacing, keyword casing, semicolons, wrapping, and blank lines.
3. Preserve semantics: do not change strings, query text, comments, or logic; only adjust formatting/casing.
4. Re-scan for consistency (tabs, parentheses spacing, keyword casing) and fix any drift.

## Reference
Read `references/style.md` before formatting to ensure the rules match this repository.
