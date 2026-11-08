import Foundation

/// Simulates a flaky backend: each call takes the "screen" through a
/// different state (empty, populated, failed, populated with different
/// data) so the four `ScreenState` cases are all visible without a real
/// network call.
actor ReyFactsService {
    private var callCount = 0

    func fetchFacts() async throws -> [CharacterFact] {
        callCount += 1
        try await Task.sleep(for: .milliseconds(700))
        switch callCount % 4 {
        case 1: return []
        case 2: return CharacterFact.reySamples
        case 3: throw DemoError.network
        default: return Array(CharacterFact.reySamples.prefix(2))
        }
    }
}

actor KyloRenFactsService {
    private var callCount = 0

    func fetchFacts() async throws -> [CharacterFact] {
        callCount += 1
        try await Task.sleep(for: .milliseconds(700))
        switch callCount % 4 {
        case 1: throw DemoError.network
        case 2: return []
        case 3: return CharacterFact.kyloRenSamples
        default: return Array(CharacterFact.kyloRenSamples.prefix(2))
        }
    }
}

/// Backs ``FinnScreen``: a real paginated backend, one page of
/// `CharacterFact.finnPages` per call, instead of ``ReyFactsService``'s
/// everything-at-once shape. `fetchNextPage()` returns `[]` once every
/// page has been served, the same "no more results" signal a real
/// paginated API would give. `fetchFirstPage()` also occasionally throws
/// `FinnServiceError.jammed` — a runnable example of the Error
/// Presentation article's `ScreenStateDisplayableError` recipe, giving
/// the default Error placeholder a Finn-flavored message distinct from
/// `localizedDescription` instead of `DemoError`'s generic one.
actor FinnFactsService {
    private var nextPageIndex = 0
    private var firstPageCallCount = 0

    func fetchFirstPage() async throws -> [CharacterFact] {
        firstPageCallCount += 1
        try await Task.sleep(for: .milliseconds(700))
        guard firstPageCallCount % 4 != 1 else {
            throw FinnServiceError.jammed
        }
        nextPageIndex = 1
        return CharacterFact.finnPages[0]
    }

    func fetchNextPage() async throws -> [CharacterFact] {
        try await Task.sleep(for: .milliseconds(700))
        guard nextPageIndex < CharacterFact.finnPages.count else { return [] }
        let page = CharacterFact.finnPages[nextPageIndex]
        nextPageIndex += 1
        return page
    }
}
