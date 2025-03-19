import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct User: Identifiable {
    let id: String
    var name: String
    var email: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
    }
}

struct UserManagementView: View {
    @Environment(\.dismiss) var dismiss
    @State private var users: [User] = []
    @State private var selectedUser: User?
    @State private var showEditUser = false
    @State private var showDeleteConfirmation = false
    @State private var userToDelete: User?
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("User Management")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            
            if users.isEmpty {
                Text("No users available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(users) { user in
                        UserRowView(user: user) {
                            selectedUser = user
                            showEditUser = true
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                userToDelete = user
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditUser, content: {
            if let user = selectedUser {
                EditUserView(user: user) { updatedUser in
                    updateUser(updatedUser)
                }
            }
        })
        .alert("Delete User", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let user = userToDelete {
                    deleteUser(user)
                }
            }
        } message: {
            Text("Are you sure you want to delete this user? This action cannot be undone.")
        }
        .onAppear {
            loadUsers()
        }
    }
    
    private func loadUsers() {
        let ref = Database.database().reference().child("users")
        ref.observe(.value) { snapshot in
            var loadedUsers: [User] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
                    let user = User(id: snapshot.key, data: dict)
                    loadedUsers.append(user)
                }
            }
            users = loadedUsers
        }
    }
    
    private func updateUser(_ user: User) {
        let ref = Database.database().reference().child("users").child(user.id)
        let data: [String: Any] = [
            "name": user.name,
            "email": user.email
        ]
        ref.updateChildValues(data)
    }
    
    private func deleteUser(_ user: User) {
        let ref = Database.database().reference().child("users").child(user.id)
        ref.removeValue()
    }
}

struct UserRowView: View {
    let user: User
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EditUserView: View {
    let user: User
    let onSave: (User) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var email: String
    
    init(user: User, onSave: @escaping (User) -> Void) {
        self.user = user
        self.onSave = onSave
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Details")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit User")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let updatedUser = User(
                        id: user.id,
                        data: [
                            "name": name,
                            "email": email
                        ]
                    )
                    onSave(updatedUser)
                    dismiss()
                }
                .disabled(name.isEmpty || email.isEmpty)
            )
        }
    }
} 