import Foundation

struct CharacterFact: Identifiable, Sendable {
    let id: UUID
    let icon: String
    let text: String

    init(id: UUID = UUID(), icon: String, text: String) {
        self.id = id
        self.icon = icon
        self.text = text
    }
}

extension CharacterFact {
    static let reySamples: [CharacterFact] = [
        CharacterFact(icon: "sun.max.fill", text: "Grew up scavenging starship wreckage on the desert world of Jakku."),
        CharacterFact(icon: "figure.walk.motion", text: "Trained in the ways of the Force by Luke Skywalker and Leia Organa."),
        CharacterFact(icon: "bolt.fill", text: "Builds and wields her own golden lightsaber."),
        CharacterFact(icon: "shield.fill", text: "Defeats Emperor Palpatine on Exegol, ending the Sith once and for all.")
    ]

    static let kyloRenSamples: [CharacterFact] = [
        CharacterFact(icon: "person.fill.questionmark", text: "Born Ben Solo, son of Han Solo and Leia Organa."),
        CharacterFact(icon: "flame.fill", text: "Once Luke Skywalker's apprentice, turned to the dark side by Snoke."),
        CharacterFact(icon: "bolt.fill", text: "Wields an unstable crossguard lightsaber of his own design."),
        CharacterFact(icon: "crown.fill", text: "Rises to become Supreme Leader of the First Order.")
    ]

    /// Three pages' worth of facts for ``FinnScreen``, fetched one page at
    /// a time via ``FinnFactsService/fetchNextPage()`` instead of all at
    /// once — see `loadNextPage(_:)`.
    static let finnPages: [[CharacterFact]] = [
        [
            CharacterFact(icon: "shield.lefthalf.filled", text: "Raised from infancy as First Order stormtrooper FN-2187."),
            CharacterFact(icon: "arrow.uturn.left", text: "Defects after his first combat mission on Jakku.")
        ],
        [
            CharacterFact(icon: "car.fill", text: "Escapes the First Order alongside Poe Dameron in a stolen TIE fighter."),
            CharacterFact(icon: "person.2.fill", text: "Becomes one of the Resistance's most capable fighters.")
        ],
        [
            CharacterFact(icon: "bolt.heart.fill", text: "Discovers he's Force-sensitive during the war's final days."),
            CharacterFact(icon: "flag.fill", text: "Helps lead the final charge against the First Order's fleet.")
        ]
    ]
}

enum DemoError: LocalizedError {
    case network

    var errorDescription: String? {
        "Couldn't reach the server. Check your connection and try again."
    }
}
