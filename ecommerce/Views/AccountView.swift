import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct AccountView: View {
    @State private var showEditProfile = false
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = Auth.auth().currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(userName.isEmpty ? (user.email ?? "") : userName)
                                .font(.headline)
                            if !userName.isEmpty {
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Button(action: { showEditProfile = true }) {
                                Text("Edit Profile")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    NavigationLink(destination: OrdersView()) {
                        HStack {
                            Image(systemName: "bag.fill")
                                .foregroundColor(.blue)
                            Text("My Orders")
                        }
                    }
                }
                
                Section {
                    Button(action: logout) {
                        HStack {
                            Text("Logout")
                            Spacer()
                            Image(systemName: "arrow.right.square.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(userName: userName, onSave: { newName in
                    updateProfile(name: newName)
                })
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                userName = userData["name"] as? String ?? ""
            }
        }
    }
    
    private func updateProfile(name: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId)
        
        ref.updateChildValues(["name": name]) { error, _ in
            if let error = error {
                alertMessage = "Failed to update profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                userName = name
                alertMessage = "Profile updated successfully!"
                showAlert = true
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: LoginView())
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var email: String
    @State private var password: String = ""
    @State private var showReauthDialog = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    let onSave: (String) -> Void
    
    init(userName: String, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: userName)
        _email = State(initialValue: Auth.auth().currentUser?.email ?? "")
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                         !email.contains("@") || 
                         email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $showReauthDialog) {
                ReauthenticationView(email: email, onReauthSuccess: updateEmail)
            }
        }
    }
    
    private func saveChanges() {
        guard let user = Auth.auth().currentUser else { return }
        
        // If email has changed, require re-authentication
        if email != user.email {
            showReauthDialog = true
        } else {
            // If only name changed, update it directly
            onSave(name)
            dismiss()
        }
    }
    
    private func updateEmail() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.updateEmail(to: email) { error in
            if let error = error {
                alertMessage = "Failed to update email: \(error.localizedDescription)"
                showAlert = true
            } else {
                // Update name and email successful
                onSave(name)
                alertMessage = "Profile updated successfully!"
                showAlert = true
                dismiss()
            }
        }
    }
}

struct ReauthenticationView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    let onReauthSuccess: () -> Void
    
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Re-authenticate")) {
                    Text("Please enter your password to confirm changes")
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                    
                    SecureField("Current Password", text: $password)
                        .textContentType(.password)
                }
            }
            .navigationTitle("Confirm Changes")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Confirm") {
                    reauthenticate()
                }
                .disabled(password.isEmpty)
            )
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func reauthenticate() {
        guard let user = Auth.auth().currentUser else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: password)
        
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                alertMessage = "Authentication failed: \(error.localizedDescription)"
                showAlert = true
            } else {
                onReauthSuccess()
                dismiss()
            }
        }
    }
} 