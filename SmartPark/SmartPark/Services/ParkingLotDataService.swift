//
//  ParkingLotDataService.swift
//  SmartPark
//
//  Created by Henry Westphal on 5/24/25.
//

import Foundation

class ParkingLotDataService {
    static func loadStaticParkingLots() -> [ParkingLot] {
        guard let url = Bundle.main.url(forResource: "static_parking_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lots = try? JSONDecoder().decode([ParkingLot].self, from: data) else {
            return []
        }
        return lots
    }
}
