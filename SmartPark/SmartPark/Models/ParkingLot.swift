//
//  ParkingLot.swift
//  SmartPark
//
//  Created by Henry Westphal on 5/24/25.
//

import Foundation
import CoreLocation

struct ParkingLot: Identifiable, Decodable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let hourlyRate: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, hourlyRate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        hourlyRate = try container.decode(Double.self, forKey: .hourlyRate)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
