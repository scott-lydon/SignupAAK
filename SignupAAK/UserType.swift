//
//  UserType.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import Foundation

enum UserType: String, CaseIterable, Identifiable {

    case researcher
    case investor
    case institutionStaff
    case serviceProvider
    case freelancer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .researcher:
            return "researcher"
        case .investor:
            return "investor"
        case .institutionStaff:
            return "institution staff"
        case .serviceProvider:
            return "service provider"
        case .freelancer:
            return "freelancer"
        }
    }

    var json: String {
        title.replacingOccurrences(of: " ", with: "_")
    }
}
