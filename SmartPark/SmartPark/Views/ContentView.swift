//
//  ContentView.swift
//  SmartPark
//
//  Created by Henry Westphal on 5/23/25.
//

import SwiftUI
import MapKit

enum MapApp: String, CaseIterable, Identifiable {
    case apple = "Apple Maps"
    case google = "Google Maps"
    var id: String { self.rawValue }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchVM = SearchViewModel()

    @State private var selectedDate = Date()
    @State private var selectedLot: ParkingLot? = nil
    @State private var selectedMapApp: MapApp = .apple
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.2808, longitude: -83.743),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var searchLocationCoordinate: CLLocationCoordinate2D? = nil

    let parkingLots = ParkingLotDataService.loadStaticParkingLots()

    var nearbyLots: [ParkingLot] {
        let filterCenter = searchLocationCoordinate ?? region.center
        return parkingLots.filter {
            isNearby($0, center: filterCenter, maxDistanceInMeters: 1000)
        }
    }

    var body: some View {
        VStack {
            // MARK: - Search Bar
            VStack(alignment: .leading) {
                TextField("Where are you going?", text: $searchVM.searchQuery)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchVM.searchQuery) { _, newValue in
                        searchVM.updateQuery(newValue)
                    }

                // MARK: - Autocomplete Suggestions
                if !searchVM.suggestions.isEmpty {
                    List {
                        ForEach(searchVM.suggestions, id: \.self) { suggestion in
                            VStack(alignment: .leading) {
                                Text(suggestion.title).bold()
                                Text(suggestion.subtitle).font(.caption)
                            }
                            .onTapGesture {
                                let fullQuery = suggestion.title + " " + suggestion.subtitle
                                searchVM.searchQuery = fullQuery
                                searchLocation(named: fullQuery) { coordinate in
                                    if let coordinate = coordinate {
                                        searchLocationCoordinate = coordinate
                                        region = MKCoordinateRegion(
                                            center: coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                    }
                                }
                                searchVM.suggestions = []
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }

            // MARK: - Time Picker + Map App Picker
            DatePicker("Select Arrival Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .padding(.horizontal)

            Picker("Navigation App", selection: $selectedMapApp) {
                ForEach(MapApp.allCases) { app in
                    Text(app.rawValue).tag(app)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // MARK: - Map View
            Map(initialPosition: .region(region)) {
                // Parking lot markers
                ForEach(nearbyLots) { lot in
                    Annotation(lot.name, coordinate: lot.coordinate) {
                        VStack {
                            Image(systemName: "car.fill").foregroundColor(.blue)
                            Text(lot.name).font(.caption2)
                        }
                        .onTapGesture {
                            selectedLot = lot
                        }
                    }
                }

                // Searched location pin
                if let searchCoord = searchLocationCoordinate {
                    Annotation("Destination", coordinate: searchCoord) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }

                // User location pin
                if let userCoord = locationManager.currentLocation {
                    Annotation("You", coordinate: userCoord) {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                    }
                }
            }
            .frame(height: 400)

            // MARK: - Parking Lot List
            List(nearbyLots) { lot in
                VStack(alignment: .leading) {
                    Text(lot.name).bold()
                    Text(lot.address).font(.subheadline)
                    Text(String(format: "$%.2f/hr", lot.hourlyRate))
                }
            }
        }

        // MARK: - Lot Detail Modal
        .sheet(item: $selectedLot) { lot in
            VStack(alignment: .leading, spacing: 12) {
                Text(lot.name).font(.title2).bold()
                Text(lot.address)
                Text(String(format: "$%.2f/hr", lot.hourlyRate))
                Text(getDistanceString(to: lot))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Get Directions") {
                    let lat = lot.coordinate.latitude
                    let lon = lot.coordinate.longitude
                    let url: URL?

                    switch selectedMapApp {
                    case .apple:
                        url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)")
                    case .google:
                        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                            url = URL(string: "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving")
                        } else {
                            url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lon)")
                        }
                    }

                    if let url = url {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }

    // MARK: - Geocode Full Location Text
    func searchLocation(named query: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        MKLocalSearch(request: request).start { response, error in
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let coordinate = response?.mapItems.first?.placemark.coordinate,
               coordinate.latitude.isFinite,
               coordinate.longitude.isFinite {
                completion(coordinate)
            } else {
                print("Search failed to return valid coordinate")
                completion(nil)
            }
        }
    }

    // MARK: - Distance Helper
    func isNearby(_ lot: ParkingLot, center: CLLocationCoordinate2D, maxDistanceInMeters: Double = 1000) -> Bool {
        let lotLocation = CLLocation(latitude: lot.coordinate.latitude, longitude: lot.coordinate.longitude)
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return lotLocation.distance(from: centerLocation) <= maxDistanceInMeters
    }

    func getDistanceString(to lot: ParkingLot) -> String {
        guard let userLocation = locationManager.currentLocation else {
            return "Location unknown"
        }
        let from = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let to = CLLocation(latitude: lot.coordinate.latitude, longitude: lot.coordinate.longitude)
        let distance = from.distance(from: to)

        if distance > 1000 {
            return String(format: "%.1f km away", distance / 1000)
        } else {
            return String(format: "%.0f m away", distance)
        }
    }
}
