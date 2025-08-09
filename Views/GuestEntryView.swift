import SwiftUI

struct GuestEntryView: View {
    @State private var displayName = ""
    @State private var roomCode = ""
    @State private var generatedCode: String?
    @State private var isHosting: Bool? = nil  // nil = undecided

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1F1D36"), Color(hex: "#9B5DE5")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Join the Game")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    TextField("Your Display Name", text: $displayName)
                        .textFieldStyle(GlassTextField())

                    // Show if hosting or joining has not yet been selected
                    if isHosting == nil {
                        GlassActionButton(title: "Host Game", icon: "crown.fill") {
                            isHosting = true
                            generatedCode = generateRoomCode()
                        }

                        GlassActionButton(title: "Join Game", icon: "arrow.right.circle.fill") {
                            isHosting = false
                        }
                    }

                    // Hosting View
                    if isHosting == true, let code = generatedCode {
                        Text("Your Room Code: \(code)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 20)
                    }

                    // Joining View
                    if isHosting == false {
                        TextField("Enter Room Code", text: $roomCode)
                            .textFieldStyle(GlassTextField())

                        GlassActionButton(title: "Join Room", icon: "arrow.right.circle.fill") {
                            // Join room with displayName and roomCode
                        }
                    }

                    // Back option
                    if isHosting != nil {
                        Button("Change Option") {
                            isHosting = nil
                            generatedCode = nil
                            roomCode = ""
                        }
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 10)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 350)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 30)
        }
    }

    // Dummy generator — replace with Firebase later
    func generateRoomCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<5).map { _ in letters.randomElement()! })
    }
}

struct GlassActionButton: View {
    var title: String
    var icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
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
}


struct GlassTextField: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}
