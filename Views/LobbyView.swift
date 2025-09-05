import SwiftUI
import FirebaseFirestore

struct LobbyView: View {
    @StateObject private var gameRoomManager = GameRoomManager()
    let roomCode: String
    let displayName: String
    let isHost: Bool
    let db = Firestore.firestore()
    @State private var showFunFactSheet = false
    @State private var goToGuessingView = false
    private var allSubmitted: Bool {
        gameRoomManager.players.allSatisfy {
            $0.funFact != "Empty"
        }
    }
    var body: some View {
        ZStack {
            NavigationLink("", isActive: $goToGuessingView) {
                GuessView(roomCode: roomCode).environmentObject(gameRoomManager)
            }
            .hidden()
            LinearGradient(
                gradient: Gradient(
                    colors: [Color(hex: "#1F1D36"), Color(hex: "#9B5DE5")]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("👋 Welcome, \(displayName)")
                        .font(.title2)
                        .foregroundColor(.white)

                    Text("Room Code: \(roomCode)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if isHost {
                        Text("You're the Host 👑")
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                }

                VStack(spacing: 12) {
                    Text("Waiting for players to join...")
                        .foregroundColor(.white.opacity(0.7))

                    VStack(spacing: 8) {
                        Text("Players")
                            .font(.headline)
                            .foregroundColor(.orange)
                                        
                        // Horizontal strip (easy to scan on phones)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(gameRoomManager.players) { player in
                                    VStack(spacing: 8) {
                                        AvatarAsyncView(urlString: player.avatarURL, name: player.name, size: 68)
                                        Text(player.name)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)
                                            .frame(width: 72)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }

                Spacer()

                if isHost {
                    if !allSubmitted {
                        GlassActionButton(
                            title: "Start Submitting",
                            icon: "flag.fill"
                        ) {
                            showFunFactSheet = true
                            db.collection("gameRooms")
                                .document(roomCode)
                                .updateData(
                                    ["showFunFactSheet" : true]
                                ) { error in
                                    if let error = error {
                                        print(
                                            "There is an error in updating",
                                            error
                                        )
                                    }
                                    else {
                                        print(
                                            "showFunFactSheet is set true in the database"
                                        )
                                    }
                                }
                        }
                    }
                    
//                    else {
//                        GlassActionButton(
//                            title: "Start Guessing",
//                            icon: "magnifyingglass.circle.fill"
//                        ) {
//                            GuessView()
//                        }
//                    }
                    
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.white.opacity(0.05))
                    .blur(radius: 15)
            )
            .padding()
            .onAppear {
                gameRoomManager.listenToPlayers(in: roomCode)
                
                db.collection("gameRooms").document(roomCode)
                    .addSnapshotListener {
                        snapshot,
                        error in
                        guard let data = snapshot?.data() else {
                            print("failed to listen to the data")
                            return
                        }
                        
                        let shouldShow = data["showFunFactSheet"] as? Bool ?? false
                        if shouldShow && !showFunFactSheet {
                            print("getting data from the firebase")
                            showFunFactSheet = true
                        }
                    }
            }
            .sheet(isPresented: $showFunFactSheet) {
                FunFactView(displayName: displayName, roomCode: roomCode)
            }
            .onChange(of: allSubmitted) { newValue in
                if newValue {
                    goToGuessingView = true
                }
            }
        }
    }
}
