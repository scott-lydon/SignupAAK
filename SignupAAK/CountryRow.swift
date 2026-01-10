//
//  CountryRow.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import SwiftUI

struct CountryRow: View {
    @Binding var countryCode: String

    var body: some View {
        NavigationLink {
            CountryPickerView(selectedCode: $countryCode)
        } label: {
            HStack {
                Text("Country")
                Spacer()
                Text(countryName)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var countryName: String {
        Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }
}

#Preview {
    CountryRow(countryCode: .constant("US"))
}
