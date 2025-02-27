//
//  TipJarView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 24/02/2025.
//

import SwiftUI
import StoreKit
import FirebaseAnalytics

struct TipJarView: View {
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var showConfetti = false
    @State private var showThanks = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    
    // This flag tracks whether the user has donated.
    @AppStorage("hasDonated") var hasDonated: Bool = false

    // Define donation options with your product identifiers and custom titles.
    let donationOptions: [(id: String, title: String)] = [
        ("Bins.Ren.Renfrewshire.tipTiny", "Wee Tablet-Sized Tip"),
        ("Bins.Ren.Renfrewshire.tipMid", "Scotch Pie-Sized Tip"),
        ("Bins.Ren.Renfrewshire.tipBig", "Haggis, Neeps & Tatties-Sized Tip")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("Support the App")) {
                        if (!hasDonated){
                            Text("If you enjoy using this app, please consider donating. It will help me to keep it free and allow me to add new features. You will also unlock the Ball minigame, notification time setting and accent colour setting!")
                        } else {
                            Text("Thank you for your donation! If you want, you can donate more in the future.")
                        }
                        
                        if isLoading {
                            ProgressView("Loading donation options…")
                        } else {
                            ForEach(products, id: \.id) { product in
                                // Match the product to a donation option by ID.
                                if let option = donationOptions.first(where: { $0.id == product.id }) {
                                    Button {
                                        Task {
                                            await purchase(product)
                                        }
                                    } label: {
                                        HStack {
                                            Text(option.title)
                                                .font(.subheadline)
                                            Spacer()
                                            Text(product.displayPrice)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // Confetti overlay (shown when a purchase is successful)
                if showConfetti {
                    ConfettiView()
                        .transition(.opacity)
                }
                // Thanks overlay (shown after successful purchase)
                if showThanks {
                    VStack {
                        Text("Thank you very much for your support!")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 300, height: 100, alignment: .center)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(20)
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("❤️ Tip Jar")
            .alert("Purchase Error", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage ?? "Something went wrong.")
            })
            .onAppear {
                Task {
                    await loadProducts()
                }
            }
        }
    }
    
    // Load products using the donationOptions' product identifiers.
    func loadProducts() async {
        do {
            let productIDs = donationOptions.map { $0.id }
            products = try await Product.products(for: productIDs)
            
            // Sort products in the desired order: small, medium, large.
            products.sort { prod1, prod2 in
                guard let idx1 = donationOptions.firstIndex(where: { $0.id == prod1.id }),
                      let idx2 = donationOptions.firstIndex(where: { $0.id == prod2.id }) else {
                    return false
                }
                return idx1 < idx2
            }
        } catch {
            print("Failed to fetch products: \(error)")
            errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            showError = true
        }
        isLoading = false
    }
    
    // Purchase the selected product and show confetti & thanks on success.
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    print("Purchase successful: \(transaction)")
                    Analytics.logEvent("tip_purchase_success", parameters: [
                        "product_id": product.id
                    ])
                    // Mark that the user has donated.
                    hasDonated = true
                    await transaction.finish()
                    
                    // Show confetti and thanks overlays.
                    withAnimation {
                        showConfetti = true
                        showThanks = true
                    }
                    // Hide confetti after 5 seconds.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            showConfetti = false
                        }
                        // Hide thanks after an additional 2 seconds.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showThanks = false
                            }
                        }
                    }
                case .unverified(_, let error):
                    print("Purchase unverified: \(error.localizedDescription)")
                    errorMessage = "Purchase unverified: \(error.localizedDescription)"
                    showError = true
                }
            case .userCancelled:
                print("Purchase cancelled by the user")
            case .pending:
                print("Purchase is pending")
            @unknown default:
                print("Unknown purchase result")
                errorMessage = "Unknown purchase result."
                showError = true
            }
        } catch {
            print("Purchase failed: \(error)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            showError = true
        }
    }
}

// A simple confetti view for the explosion effect.
struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<100, id: \.self) { _ in
                Circle()
                    .fill(randomColor())
                    .frame(width: 8, height: 8)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: animate ? geometry.size.height + 20 : -20
                    )
                    .animation(
                        Animation.easeOut(duration: Double.random(in: 1.5...3))
                            .delay(Double.random(in: 0...0.5)),
                        value: animate
                    )
            }
            .onAppear {
                animate = true
            }
        }
        .ignoresSafeArea()
    }

    func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        return colors.randomElement()!
    }
}
