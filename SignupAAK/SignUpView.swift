//
//  ContentView.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import SwiftUI

struct SignupView: View {

    @StateObject var viewModel: SignupViewModel = .init()
    @EnvironmentObject private var connectivity: ConnectivityMonitor

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Form {
                    Section("Create account") {

                        UserTypeRow(selected: $viewModel.userType)
                            .fieldRowStyle()
                            .listRowSeparator(.hidden, edges: .top)

                        if let userTypeError = viewModel.userTypeError {
                            InlineErrorRow(userTypeError)
                        }

                        TextField("First Name", text: $viewModel.firstName)
                            .textInputAutocapitalization(.words)
                            .keyboardType(.default)
                            .textContentType(.givenName)
                            .fieldRowStyle()

                        if let firstNameError = viewModel.firstNameError {
                            InlineErrorRow(firstNameError)
                        }

                        TextField("Last Name", text: $viewModel.lastName)
                            .textInputAutocapitalization(.words)
                            .keyboardType(.default)
                            .textContentType(.familyName)
                            .fieldRowStyle()

                        if let lastNameError = viewModel.lastNameError {
                            InlineErrorRow(lastNameError)
                        }

                        TextField("Username", text: $viewModel.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .fieldRowStyle()

                        if let usernameError = viewModel.usernameError {
                            InlineErrorRow(usernameError)
                        }

                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .fieldRowStyle()

                        if let emailError = viewModel.emailError {
                            InlineErrorRow(emailError)
                        }

                        CountryRow(countryCode: $viewModel.countryCode)
                            .fieldRowStyle()

                        if let countryError = viewModel.countryError {
                            InlineErrorRow(countryError)
                        }

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .listRowSeparator(.visible, edges: .bottom)

                        let passwordErrors = viewModel.passwordErrors
                        if !passwordErrors.isEmpty {
                            InlineErrorRow(passwordErrors.joined(separator: "  "))
                        }

                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .fieldRowStyle(include: viewModel.confirmPasswordError != nil)

                        if let confirmPasswordError = viewModel.confirmPasswordError {
                            InlineErrorRow(confirmPasswordError)
                        }
                    }

                    Section {
                        Button {
                            viewModel.hasAttemptedSubmit = true
                            let validationErrors: [String] = viewModel.allErrors
                            if validationErrors.isEmpty {
                                viewModel.submitTapped()
                            }
                        } label: {
                            Text("Create Account")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
                .navigationTitle("Sign Up")
                .disabled(viewModel.isLoading)
                if viewModel.isLoading {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()
                        .zIndex(3)

                    VStack {
                        Spacer()

                        ProgressView("Creating account…")
                            .padding(20)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(radius: 12)

                        Spacer()
                    }
                }
            }
        }
        .alert(viewModel.resultAlertTitle, isPresented: $viewModel.shouldShowResultAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.resultAlertMessage)
        }
    }
}


#Preview {
    SignupView()
}

