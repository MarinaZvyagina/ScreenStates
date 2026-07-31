#!/bin/sh
# Regenerates the static DocC site published at
# https://marinazvyagina.github.io/ScreenStates/ from the doc comments and
# the ScreenStates.docc catalog under Sources/ScreenStates. Run from the
# repo root (or anywhere — it cd's there itself) after changing public API
# doc comments or the catalog, then commit the resulting docs/ diff.
#
# Uses `xcodebuild docbuild` targeting iOS rather than
# `swift package generate-documentation`: this package mixes SwiftUI and
# UIKit code behind `#if canImport(UIKit)`, and generating documentation by
# building for the host Mac (what the SwiftPM plugin does) silently drops
# every UIKit symbol, since UIKit isn't available on plain macOS.
set -eu

cd "$(dirname "$0")/.."

DERIVED_DATA=$(mktemp -d)
trap 'rm -rf "$DERIVED_DATA"' EXIT

xcodebuild docbuild \
    -scheme ScreenStates \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA"

ARCHIVE=$(find "$DERIVED_DATA" -name 'ScreenStates.doccarchive' -print -quit)

rm -rf docs
"$(xcrun --find docc)" process-archive transform-for-static-hosting \
    "$ARCHIVE" \
    --output-path docs \
    --hosting-base-path ScreenStates

touch docs/.nojekyll
