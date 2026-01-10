//
//  CountryPickerView.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedCode: String
    @State var searchText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(Locale.filteredCountries(searchText: searchText), id: \.code) { country in
            Button {
                selectedCode = country.code
                dismiss()
            } label: {
                HStack {
                    Text(country.name)
                    Spacer()
                    if country.code == selectedCode {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Choose Country")
        .searchable(text: $searchText)
    }
}

#Preview {
    CountryPickerView(selectedCode: .constant("US"))
}
