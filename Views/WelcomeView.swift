import SwiftUI
import FirebaseAuth
struct WelcomeView: View {
    @State private var signingInAnonymously = false
    @State private var navigateToGuest = false
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(
                        colors: [Color(hex: "#1F1D36"), Color(hex: "#9B5DE5")]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            
                // Blurred glass card
                VStack(spacing: 24) {
                    Text("Who’s da Boss?")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                
                    Text("A fun guessing game to discover your inner boss.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                
                    Spacer().frame(height: 30)
                
//                    NavigationLink(destination: GuestEntryView()) {
//                        GlassButton(
//                            title: "Play as Guest",
//                            icon: "person.fill"
//                        )
//                    }
                    
                    GlassActionButton(title: signingInAnonymously ? "Signing in ... " : "Play as Guest", icon: "person.fill") {
                        signingInAnonymously = true
                        if Auth.auth().currentUser == nil {
                            Auth.auth().signInAnonymously { result, error in
                                signingInAnonymously = false
                                if let error = error {
                                    print("Error: ", error.localizedDescription)
                                    return
                                } else {
                                    print("Signed in as user: ", result?.user.uid ?? "Anonymous")
                                    navigateToGuest = true
                                }
                            }
                        } else {
                            signingInAnonymously = false
                            navigateToGuest = true
                        }
                    }
                    
                    NavigationLink(
                        destination: GuestEntryView(),
                        isActive: $navigateToGuest
                    ) {
                        EmptyView()
                    }
                
                    GlassButton(title: "Log In / Sign Up", icon: "lock.fill")
                
                }
                .padding()
                .frame(maxWidth: 350)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 30)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )
                .padding(.horizontal, 30)
            }
        }
    }
}

struct GlassButton: View {
    var title: String
    var icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}


#Preview {
    WelcomeView()
}

// Color extension for HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
