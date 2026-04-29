#!/usr/bin/env bash
# Sync the contents of docs/ to the GitHub Wiki.
#
# Prerequisites (one-time, manual):
#   1. Open https://github.com/pietro1704/swiftui-uikit-interview-prep/wiki
#   2. Click "Create the first page", paste anything, save.
#      (GitHub only initializes the wiki git remote after the first page exists.)
#
# Then run this script — it will mirror docs/ onto the wiki.

set -euo pipefail

REPO_SLUG="pietro1704/swiftui-uikit-interview-prep"
WIKI_URL="git@github.com:${REPO_SLUG}.wiki.git"
TMP=$(mktemp -d)
HERE=$(cd "$(dirname "$0")/.." && pwd)

echo "→ Cloning wiki into $TMP"
git clone "$WIKI_URL" "$TMP"

echo "→ Mirroring docs/ to wiki"
rm -f "$TMP"/*.md
cp "$HERE"/docs/*.md "$TMP"/

# Add a sidebar so navigation is easy on the wiki UI
cat > "$TMP/_Sidebar.md" <<'EOF'
### 📚 Docs

- 🏠 [Home](Home)
- ⚡️ [Senior Fast Track](Fast-Track-Senior)
- ❓ [Interview Questions](Interview-Questions)

### Cheat sheets

- 🧠 [SwiftUI](Cheat-Sheet-SwiftUI)
- 🛠 [UIKit](Cheat-Sheet-UIKit)
- ⚡️ [Concurrency](Cheat-Sheet-Concurrency)

### More

- 🏛 [Architecture](Architecture-Patterns)
- 🐛 [Common Pitfalls](Common-Pitfalls)

---

[← back to repo](https://github.com/pietro1704/swiftui-uikit-interview-prep)
EOF

cd "$TMP"
git add -A
if git diff --cached --quiet; then
    echo "→ Wiki already up to date."
else
    git commit -m "docs: sync from main repo docs/"
    git push origin master
    echo "✅ Wiki synced."
fi
