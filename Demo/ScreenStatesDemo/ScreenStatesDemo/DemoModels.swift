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
}

enum DemoError: LocalizedError {
    case network

    var errorDescription: String? {
        "Couldn't reach the server. Check your connection and try again."
    }
}
