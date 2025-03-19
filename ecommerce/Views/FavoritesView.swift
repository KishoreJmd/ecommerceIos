import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct FavoritesView: View {
    @State private var favoriteProducts: [Product] = []
    
    var body: some View {
        NavigationView {
            if favoriteProducts.isEmpty {
                Text("No favorites yet")
                    .foregroundColor(.gray)
                    .navigationTitle("Favorites")
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(favoriteProducts) { product in
                            FavoriteProductCard(product: product, onRemove: {
                                if let index = favoriteProducts.firstIndex(where: { $0.id == product.id }) {
                                    favoriteProducts.remove(at: index)
                                }
                            })
                        }
                    }
                    .padding()
                }
                .navigationTitle("Favorites")
            }
        }
        .onAppear {
            loadFavorites()
        }
    }
    
    private func loadFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("favorites")
        
        ref.observe(.value) { snapshot in
            if let favorites = snapshot.value as? [String: Bool] {
                let favoriteIds = favorites.filter { $0.value }.map { $0.key }
                loadProducts(ids: favoriteIds)
            }
        }
    }
    
    private func loadProducts(ids: [String]) {
        let ref = Database.database().reference().child("products")
        ref.observe(.value) { snapshot in
            var loadedProducts: [Product] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   ids.contains(snapshot.key) {
                    let id = snapshot.key
                    let name = dict["name"] as? String ?? ""
                    let price = dict["price"] as? Double ?? 0.0
                    let description = dict["description"] as? String ?? ""
                    let imageUrl = dict["imageUrl"] as? String
                    
                    let product = Product(
                        id: id,
                        name: name,
                        price: price,
                        description: description,
                        imageUrl: imageUrl
                    )
                    loadedProducts.append(product)
                }
            }
            favoriteProducts = loadedProducts
        }
    }
}

struct FavoriteProductCard: View {
    let product: Product
    let onRemove: () -> Void
    @State private var showRemoveAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: ProductDetailView(product: product)) {
                    VStack(alignment: .leading) {
                        if let imageUrl = product.imageUrl,
                           let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 150)
                            .clipped()
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 150)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text("$\(String(format: "%.2f", product.price))")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
                
                Button(action: { showRemoveAlert = true }) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 2)
                }
                .padding(8)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .alert("Remove from Favorites", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removeFromFavorites()
            }
        } message: {
            Text("Are you sure you want to remove this item from your favorites?")
        }
    }
    
    private func removeFromFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("favorites")
        ref.child(product.id).removeValue { error, _ in
            if error == nil {
                onRemove()
            }
        }
    }
} 