import SwiftUI
import FirebaseDatabase

struct HomeView: View {
    @State private var products: [Product] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(products) { product in
                        ProductCard(product: product)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .onAppear {
                loadProducts()
            }
        }
    }
    
    private func loadProducts() {
        let ref = Database.database().reference().child("products")
        ref.observe(.value) { snapshot in
            var loadedProducts: [Product] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
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
            products = loadedProducts
        }
    }
}

struct ProductCard: View {
    let product: Product
    
    var body: some View {
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
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
} 