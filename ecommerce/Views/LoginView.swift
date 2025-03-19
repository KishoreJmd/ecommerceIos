import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import UIKit

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var isAdmin = false
    @State private var showSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 35)
            
            Button(action: login) {
                Text("Login")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            
            Button(action: { showSignUp = true }) {
                Text("Don't have an account? Sign Up")
                    .foregroundColor(.orange)
            }
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
        }
        .onChange(of: isLoggedIn) { _, newValue in
            if newValue && !isAdmin {
                navigateToUserDashboard()
            }
        }
    }
    
    private func navigateToAdminDashboard() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: AdminDashboard())
        }
    }
    
    private func navigateToUserDashboard() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: UserDashboard())
        }
    }
    
    private func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                showError = true
                errorMessage = error.localizedDescription
            } else if let uid = result?.user.uid {
                let ref = Database.database().reference().child("users").child(uid)
                ref.observeSingleEvent(of: .value) { snapshot in
                    if let dict = snapshot.value as? [String: Any],
                       let role = dict["role"] as? String {
                        print("User role: \(role)") // Debug print
                        isAdmin = (role == "admin")
                        if isAdmin {
                            navigateToAdminDashboard()
                        } else {
                            isLoggedIn = true
                        }
                    } else {
                        // If no role is found, set as regular user
                        isAdmin = false
                        isLoggedIn = true
                    }
                } withCancel: { error in
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
} 
