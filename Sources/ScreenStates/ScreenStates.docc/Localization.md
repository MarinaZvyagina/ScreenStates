# Localization

How the default placeholders' built-in text is localized, how to add a language, and how to show different text instead without touching ScreenStates itself.

## Overview

The default Empty/Loading/Error placeholders' text — "Nothing Here," "Loading," "Retry," "Something Went Wrong," "Connection Issue" — comes from a String Catalog, `Resources/Localizable.xcstrings`, resolved from ScreenStates' own bundle (`Bundle.module`) rather than your app's. That's deliberate: a custom title your app passes in (see below) is never run back through localization, and a language you add to *your own* app's catalog has no effect on these five strings — they only ever resolve against ScreenStates' bundle. English, Spanish, French, and Russian are built in today.

## Adding a language to ScreenStates

This is a change to the package itself, not something a consuming app can do on its own — it needs a PR. Open `Resources/Localizable.xcstrings` and add a `localizations` entry for the new language code under each of the five string keys:

```json
"Retry" : {
  "comment" : "Title of the button that retries loading after an error.",
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Retry" } },
    "de" : { "stringUnit" : { "state" : "translated", "value" : "Wiederholen" } }
  }
}
```

Every one of the five keys needs an entry for every language — a string present in English but missing a translation elsewhere fails CI (see below). `ScreenStatesStrings.swift`'s doc comments list all five keys and their English text if you're starting from scratch.

## Overriding text per-app

You don't need a new language, or a PR, to show different text than the built-in default — two options, depending on how much you want to replace:

- `ScreenStateDefaultEmptyView(title:)` takes a `title` directly, bypassing `Localizable.xcstrings` entirely for that one string. Pass your own localized string (from your own app's String Catalog, `NSLocalizedString`, whatever) instead of the default:

  ```swift
  ScreenStateDefaultEmptyView(title: String(localized: "No Results"))
  ```

  `ScreenStateDefaultErrorView` has no equivalent for its title or Retry button text today — only the error's own message is customizable, via ``ScreenStateDisplayableError``.

- For anything else — the Error placeholder's title, the Retry button's text, or any text at all in a shape the built-in views don't expose a parameter for — pass a fully custom placeholder instead of the default one, via ``ScreenStateView``'s `empty`/`loading`/`error` builder closures (see <doc:GettingStartedWithSwiftUI>/<doc:GettingStartedWithUIKit>) or ``ScreenStateViewController``'s equivalent. A custom placeholder can still reuse ``ScreenState/accessibilityAnnouncement`` so VoiceOver announces transitions with the same wording your custom text uses, instead of the default's.

## See Also

- <doc:GettingStartedWithSwiftUI>
- <doc:GettingStartedWithUIKit>
- <doc:Accessibility>
