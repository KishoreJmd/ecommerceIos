import Foundation

struct Product: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var price: Double
    var description: String
    var imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case price
        case description
        case imageUrl
    }
} 
