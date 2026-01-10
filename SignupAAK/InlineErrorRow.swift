//
//  InlineErrorRow.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import SwiftUI

struct InlineErrorRow: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Pull it closer to the field above and reduce the “table row” feel
            .fixedSize(horizontal: false, vertical: true)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            // Hide separators for error rows so they don’t create extra “underlines”
            .listRowSeparator(.hidden)
            .accessibilityLabel("Error: \(message)")
    }
}
