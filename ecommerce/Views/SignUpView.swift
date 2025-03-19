import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isRegistered = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            VStack(spacing: 15) {
                TextField("Full Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 30)
            
            Button(action: signUp) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            .disabled(name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            
            Button(action: { dismiss() }) {
                Text("Already have an account? Login")
                    .foregroundColor(.orange)
            }
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .fullScreenCover(isPresented: $isRegistered) {
            LoginView()
        }
    }
    
    private func signUp() {
        if name.isEmpty {
            showError = true
            errorMessage = "Please enter your name"
            return
        }
        
        if password != confirmPassword {
            showError = true
            errorMessage = "Passwords do not match"
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                showError = true
                errorMessage = error.localizedDescription
            } else {
                if let uid = result?.user.uid {
                    let db = Database.database().reference()
                    let userData: [String: Any] = [
                        "role": "user",
                        "name": name,
                        "email": email,
                        "createdAt": ServerValue.timestamp()
                    ]
                    db.child("users").child(uid).setValue(userData)
                }
                isRegistered = true
            }
        }
    }
} 
