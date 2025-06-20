//
//  SearchViewModel.swift
//  SmartPark
//
//  Created by Henry Westphal on 5/27/25.
//

import Foundation
import MapKit
import Combine

class SearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private var completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ query: String) {
        searchQuery = query
        completer.queryFragment = query
    }

    func completer(_ completer: MKLocalSearchCompleter, didUpdateResults results: [MKLocalSearchCompletion]) {
        print("Got \(results.count) autocomplete suggestions:")
        results.forEach { print("- \($0.title), \($0.subtitle)") }
        suggestions = results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Autocomplete error: \(error.localizedDescription)")
    }
}
