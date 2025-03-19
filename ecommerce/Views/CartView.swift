import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct CartView: View {
    @State private var cartItems: [CartItem] = []
    @State private var totalPrice: Double = 0
    @State private var showOrderPlacedAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            if cartItems.isEmpty {
                Text("Your cart is empty")
                    .foregroundColor(.gray)
                    .navigationTitle("Cart")
            } else {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(cartItems) { item in
                                CartItemRow(
                                    product: item.product,
                                    quantity: item.quantity,
                                    onDelete: {
                                        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
                                            cartItems.remove(at: index)
                                            updateTotalPrice()
                                        }
                                    },
                                    onUpdateQuantity: { newQuantity in
                                        updateCartItemQuantity(item: item, quantity: newQuantity)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total:")
                                .font(.headline)
                            Spacer()
                            Text("$\(String(format: "%.2f", totalPrice))")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        Button(action: checkout) {
                            Text("Checkout")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .shadow(radius: 2)
                }
                .navigationTitle("Cart")
            }
        }
        .onAppear {
            loadCart()
        }
        .alert(alertMessage, isPresented: $showOrderPlacedAlert) {
            Button("OK") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                    tabBarController.selectedIndex = 3
                }
            }
        }
    }
    
    private func updateTotalPrice() {
        totalPrice = cartItems.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    private func updateCartItemQuantity(item: CartItem, quantity: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("cart")
        
        let cartItem: [String: Any] = [
            "quantity": quantity,
            "price": item.product.price,
            "active": true
        ]
        
        ref.child(item.product.id).updateChildValues(cartItem)
        
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            cartItems[index].quantity = quantity
            updateTotalPrice()
        }
    }
    
    private func loadCart() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("cart")
        
        ref.observe(.value) { snapshot in
            var loadedItems: [String: [String: Any]] = [:]
            if let cart = snapshot.value as? [String: [String: Any]] {
                loadedItems = cart.filter { $0.value["active"] as? Bool ?? false }
            }
            loadProducts(items: loadedItems)
        }
    }
    
    private func loadProducts(items: [String: [String: Any]]) {
        let ref = Database.database().reference().child("products")
        ref.observe(.value) { snapshot in
            var loadedCartItems: [CartItem] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let cartItemData = items[snapshot.key] {
                    let id = snapshot.key
                    let name = dict["name"] as? String ?? ""
                    let price = dict["price"] as? Double ?? 0.0
                    let description = dict["description"] as? String ?? ""
                    let imageUrl = dict["imageUrl"] as? String
                    let quantity = cartItemData["quantity"] as? Int ?? 1
                    
                    let product = Product(
                        id: id,
                        name: name,
                        price: price,
                        description: description,
                        imageUrl: imageUrl
                    )
                    
                    let cartItem = CartItem(
                        id: id,
                        product: product,
                        quantity: quantity
                    )
                    loadedCartItems.append(cartItem)
                }
            }
            cartItems = loadedCartItems
            updateTotalPrice()
        }
    }
    
    private func checkout() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ordersRef = Database.database().reference().child("orders")
        let cartRef = Database.database().reference().child("users").child(userId).child("cart")
        
        let products = cartItems.map { item -> [String: Any] in
            return [
                "id": item.product.id,
                "name": item.product.name,
                "price": item.product.price,
                "quantity": item.quantity,
                "imageUrl": item.product.imageUrl ?? ""
            ]
        }
        
        let orderData: [String: Any] = [
            "userId": userId,
            "products": products,
            "totalAmount": totalPrice,
            "status": "placed",
            "timestamp": ServerValue.timestamp()
        ]
        
        let orderRef = ordersRef.childByAutoId()
        orderRef.setValue(orderData) { error, _ in
            if error == nil {
                cartRef.removeValue()
                cartItems = []
                totalPrice = 0
                alertMessage = "Order placed successfully! View your order in the Account tab."
                showOrderPlacedAlert = true
            } else {
                alertMessage = "Failed to place order. Please try again."
                showOrderPlacedAlert = true
            }
        }
    }
}

struct CartItemRow: View {
    let product: Product
    let quantity: Int
    let onDelete: () -> Void
    let onUpdateQuantity: (Int) -> Void
    @State private var showRemoveAlert = false
    @State private var itemQuantity: Int
    
    init(product: Product, quantity: Int, onDelete: @escaping () -> Void, onUpdateQuantity: @escaping (Int) -> Void) {
        self.product = product
        self.quantity = quantity
        self.onDelete = onDelete
        self.onUpdateQuantity = onUpdateQuantity
        _itemQuantity = State(initialValue: quantity)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = product.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                // Quantity Stepper
                Stepper(value: $itemQuantity, in: 1...99) {
                    Text("Qty: \(itemQuantity)")
                        .font(.subheadline)
                }
                .onChange(of: itemQuantity) { newValue in
                    onUpdateQuantity(newValue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Button(action: { showRemoveAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                
                Text("$\(String(format: "%.2f", product.price * Double(itemQuantity)))")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .alert("Remove Item", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removeFromCart()
            }
        } message: {
            Text("Are you sure you want to remove this item from your cart?")
        }
    }
    
    private func removeFromCart() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId).child("cart")
        ref.child(product.id).removeValue { error, _ in
            if error == nil {
                onDelete()
            }
        }
    }
}

struct CartItem: Identifiable {
    let id: String
    let product: Product
    var quantity: Int
} 