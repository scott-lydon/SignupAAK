//
//  UserTypeRow.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/9/26.
//

import SwiftUI

struct UserTypeRow: View {
    @Binding var selected: UserType?

    var body: some View {
        NavigationLink {
            UserTypePickerView(selected: $selected)
        } label: {
            HStack {
                Text("User Type")
                Spacer()
                Text(selected?.title ?? "Select")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .listRowSeparator(.hidden, edges: .top)
    }
}
