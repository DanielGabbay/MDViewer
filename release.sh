#!/bin/bash

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo ""
echo "  MDViewer Release Tool"
echo "  ────────────────────────────────"

# Show current version (latest tag)
CURRENT=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
echo "  Current version: $CURRENT"
echo ""

# Prompt for new version
read -rp "  New version (e.g. 1.0.1): " INPUT

# Normalize — strip leading 'v' if user typed it
VERSION="${INPUT#v}"

if [ -z "$VERSION" ]; then
    echo "  Aborted — no version entered."
    exit 1
fi

TAG="v$VERSION"

# Confirm
echo ""
echo "  Will create tag: $TAG and push to origin."
read -rp "  Confirm? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "  Aborted."
    exit 0
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo ""
    echo "  Warning: you have uncommitted changes."
    read -rp "  Commit them now with message 'Release $TAG'? [y/N]: " COMMIT_NOW
    if [[ "$COMMIT_NOW" == "y" || "$COMMIT_NOW" == "Y" ]]; then
        git add -A
        git commit -m "Release $TAG"
    else
        echo "  Aborted — commit or stash changes first."
        exit 1
    fi
fi

# Push latest commits
echo ""
echo "  Pushing master..."
git push origin master

# Create and push tag
echo "  Creating tag $TAG..."
git tag "$TAG"
git push origin "$TAG"

echo ""
echo "  Done. GitHub Actions will build and publish the release automatically."
echo "  Track progress: https://github.com/DanielGabbay/MDViewer/actions"
echo ""
