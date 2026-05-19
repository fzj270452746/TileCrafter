import Foundation

enum TC_Suit: String, CaseIterable, Codable {
    case bamboo
    case character
    case dot
    case honor
}

enum TC_HonorFace: String, CaseIterable, Codable {
    case eastWind
    case redCenter
    case greenFa
    case whiteBlank
}

struct TC_TileMotif: Hashable, Codable {
    let suit: TC_Suit
    let rank: Int
    let honor: TC_HonorFace?

    static func numbered(_ suit: TC_Suit, _ rank: Int) -> TC_TileMotif {
        TC_TileMotif(suit: suit, rank: rank, honor: nil)
    }

    static func honored(_ face: TC_HonorFace) -> TC_TileMotif {
        TC_TileMotif(suit: .honor, rank: 0, honor: face)
    }

    var isNumbered: Bool { honor == nil }

    var assetName: String {
        if let face = honor {
            switch face {
            case .eastWind:   return "TileCrafter-EastWind"
            case .redCenter:  return "TileCrafter-RedZhong"
            case .greenFa:    return "TileCrafter-GreenFa"
            case .whiteBlank: return "TileCrafter-WhiteBlank"
            }
        }
        switch suit {
        case .bamboo:    return "TileCrafter-Lines-\(rank)"
        case .character: return "TileCrafter-Million-\(rank)"
        case .dot:       return "TileCrafter-Bing-\(rank)"
        case .honor:     return "TileCrafter-WhiteBlank"
        }
    }

    var spokenLabel: String {
        if let face = honor {
            switch face {
            case .eastWind:   return "East"
            case .redCenter:  return "Red"
            case .greenFa:    return "Fa"
            case .whiteBlank: return "Blank"
            }
        }
        return "\(rank) of \(suit.rawValue)"
    }
}

enum TC_TilePower: Codable, Hashable {
    case plain
    case jokerRed
    case mirrorWhite
    case sweepEast
    case bombFa
    case frozenIce

    var isWild: Bool {
        switch self {
        case .jokerRed, .mirrorWhite: return true
        default: return false
        }
    }
}
