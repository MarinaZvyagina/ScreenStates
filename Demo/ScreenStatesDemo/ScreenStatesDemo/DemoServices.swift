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
