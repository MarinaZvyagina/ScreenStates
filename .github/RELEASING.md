# Releasing

ScreenStates has no build step and no artifact to publish beyond the package itself — "releasing" just means tagging a commit so the [Swift Package Index](https://swiftpackageindex.com/MarinaZvyagina/ScreenStates) and anyone pinning a version in `Package.swift` pick it up.

## Versioning

Every notable change gets its own `CHANGELOG.md` entry with a bumped `major.minor.patch` version, as part of the same commit/PR that makes the change (see `CONTRIBUTING.md`). That happens far more often than an actual tagged release — most `CHANGELOG.md` versions never get their own tag.

## Cutting a release

Periodically, at a point worth marking (not necessarily every `CHANGELOG.md` bump):

1. Confirm `CHANGELOG.md`'s top entry is the version you're about to tag, and that `swift build`/`swift test` plus the iOS Simulator suite (see `CONTRIBUTING.md`) pass on `main`.
2. Tag the commit with an annotated tag, `vX.Y.Z` matching that top `CHANGELOG.md` entry:

   ```bash
   git tag -a vX.Y.Z -m "$(cat <<'EOF'
   ScreenStates X.Y.Z — <short summary>

   Highlights:
   - <what changed, one bullet per notable CHANGELOG.md entry since the last tag>

   No breaking changes; drop-in upgrade from <previous version>.
   EOF
   )"
   ```

   Match the style already in the tag history (`git tag -n99` to see prior messages) — a one-line summary, a `Highlights:` list pulled from the relevant `CHANGELOG.md` entries since the last tag, and a closing note on whether it's a breaking change.
3. Push the tag: `git push origin vX.Y.Z`.

That's the whole process — the Swift Package Index polls tags automatically, and there's no separate GitHub Release to publish (none of the existing tags have one; a tag alone is sufficient for SPI and for `Package.swift` version pins).
