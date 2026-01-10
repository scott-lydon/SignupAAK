//
//  Locale.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import Foundation

typealias Country = (code: String, name: String)

extension Locale {

    static func filteredCountries(searchText: String) -> [Country] {
        if searchText.isEmpty { return countries }
        return countries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    static var countries: [Country] = {
        Region.isoRegions
            .compactMap { region in
                let code = region.identifier
                guard let name = Locale.current.localizedString(forRegionCode: code) else {
                    return nil
                }
                return (code, name)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()
}
