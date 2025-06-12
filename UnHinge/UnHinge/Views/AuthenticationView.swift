import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Title
                Image(systemName: "theatermasks.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.red)
                
                Text("UnHinge")
                    .font(.largeTitle)
                    .bold()
                
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                // Form Fields
                VStack(spacing: 15) {
                    if isSignUp {
                        AuthTextField(
                            placeholder: "Username",
                            systemImage: "person",
                            text: $username
                        )
                    }
                    
                    AuthTextField(
                        placeholder: "Email",
                        systemImage: "envelope",
                        text: $email
                    )
                    
                    AuthTextField(
                        placeholder: "Password",
                        systemImage: "lock",
                        text: $password,
                        isSecure: true
                    )
                }
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Sign In/Up Button
                Button {
                    Task {
                        if isSignUp {
                            await viewModel.signUp(
                                email: email,
                                password: password,
                                username: username
                            )
                        } else {
                            await viewModel.signInWithEmail(
                                email: email,
                                password: password
                            )
                        }
                    }
                } label: {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(viewModel.isLoading)
                
                // Toggle Sign In/Up
                Button {
                    withAnimation {
                        isSignUp.toggle()
                    }
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.red)
                }
                
                // Apple Sign In Button
                Button {
                    // TODO: Implement Apple Sign In
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
}

#Preview {
    AuthenticationView()
} 