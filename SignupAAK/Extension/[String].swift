//
//  [String].swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import Foundation

extension Array where Element == String {

    static func validate(
        email: String,
        password: String,
        confirmPassword: String
    ) -> [String] {
        var errors: [String] = []
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let emailError = trimmedEmail.validateEmail() {
            errors.append(emailError)
        }
        errors.append(contentsOf: password.validatePassword)
        if password != confirmPassword {
            errors.append("Password does not match confirmation password.")
        }
        return errors
    }
}
