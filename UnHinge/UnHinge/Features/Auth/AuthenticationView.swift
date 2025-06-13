import SwiftUI
import AuthenticationServices // Import for Apple Sign-In Button

struct AuthenticationView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var isSignUp: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Sign Up" : "Sign In")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if isSignUp {
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                Task {
                    if isSignUp {
                        await viewModel.signUp(email: email, password: password, username: username)
                    } else {
                        await viewModel.signInWithEmail(email: email, password: password)
                    }
                }
            }) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isLoading)
            
            Button(action: {
                isSignUp.toggle()
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.footnote)
            }

            // Apple Sign In Button
            if !isSignUp { // Show Apple Sign In only on the Sign In screen
                SignInWithAppleButton(
                    onRequest: { request in
                        // You can configure the request here if needed,
                        // e.g., request.requestedScopes = [.fullName, .email]
                        // Nonce will be handled by FirebaseService
                    },
                    onCompletion: { result in
                        Task {
                            await viewModel.signInWithApple()
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black) // or .white, .whiteOutline
                .frame(height: 50)
                .cornerRadius(10)
                .padding(.top, 10)
            }
        }
        .padding()
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        )
    }
}

#Preview {
    AuthenticationView().environmentObject(AuthenticationViewModel())
} 