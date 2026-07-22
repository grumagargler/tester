# GitHub Wiki mirror

The GitHub Wiki is generated from the MkDocs sources in `docs/`. Do not edit
the generated Wiki directly because the next publication will overwrite those
changes.

To build and validate the Wiki locally:

```bash
python3 scripts/build_wiki.py --output /tmp/tester-wiki
```

The exporter:

- expands `mdx_include` fragments;
- converts MkDocs admonitions to block quotes;
- converts embedded YouTube players to ordinary links;
- rewrites page and image links for GitHub Wiki;
- copies documentation images into the Wiki repository;
- generates `Home.md`, `_Sidebar.md`, and `_Footer.md`;
- checks generated local links and image references.

The `Publish documentation to Wiki` GitHub Actions workflow runs after changes
to the documentation are pushed to `master`. It can also be started manually
from the Actions tab on the `master` branch.
