//
//  UserTypePickerView.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/9/26.
//

import SwiftUI

struct UserTypePickerView: View {

    @Binding var selected: UserType?

    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            ForEach(UserType.allCases) { type in
                Button {
                    selected = type
                    dismiss()
                } label: {
                    HStack {
                        Text(type.title)
                        Spacer()
                        if selected == type {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Choose User Type")
    }
}
