//
//  FieldRowStyle.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import SwiftUI

extension View {
    func fieldRowStyle(include: Bool = true) -> some View {
        modifier(FieldRowStyle(include: include))
    }
}

private struct FieldRowStyle: ViewModifier {
    let include: Bool

    func body(content: Content) -> some View {
        if include {
            content
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.visible)
        } else {
            content
        }
    }
}
