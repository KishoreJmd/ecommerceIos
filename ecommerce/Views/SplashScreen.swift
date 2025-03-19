import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            LoginView()
        } else {
            VStack {
                
                Text("A whole grocery store")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("at your fingertips")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.orange.gradient)
            .ignoresSafeArea()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
} 
