import UIKit

/// Where the monster picture is fetched from.
enum ImageSource: String, CaseIterable, Identifiable {
    case robohash
    case wikimedia

    var id: Self { self }

    var title: String {
        switch self {
        case .robohash: return "Robohash 怪物"
        case .wikimedia: return "維基共享資源"
        }
    }
}

struct Monster: Identifiable {
    let id = UUID()
    let name: String
    let species: String
    let emoji: String
    let power: String
    let weakness: String
    let fear: Int
    let image: UIImage
    let imageURL: URL
    let credit: String
}

/// The random parts of a monster that do not depend on the picture.
struct MonsterTraits {
    let name: String
    let species: String
    let emoji: String
    let power: String
    let weakness: String
    let fear: Int

    /// Seed used for Robohash so the same name always gives the same face.
    var seed: String { "\(name)-\(species)-\(Int.random(in: 0...99_999))" }
}

enum MonsterFactory {
    private static let species: [(String, String)] = [
        ("吸血鬼", "🧛"), ("狼人", "🐺"), ("骷髏", "💀"), ("幽靈", "👻"),
        ("木乃伊", "🧟"), ("巫婆", "🧙"), ("南瓜怪", "🎃"), ("蝙蝠王", "🦇"),
        ("蜘蛛精", "🕷️"), ("黑貓妖", "🐈‍⬛"), ("觸手怪", "🐙"), ("小惡魔", "😈"),
    ]
    private static let prefixes = [
        "午夜", "幽暗的", "腐朽的", "尖叫的", "迷霧", "血月", "墓園", "嘎吱作響的",
        "黏糊糊的", "不眠的", "地下室的", "倒立的", "愛吃糖的", "害羞的",
    ]
    private static let givenNames = [
        "阿嚕", "咕嚕", "噗噗", "嘎嘎", "嗚嗚", "啾啾", "咚咚", "嘶嘶", "喵嗚", "咯咯",
    ]
    private static let powers = [
        "一眨眼就把糖果變成蟲子", "在鏡子裡偷偷做鬼臉", "讓燈泡一閃一閃",
        "用尖叫震碎玻璃杯", "穿牆偷吃冰箱的布丁", "把影子借走不還",
        "召喚一千隻蝙蝠", "讓南瓜燈自己笑出聲", "在午夜敲三下門",
        "用蜘蛛絲織出隱形斗篷",
    ]
    private static let weaknesses = [
        "大蒜", "陽光", "銀湯匙", "被搔癢", "聽到鬧鐘", "看到蔬菜",
        "溫暖的擁抱", "被叫全名", "沒電的手機", "一杯熱可可",
    ]

    static func makeTraits() -> MonsterTraits {
        let pick = species.randomElement()!
        return MonsterTraits(
            name: "\(prefixes.randomElement()!)\(givenNames.randomElement()!)",
            species: pick.0,
            emoji: pick.1,
            power: powers.randomElement()!,
            weakness: weaknesses.randomElement()!,
            fear: Int.random(in: 1...5)
        )
    }
}
