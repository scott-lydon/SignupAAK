//
//  String.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import Foundation

extension String {

    func validatePersonName(fieldLabel: String) -> String? {
        if isEmpty {
            return "\(fieldLabel) is required."
        }

        if unicodeScalars.contains(where: { !CharacterSet.allowedCharacters.contains($0) }) {
            return "\(fieldLabel) contains an invalid character."
        }

        if count < 2 {
            return "\(fieldLabel) is too short."
        }
        return nil
    }

    var validatePassword: [String] {
        var errors: [String] = []
        if count < 10 {
            errors.append("Password must be at least 10 characters.")
        }
        if rangeOfCharacter(from: .uppercaseLetters) == nil {
            errors.append("Password must include an uppercase letter.")
        }
        if rangeOfCharacter(from: .lowercaseLetters) == nil {
            errors.append("Password must include a lowercase letter.")
        }
        if rangeOfCharacter(from: .decimalDigits) == nil {
            errors.append("Password must include a number.")
        }
        if rangeOfCharacter(from: CharacterSet(charactersIn: .specialCharacters)) == nil {
            errors.append("Password must include a special character.")
        }
        return errors
    }

    static var specialCharacters: String {
        "!@#$%^&*()-_=+[]{};:'\",.<>/?\\|`~"
    }


    func validateEmail() -> String? {
        let trimmedEmail = trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            return "Email is required."
        }

        if trimmedEmail.contains(" ") {
            return "Email is not valid."
        }

        // Must contain exactly one at sign.
        let parts = trimmedEmail.split(separator: "@", omittingEmptySubsequences: false)
        if parts.count != 2 {
            return "Email is not valid."
        }

        let localPart = String(parts[0])
        let domainPart = String(parts[1])

        if localPart.isEmpty || domainPart.isEmpty {
            return "Email is not valid."
        }

        // Domain must contain at least one dot, not at start or end.
        if !domainPart.contains(".") {
            return "Email is not valid."
        }
        if domainPart.hasPrefix(".") || domainPart.hasSuffix(".") {
            return "Email is not valid."
        }

        // No consecutive dots in local or domain.
        if localPart.contains("..") || domainPart.contains("..") {
            return "Email is not valid."
        }

        // Minimal domain sanity: each label must be non-empty.
        let domainLabels = domainPart.split(separator: ".", omittingEmptySubsequences: false)
        if domainLabels.contains(where: { $0.isEmpty }) {
            return "Email is not valid."
        }

        return nil
    }

    func validateUsername() -> String? {
        let trimmedUsername = trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedUsername.isEmpty {
            return "Username is required."
        }

        if trimmedUsername.contains(" ") {
            return "Username cannot contain spaces."
        }

        if !(3...20).contains(trimmedUsername.count) {
            return "Username must be between 3 and 20 characters."
        }

        if trimmedUsername.first == "." || trimmedUsername.last == "." {
            return "Username cannot start or end with a period."
        }

        if trimmedUsername.contains("..") {
            return "Username cannot contain consecutive periods."
        }

        // Common safe set: letters, numbers, underscore, period.
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._"))
        if trimmedUsername.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return "Username contains an invalid character."
        }

        return nil
    }
}
