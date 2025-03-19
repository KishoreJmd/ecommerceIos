import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct ProductDetailView: View {
    let product: Product
    @State private var isFavorite = false
    @State private var isInCart = false
    @State private var quantity = 1
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Product Image
                if let imageUrl = product.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 300)
                    .clipped()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 300)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Product Name
                    Text(product.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Price
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    // Description
                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    // Quantity Stepper
                    HStack {
                        Text("Quantity:")
                            .font(.headline)
                        
                        Stepper(value: $quantity, in: 1...99) {
                            Text("\(quantity)")
                                .font(.headline)
                                .frame(minWidth: 50)
                        }
                    }
                    .padding(.vertical)
                    
                    // Total Price
                    HStack {
                        Text("Total:")
                            .font(.headline)
                        Text("$\(String(format: "%.2f", Double(quantity) * product.price))")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        // Favorite Button
                        Button(action: toggleFavorite) {
                            HStack {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorite ? .red : .gray)
                                Text(isFavorite ? "Favorited" : "Add to Favorites")
                                    .foregroundColor(isFavorite ? .red : .gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                        
                        // Cart Button
                        Button(action: toggleCart) {
                            HStack {
                                Image(systemName: isInCart ? "cart.fill" : "cart")
                                    .foregroundColor(isInCart ? .blue : .gray)
                                Text(isInCart ? "Update Cart" : "Add to Cart")
                                    .foregroundColor(isInCart ? .blue : .gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            checkFavoriteStatus()
            checkCartStatus()
        }
    }
    
    private func checkFavoriteStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("favorites")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let favorites = snapshot.value as? [String: Bool] {
                isFavorite = favorites[product.id] ?? false
            }
        }
    }
    
    private func checkCartStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("cart")
        
        ref.child(product.id).observeSingleEvent(of: .value) { snapshot in
            if let cartItem = snapshot.value as? [String: Any] {
                isInCart = true
                if let qty = cartItem["quantity"] as? Int {
                    quantity = qty
                }
            }
        }
    }
    
    private func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("favorites")
        
        if isFavorite {
            // Remove from favorites
            ref.child(product.id).removeValue()
            alertMessage = "Removed from favorites"
        } else {
            // Add to favorites
            ref.child(product.id).setValue(true)
            alertMessage = "Added to favorites"
        }
        isFavorite.toggle()
        showAlert = true
    }
    
    private func toggleCart() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("cart")
        
        let cartItem: [String: Any] = [
            "quantity": quantity,
            "price": product.price,
            "active": true
        ]
        
        ref.child(product.id).setValue(cartItem) { error, _ in
            if error == nil {
                isInCart = true
                alertMessage = "Added to cart"
            }
            showAlert = true
        }
    }
} 