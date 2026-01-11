//
//  SignupViewModel.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import Foundation
import Combine
import SwiftUI
import Network

@MainActor
final class SignupViewModel: ObservableObject {

    @Published var userType: UserType? = nil
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var countryCode: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var hasAttemptedSubmit: Bool = false

    @Published var shouldShowResultAlert: Bool = false
    @Published var resultAlertTitle: String = ""
    @Published var resultAlertMessage: String = ""

    @Published var isLoading: Bool = false

    var userTypeError: String? {
        guard hasAttemptedSubmit else { return nil }
        return userType == nil ? "Please select a user type." : nil
    }

    var firstNameError: String? {
        guard hasAttemptedSubmit else { return nil }
        return firstName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .validatePersonName(fieldLabel: "First name")
    }

    var lastNameError: String? {
        guard hasAttemptedSubmit else { return nil }
        return lastName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .validatePersonName(fieldLabel: "Last name")
    }

    var usernameError: String? {
        guard hasAttemptedSubmit else { return nil }
        return username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .validateUsername()
    }

    var emailError: String? {
        guard hasAttemptedSubmit else { return nil }
        return email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .validateEmail()
    }

    var countryError: String? {
        guard hasAttemptedSubmit else { return nil }
        return countryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Please select a country."
            : nil
    }

    var passwordErrors: [String] {
        guard hasAttemptedSubmit else { return [] }
        return password.validatePassword
    }

    var confirmPasswordError: String? {
        guard hasAttemptedSubmit else { return nil }
        return password == confirmPassword ? nil : "Passwords do not match"
    }

    var joinedPasswordError: String? {
        let errors = passwordErrors
        guard !errors.isEmpty else { return nil }
        return errors.joined(separator: "  ")
    }

    // MARK: - Aggregate validation

    var allErrors: [String] {
        var errors: [String] = [userTypeError, firstNameError, lastNameError, usernameError, emailError, countryError, confirmPasswordError].compactMap { $0 }
        errors.append(contentsOf: passwordErrors)
        return errors
    }

    var payload: SignupRequestPayload? {
        guard let userType else { return nil }
        return .init(
            userType: userType.json,
            firstName: firstName,
            lastName: lastName,
            username: username,
            email: email,
            country: Locale(identifier: "en_US_POSIX").localizedString(forRegionCode: countryCode) ?? countryCode,
            password: password
        )
    }

    func submitTapped() {
        hasAttemptedSubmit = true
        guard allErrors.isEmpty, let payload,
              let request = try? URLRequest.signUp(payload: payload) else {
            isLoading = false
            return
        }
        isLoading = true
        ConnectivityMonitor.shared.updateOnlineStatus()
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let responseText = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
            Task { @MainActor [weak self] in
                guard let self else { return }
                isLoading = false

                if let error {
                    resultAlertTitle = "Network Error"
                    resultAlertMessage = error.localizedDescription
                    shouldShowResultAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    resultAlertTitle = "Unexpected Response"
                    resultAlertMessage = "No HTTP response received."
                    shouldShowResultAlert = true
                    return
                }

                let isSuccess = (200..<300).contains(httpResponse.statusCode)
                resultAlertTitle = isSuccess ? "Success" : "Signup Failed"
                if isSuccess {
                    resultAlertMessage = "Signup request accepted. Check your email to verify your account."
                } else {
                    resultAlertMessage = responseText.isEmpty ? "Server returned status code \(httpResponse.statusCode)." : responseText
                }
                shouldShowResultAlert = true
            }
        }.resume()
    }
}

struct SignupRequestPayload: Codable {
    let userType: String
    let firstName: String
    let lastName: String
    let username: String
    let email: String
    let country: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case userType = "user_type"
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case email
        case country
        case password
    }
}

extension URL {

    /// Signup endpoint, ends with a slash to match swagger, this produced 200.
    static var signup: URL = URL(string: "https://django-dev.aakscience.com/signup/")!
}



extension URLRequest {

    static func signUp(payload: SignupRequestPayload) throws -> URLRequest {
        var urlRequest: URLRequest = .init(url: .signup)
        let data = try JSONEncoder().encode(payload)
        urlRequest.httpBody = data
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return urlRequest
    }
}

