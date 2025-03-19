import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct Order: Identifiable {
    let id: String
    let date: Date
    let items: [OrderItem]
    let total: Double
    let status: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.date = Date(timeIntervalSince1970: (data["timestamp"] as? Double ?? 0) / 1000)
        self.total = data["totalAmount"] as? Double ?? 0.0
        self.status = data["status"] as? String ?? "Processing"
        
        var orderItems: [OrderItem] = []
        if let products = data["products"] as? [[String: Any]] {
            for item in products {
                if let orderItem = OrderItem(data: item) {
                    orderItems.append(orderItem)
                }
            }
        }
        self.items = orderItems
    }
}

struct OrderItem: Identifiable {
    let id: String
    let name: String
    let price: Double
    let quantity: Int
    let imageUrl: String
    
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let price = data["price"] as? Double,
              let quantity = data["quantity"] as? Int,
              let imageUrl = data["imageUrl"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.imageUrl = imageUrl
    }
}

struct OrdersView: View {
    @State private var orders: [Order] = []
    @State private var isLoading = false
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if orders.isEmpty {
                Text("No orders yet")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(orders.sorted(by: { $0.date > $1.date })) { order in
                    OrderCard(order: order)
                }
            }
        }
        .navigationTitle("My Orders")
        .onAppear {
            loadOrders()
        }
    }
    
    private func loadOrders() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let ref = Database.database().reference().child("orders")
        ref.observeSingleEvent(of: .value) { snapshot in
            isLoading = false
            orders.removeAll()
            
            guard let ordersData = snapshot.value as? [String: [String: Any]] else { return }
            
            for (orderId, orderData) in ordersData {
                if orderData["userId"] as? String == userId {
                    let order = Order(id: orderId, data: orderData)
                    orders.append(order)
                }
            }
        }
    }
}

struct OrderCard: View {
    let order: Order
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Order #\(order.id.prefix(8))")
                        .font(.headline)
                    Text(order.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(order.status)
                    .font(.caption)
                    .padding(6)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            
            if isExpanded {
                Divider()
                
                ForEach(order.items) { item in
                    HStack {
                        AsyncImage(url: URL(string: item.imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 40, height: 40)
                        .cornerRadius(6)
                        
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.subheadline)
                            Text("Qty: \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                            .font(.subheadline)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("$\(order.total, specifier: "%.2f")")
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
    
    private var statusColor: Color {
        switch order.status.lowercased() {
        case "processing":
            return .blue
        case "shipped":
            return .orange
        case "delivered":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
} 