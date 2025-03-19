//
//  ecommerceApp.swift
//  ecommerce
//
//  Created by User on 2025-03-11.
//

import SwiftUI
import Firebase

@main
struct ecommerceApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
