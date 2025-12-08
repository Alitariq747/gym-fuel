//
//  ProfileView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    @State private var errorMessage: String?
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.secondary)
                    Text(authManager.user?.email ?? "Anonymous")
                        .font(.headline)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(role: .destructive) {
                    handleSignOut()
                } label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading Profile")
                    } else if let error = viewModel.errorMessage {
                        VStack {
                            Text("Error")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                            Button ("Retry") {
                                viewModel.loadProfile()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else if let profile = viewModel.profile {
                        Form {
                            Section(header: Text("Account")) {
                                                       Text(profile.email)
                                                       Picker("Goal", selection: .constant(profile.goal)) {
                                                           Text("Cut").tag("cut")
                                                           Text("Recomp").tag("recomp")
                                                           Text("Lean bulk").tag("lean_bulk")
                                                       }
                                                       .disabled(true) 
                                                   }
                            Section(header: Text("Body")) {
                                                       HStack {
                                                           Text("Height (cm)")
                                                           Spacer()
                                                           Text(profile.heightCm != nil ? String(format: "%.0f", profile.heightCm!) : "-")
                                                               .foregroundColor(.secondary)
                                                       }
                                                       HStack {
                                                           Text("Weight (kg)")
                                                           Spacer()
                                                           Text(profile.weightKg != nil ? String(format: "%.1f", profile.weightKg!) : "-")
                                                               .foregroundColor(.secondary)
                                                       }
                                                   }
                            
                        }
                    } else {
                        Text("No profile loaded")
                    }
                }
            }
            .padding()
            .navigationTitle("Profile")
            .onAppear {
                if viewModel.profile == nil && !viewModel.isLoading {
                    viewModel.loadProfile()
                }
            }
            
        }
    }
    
    private func handleSignOut() {
        do {
            try FirebaseAuthManager.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ProfileView()
}
