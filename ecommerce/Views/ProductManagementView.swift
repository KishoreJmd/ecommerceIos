import SwiftUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct ProductManagementView: View {
    @Environment(\.dismiss) var dismiss
    @State private var products: [Product] = []
    @State private var showAddProduct = false
    @State private var selectedProduct: Product?
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("Product Management")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            
            Button(action: { showAddProduct = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add New Product")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if products.isEmpty {
                Text("No products available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(products) { product in
                        ProductRowView(product: product) {
                            selectedProduct = product
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteProduct(product)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddProduct) {
            ProductFormView(mode: .add) { product in
                addProduct(product)
            }
        }
        .sheet(item: $selectedProduct) { product in
            ProductFormView(mode: .edit(product)) { updatedProduct in
                updateProduct(updatedProduct)
            }
        }
        .onAppear {
            loadProducts()
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
    
    private func addProduct(_ product: Product) {
        let ref = Database.database().reference().child("products").childByAutoId()
        let data: [String: Any] = [
            "name": product.name,
            "price": product.price,
            "description": product.description,
            "imageUrl": product.imageUrl ?? ""
        ]
        ref.setValue(data)
    }
    
    private func updateProduct(_ product: Product) {
        let ref = Database.database().reference().child("products").child(product.id)
        let data: [String: Any] = [
            "name": product.name,
            "price": product.price,
            "description": product.description,
            "imageUrl": product.imageUrl ?? ""
        ]
        ref.updateChildValues(data)
    }
    
    private func deleteProduct(_ product: Product) {
        if let imageUrl = product.imageUrl {
            let storage = Storage.storage()
            let storageRef = storage.reference(forURL: imageUrl)
            storageRef.delete { error in
                if let error = error {
                    print("Error deleting image: \(error)")
                }
            }
        }
        
        let ref = Database.database().reference().child("products").child(product.id)
        ref.removeValue()
    }
}

struct ProductRowView: View {
    let product: Product
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            if let imageUrl = product.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text("$\(String(format: "%.2f", product.price))")
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

struct ProductFormView: View {
    enum Mode {
        case add
        case edit(Product)
        
        var isEditing: Bool {
            switch self {
            case .add:
                return false
            case .edit:
                return true
            }
        }
        
        var productId: String {
            switch self {
            case .add:
                return UUID().uuidString
            case .edit(let product):
                return product.id
            }
        }
        
        var existingImageUrl: String? {
            switch self {
            case .add:
                return nil
            case .edit(let product):
                return product.imageUrl
            }
        }
    }
    
    let mode: Mode
    let onSave: (Product) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var price = ""
    @State private var description = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var currentUser: (email: String, name: String)?
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(mode: Mode, onSave: @escaping (Product) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        if case .edit(let product) = mode {
            _name = State(initialValue: product.name)
            _price = State(initialValue: String(format: "%.2f", product.price))
            _description = State(initialValue: product.description)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Details")) {
                    TextField("Product Name", text: $name)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Product Image")) {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let selectedImageData,
                           let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } else if let existingUrl = mode.existingImageUrl,
                                  let url = URL(string: existingUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(maxHeight: 200)
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Select Image")
                            }
                        }
                    }
                }
                
                if isUploading {
                    Section {
                        ProgressView("Uploading image...")
                    }
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(mode.isEditing ? "Edit Product" : "Add Product")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveProduct()
                }
                .disabled(name.isEmpty || price.isEmpty || description.isEmpty || currentUser == nil || isUploading)
            )
            .onChange(of: selectedImage) { _, _ in
                Task {
                    if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
        .onAppear {
            if let user = Auth.auth().currentUser {
                let ref = Database.database().reference().child("users").child(user.uid)
                ref.observeSingleEvent(of: .value) { snapshot in
                    if let dict = snapshot.value as? [String: Any],
                       let email = dict["email"] as? String,
                       let name = dict["name"] as? String {
                        currentUser = (email: email, name: name)
                    }
                }
            }
        }
    }
    
    private func saveProduct() {
        guard let user = currentUser else { return }
        
        isUploading = true
        showError = false
        
        if let imageData = selectedImageData {
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let imageRef = storageRef.child("product_images/\(UUID().uuidString).jpg")
            
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    isUploading = false
                    showError = true
                    errorMessage = error.localizedDescription
                    return
                }
                
                imageRef.downloadURL { url, error in
                    isUploading = false
                    
                    if let error = error {
                        showError = true
                        errorMessage = error.localizedDescription
                        return
                    }
                    
                    if let url = url {
                        let product = Product(
                            id: mode.productId,
                            name: name,
                            price: Double(price) ?? 0.0,
                            description: description,
                            imageUrl: url.absoluteString
                        )
                        onSave(product)
                        dismiss()
                    }
                }
            }
        } else {
            let product = Product(
                id: mode.productId,
                name: name,
                price: Double(price) ?? 0.0,
                description: description,
                imageUrl: mode.existingImageUrl
            )
            onSave(product)
            dismiss()
        }
    }
} 
