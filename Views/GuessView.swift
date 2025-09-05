//
//  GuessView.swift
//  Who's da Boss
//
//  Created by Nyi Htet on 8/12/25.
//

import SwiftUI
import VideoToolbox
import AVFoundation
import AVKit
import Combine
import FirebaseAuth
struct GuessView: View {
    let roomCode: String
    @EnvironmentObject private var gameRoomManager: GameRoomManager
    @State private var player: AVPlayer = {
        let url = Bundle.main.url(forResource: "final", withExtension: "mp4")!
        return AVPlayer(url: url)
    }()
    @State private var showContent = false
    @State var funFacts: [funFact] = []
    
    // variables for the fun facts
    @State private var currentIndex = 0
    @State private var order: [Player] = []
    @State private var timeLeft = 10
    @State private var timerCancellable: AnyCancellable?
    @State private var selectedOptionID: String? = nil

    @State private var locked: Bool = false
    @State private var winners: [String] = []
    
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 24), count: 3)
    var body: some View {
        
        ZStack {
            Color.purple.ignoresSafeArea()
            if !showContent {
                // Video first
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.seek(to: .zero)
                        player.play()
                    }
                    .onReceive(
                        NotificationCenter.default
                            .publisher(for: .AVPlayerItemDidPlayToEndTime)
                    ) { _ in
                        // When video ends, show content
                        showContent = true
                    }
            } else {
                // Your GuessView content
                VStack {
                    Spacer()
                    Text("Guess the Fact!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Spacer()
                    
                    Text("⏱️ \(timeLeft)s left")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    if order.indices.contains(currentIndex) {
                        let player = order[currentIndex]
                        Spacer()
                        Text(player.funFact)
                        Spacer()
                        ScrollView {
                            LazyVGrid(
                                columns: columns,
                                alignment: .center,
                                spacing: 28
                            ) {
                                ForEach(gameRoomManager.players) { optionPlayer in
                                    Button {
                                        // allow only first selection
                                        guard selectedOptionID == nil else { return }
                                        selectedOptionID = optionPlayer.id

                                        if optionPlayer.id == player.id {
                                            if let user = Auth.auth().currentUser {
                                                gameRoomManager.increasePoint(in: roomCode, userID: user.uid)
                                            }
                                        }
                                    } label: {
                                        VStack(spacing: 10) {
                                            OptionAvatar(
                                                imageURL: URL(string: optionPlayer.avatarURL ?? ""),
                                                size: 88
                                            )
                                            Text(optionPlayer.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(10)
                                        // 👇 highlight ONLY the selected tile
                                        .background(
                                            selectedOptionID == optionPlayer.id
                                                ? Color.blue.opacity(0.6)
                                                : Color.clear
                                        )
                                        .overlay(
                                            // optional: add a ring on the selected tile
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(selectedOptionID == optionPlayer.id ? Color.white.opacity(0.6) : .clear, lineWidth: 2)
                                        )
                                    }
                                    // optional: prevent changing your answer after first tap
                                    .disabled(selectedOptionID != nil)
                                    .instantPressCard()
                                }

                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                        }
                        Spacer()
                    }
                    else {
                        VStack{
                            Spacer()
                            Text("Game Over")
                            Spacer()
                            if winners.isEmpty {
                                ProgressView("Calculating winner…")
                            } else {
                                ForEach(winners, id: \.self) { id in
                                    VStack(spacing: 10) {
                                        OptionAvatar(
                                            //                                            imageURL: URL(string: optionPlayer.photoURL ?? ""),
                                            imageURL: avatarURL(for: id),
                                            //                                            seed: optionPlayer.id,
                                            size: 88            // <-- big round avatar
                                        )
                                        Text("🏆 \(name(for: id)) wins!")
                                            .foregroundColor(.white)
                                    }
                                    
                                }
                            }
                            Spacer()
                        }
                        .task {
                            do {
                                winners = try await gameRoomManager
                                    .calculateWinner(in: roomCode)
                            } catch {
                                print("error in reading the winner: \(error)")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.purple.ignoresSafeArea())
            }
        }
    
        // REMOVE this from .onAppear (it runs during the intro video)
        // startTimer()

        .onChange(of: showContent) { shown in
            if shown, !gameRoomManager.players.isEmpty {
                order = gameRoomManager.players
                currentIndex = 0
                startTimer()                 // ← start only now
            }
        }

        // If players arrive AFTER the video, init then
        .onChange(of: gameRoomManager.players) { _ in
            guard showContent else { return }
            if order.isEmpty, !gameRoomManager.players.isEmpty {
                order = gameRoomManager.players.shuffled()
                currentIndex = 0
                startTimer()
            }
        }

        // Optional: clean up
        .onDisappear { timerCancellable?.cancel() }

        .onAppear {
            order = gameRoomManager.players.shuffled()
            currentIndex = 0
            // DO NOT call startTimer() here
        }

        //        .onAppear {prepareFunFacts()}
        
    }
    
    // Helper in GuessView
    private func name(for id: String) -> String {
        gameRoomManager.players.first(where: { $0.id == id })?.name ?? id
    }

    // Get the player via the specific ID
    private func player(for id: String) -> Player? {
        gameRoomManager.players.first { $0.id == id }
    }
    
    private func avatarURL(for id: String) -> URL? {
        guard
            let urlString = gameRoomManager.players.first(where: { $0.id == id })?.avatarURL,
            !urlString.isEmpty
        else { return nil }
        return URL(string: urlString)
    }

    
    private func startTimer() {
        timerCancellable?.cancel()
        timeLeft = 10
        selectedOptionID = nil
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeLeft > 0 {
                    timeLeft -= 1
                } else {
                    timerCancellable?.cancel()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        nextQuestion()
                    }
                }
            }
    }
    
    private func nextQuestion() {
        if (currentIndex + 1 < order.count) {
            currentIndex += 1
            locked = false
            startTimer()
        } else {
            timerCancellable?.cancel()
            timeLeft = 0
            currentIndex = order.count
        }
    }
    private func prepareFunFacts() {
        for player in gameRoomManager.players {
            let question = funFact(id: player.id, fact: player.funFact, options: gameRoomManager.players.filter({ member in
                member.id != player.id
            }), correctPlayerID: player.id)
            funFacts.append(question)
        }
    }
}

// 1) Drop this somewhere (e.g., below your view) — liquid glass style
struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [
                            .white.opacity(0.6),
                            .white.opacity(0.15)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .overlay(
                // subtle top highlight
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white.opacity(0.12))
                    .blur(radius: 6)
                    .offset(y: -8)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .padding(.bottom, 24)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 18) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius))
    }
}

struct InstantPressCard: ViewModifier {
    @State private var flashing = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(flashing ? 0.96 : 1.0)
            .background(
                flashing ? Color.white.opacity(0.25) : Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(flashing ? 0.5 : 0.25),
                radius: flashing ? 12 : 6,
                x: 0,
                y: flashing ? 6 : 4
            )
        // Make the feedback visible even for quick taps:
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !flashing {
                            withAnimation(
                                .spring(response: 0.22, dampingFraction: 0.7)
                            ) {
                                flashing = true
                            }
                            DispatchQueue.main
                                .asyncAfter(deadline: .now() + 0.12) {
                                    withAnimation(
                                        .spring(
                                            response: 0.28,
                                            dampingFraction: 0.7
                                        )
                                    ) {
                                        flashing = false
                                    }
                                }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(
                            .spring(response: 0.2, dampingFraction: 0.7)
                        ) {
                            flashing = false
                        }
                    }
            )
        
    }
}

extension View {
    func instantPressCard() -> some View { modifier(InstantPressCard()) }
}

struct OptionAvatar: View {
    let imageURL: URL?
    let seed: String  = ""        // e.g., player.id
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(color(for: seed))
            Image(systemName: "person.fill")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.9))
        }
    }

    private func color(for seed: String) -> Color {
        // simple deterministic hue (good enough for testing)
        let v = Double(abs(seed.hashValue % 360)) / 360.0
        return Color(hue: v, saturation: 0.55, brightness: 0.9)
    }
}
