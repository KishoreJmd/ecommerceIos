import SwiftUI
import FirebaseAuth
import UIKit

struct AdminDashboard: View {
    @State private var showProductManagement = false
    @State private var showUserManagement = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                Button(action: { showProductManagement = true }) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Product Management")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: { showUserManagement = true }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("User Management")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: logout) {
                    HStack {
                        Image(systemName: "arrow.right.square.fill")
                        Text("Logout")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showProductManagement) {
            ProductManagementView()
        }
        .fullScreenCover(isPresented: $showUserManagement) {
            UserManagementView()
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            // Navigate back to login using the new API
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: LoginView())
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
} 
