import SwiftUI

@MainActor
final class MonsterViewModel: ObservableObject {
    enum Phase {
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var monster: Monster?
    @Published private(set) var phase: Phase = .loading
    @Published private(set) var favorites: [Monster] = []
    @Published private(set) var summonCount = 0
    @Published var source: ImageSource = .robohash

    private let service = MonsterImageService()
    private var task: Task<Void, Never>?

    var isLoading: Bool {
        if case .loading = phase { return true }
        return false
    }

    var isFavorite: Bool {
        guard let monster else { return false }
        return favorites.contains { $0.id == monster.id }
    }

    func summon() {
        task?.cancel()
        phase = .loading
        let source = source
        task = Task {
            let traits = MonsterFactory.makeTraits()
            do {
                let fetched = try await service.fetch(from: source, seed: traits.seed)
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                    monster = Monster(
                        name: traits.name,
                        species: traits.species,
                        emoji: traits.emoji,
                        power: traits.power,
                        weakness: traits.weakness,
                        fear: traits.fear,
                        image: fetched.image,
                        imageURL: fetched.url,
                        credit: fetched.credit
                    )
                    summonCount += 1
                    phase = .loaded
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func toggleFavorite() {
        guard let monster else { return }
        withAnimation {
            if let index = favorites.firstIndex(where: { $0.id == monster.id }) {
                favorites.remove(at: index)
            } else {
                favorites.insert(monster, at: 0)
            }
        }
    }
}
