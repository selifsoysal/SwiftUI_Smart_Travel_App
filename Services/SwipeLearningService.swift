import Foundation

final class SwipeLearningService {

    private(set) var interestScores: [Interest: Int] = [:]

    init() {
        Interest.allCases.forEach { interestScores[$0] = 0 }
    }

    func like(item: SwipeItem) {
        update(tags: item.tags, value: 1)
    }

    func dislike(item: SwipeItem) {
        update(tags: item.tags, value: -1)
    }

    private func update(tags: [Interest], value: Int) {
        for tag in tags {
            interestScores[tag, default: 0] += value
        }
    }
}
