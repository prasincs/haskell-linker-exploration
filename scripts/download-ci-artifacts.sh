#!/bin/bash
set -e

# Script to download artifacts from latest successful CI run
# Requires: gh CLI (GitHub CLI)

echo "============================================"
echo "Downloading CI Artifacts"
echo "============================================"

# Check if gh is available
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI not found. Install from https://cli.github.com/"
    exit 1
fi

# Get the latest successful workflow run
echo "Finding latest successful workflow run..."
RUN_ID=$(gh run list --workflow=ci.yml --status=success --limit=1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo "No successful workflow runs found"
    exit 1
fi

echo "Latest successful run: $RUN_ID"
echo ""

# Create artifacts directory
mkdir -p ci-artifacts
cd ci-artifacts

# Download all artifacts
echo "Downloading artifacts..."
gh run download "$RUN_ID"

echo ""
echo "============================================"
echo "Downloaded artifacts:"
ls -lh
echo "============================================"
