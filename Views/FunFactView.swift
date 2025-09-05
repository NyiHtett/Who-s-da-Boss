import Foundation
import SwiftUI

struct FunFactView: View {
    @Environment(\.dismiss) var dismiss
    let displayName: String
    let roomCode: String
    @State private var funFact = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("What's a fun fact about you, \(displayName)?")
                    .font(.title3)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .padding()

                TextEditor(text: $funFact)
                    .padding(20)
                    .frame(height: 150)
                    .scrollContentBackground(.hidden)
                    .background(.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    

                GlassActionButton(title: "Submit your fun fact", icon: "checkmark.circle.fill") {
                    print("Submitted fun fact: \(funFact)")
                    // later: send this to Firestore
                    let manager = GameRoomManager()
                    manager.submitFunFact(to: roomCode, funfact: funFact)
                    dismiss()
                }
                .padding(.top)

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#1F1D36"), Color(hex: "#9B5DE5")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
}
