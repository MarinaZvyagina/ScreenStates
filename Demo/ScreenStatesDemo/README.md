# ScreenStates Demo

A runnable iOS app showing the library on two screens, built with two
different paradigms:

- **Articles** — SwiftUI, using `ScreenStateStore` + `ScreenStateView`.
- **Tasks** — UIKit, using `ScreenStateStore` + `ScreenStateContainerView`,
  wrapped for the tab bar with `UIViewControllerRepresentable`.

Both screens call a simulated, flaky `DemoArticleService` / `DemoTaskService`
through the library's real `loadCollection(_:)` API every couple of seconds,
so opening either tab cycles through **Loading → Empty → Data → Error →
Data** entirely on its own — no backend required. The Retry button on the
Error placeholder calls the exact same reload path.

## Running it

Open `ScreenStatesDemo.xcodeproj` in Xcode and run the `ScreenStatesDemo`
scheme on any iOS 17+ simulator or device. It depends on the `ScreenStates`
package one directory up via a local Swift Package reference — no external
dependencies to fetch.

## Regenerating the project

The `.xcodeproj` is checked in for convenience, but it's generated from
[`project.yml`](project.yml) with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen   # if you don't have it
cd Demo/ScreenStatesDemo
xcodegen generate
```
