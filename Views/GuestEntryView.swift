import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import FirebaseStorage
// import FirebaseStorage
struct GuestEntryView: View {
    @State private var displayName = ""
    @State private var roomCode = ""
    @State private var generatedCode: String?
    @State private var isHosting: Bool? = nil  // nil = undecided
    @State private var navigateToLobby = false
    @StateObject private var gameRoomManager = GameRoomManager()
    @State private var showCamera = false
    @State private var avatarImage: UIImage?
    @State private var showAlert: Bool = false
    let db = Firestore.firestore()
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1F1D36"), Color(hex: "#9B5DE5")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
                NavigationLink(
                    destination: Group {
                        if let code = generatedCode {
                            LobbyView(
                                roomCode: code,
                                displayName: displayName,
                                isHost: isHosting ?? false
                            )
                        }
                        else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(get: {navigateToLobby && generatedCode != nil}, set: {navigateToLobby = $0})
                ) {
                    EmptyView()
                }
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
                            
                            if displayName == "" {
                                showAlert = true
                            }
                            guard !displayName.isEmpty else { return }

                            let code = generateRoomCode()
                            generatedCode = code
                            print("code is \(code), name is \(displayName)")
                            guard let generatedCode = generatedCode else {
                                print("room code is not generated")
                                return
                            }
                            
                            // create the room first in the firebase
                            db.collection("gameRooms").document(generatedCode).setData([
                                "createdAt": Timestamp(),
                                "hostId": Auth.auth().currentUser?.uid ?? "noId", 
                                "showFunFactSheet": false
                            ]) { error in
                                print("Error is happening in the initial creation of the room")
                            }
                            
                            
                            
                            // ⬇️ Upload avatar, then add the player with avatarURL
                                uploadAvatarIfAvailable(avatarImage, roomCode: generatedCode) { avatarURL in
                                    gameRoomManager.addPlayer(
                                        to: generatedCode,
                                        name: displayName,
                                        isHost: true,
                                        avatarURL: avatarURL
                                    ) { success in
                                        if success {
                                            DispatchQueue.main.async { navigateToLobby = true }
                                        } else {
                                            print("❌ Failed to host")
                                        }
                                    }
                                }
                        }



                        GlassActionButton(title: "Join Room", icon: "arrow.right.circle.fill") {
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
                            guard !displayName.isEmpty, !roomCode.isEmpty else { return }
                            
//                            // authenticating before joining
//                            print("name is \(displayName) and room code is \(roomCode)")
//                            if Auth.auth().currentUser == nil {
//                                Auth.auth().signInAnonymously { result, error in
//                                    if let error = error {
//                                        print("Error: ", error.localizedDescription)
//                                        return
//                                    } else {
//                                        print("Signed in as user: ", result?.user.uid ?? "Anonymous")
//                                    }
//                                }
//                            }
//                            // the end of authentication
                            
                            // check if the room already exists
                            
                            let roomRef = db.collection("gameRooms").document(roomCode)
                            roomRef.getDocument { docSnapShot, error in
                                if let error = error {
                                    print("there is an error retrieving the room number")
                                    return
                                }
                                
                                guard let doc = docSnapShot, doc.exists else {
                                    print("there is no room with this number")
                                    return
                                }
                                
                                // room exists → upload avatar then join
                                uploadAvatarIfAvailable(avatarImage, roomCode: roomCode) { avatarURL in
                                    gameRoomManager.addPlayer(
                                        to: roomCode,
                                        name: displayName,
                                        isHost: false,
                                        avatarURL: avatarURL
                                    ) { success in
                                        if success {
                                            DispatchQueue.main.async {
                                                generatedCode = roomCode
                                                navigateToLobby = true
                                            }
                                        } else {
                                            print("❌ Failed to join room")
                                        }
                                    }
                                }

                            }
                            
                            
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
            
            // add this overlay to add the photo to the top right
            .overlay(alignment: .topTrailing) {
                SelfieBubble(image: $avatarImage)
                    .offset(x: 22, y: -22)   // nudge outside the corner
                    .onTapGesture {
                        showCamera = true
                    }
            }
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 30)
            
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $avatarImage) { img in
                    avatarImage = img
                }
                .ignoresSafeArea()
            }


        }
        .alert("Important Requirement", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text("Please enter your display name")
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

import UIKit

struct SelfieBubble: View {
    @Binding var image: UIImage?

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 84, height: 84)
                    .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)

                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            Text(image == nil ? "Take Selfie" : "Change")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.12), in: Capsule())
        }
        .padding(4)
        .contentShape(Rectangle()) // whole bubble tappable later
        // .onTapGesture { /* hook up camera later */ }
    }
}


import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                picker.cameraDevice = .front
            }
            picker.cameraCaptureMode = .photo
            picker.showsCameraControls = true
        } else {
            // Simulator or no camera -> allow picking from library
            picker.sourceType = .photoLibrary
        }

        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = (info[.originalImage] as? UIImage) {
                parent.image = img
                parent.onCapture(img)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

/// Ensure we have a Firebase user (anonymous is fine). Returns the uid.
func ensureAuth(_ completion: @escaping (String?) -> Void) {
    if let uid = Auth.auth().currentUser?.uid {
        completion(uid); return
    }
    Auth.auth().signInAnonymously { result, error in
        if let error = error {
            print("Auth error: \(error.localizedDescription)")
            completion(nil)
        } else {
            completion(result?.user.uid)
        }
    }
}

func uploadAvatarIfAvailable(_ image: UIImage?, roomCode: String, completion: @escaping (String?) -> Void) {
    guard let image = image, let data = image.jpegData(compressionQuality: 0.85) else {
        print("🟡 no image, skip upload"); completion(nil); return
    }

    // ✅ sanitize roomCode just in case
    let safeRoom = roomCode.replacingOccurrences(of: "/", with: "_")

    ensureAuth { uid in
        guard let uid = uid else { completion(nil); return }

        let storage = Storage.storage(url: "gs://who-s-da-boss-7f05a.firebasestorage.app") // 👈 explicit bucket
        let filename = "\(uid)_\(UUID().uuidString).jpg"
        let ref = storage.reference().child("gameRooms/\(safeRoom)/avatars/\(filename)")

        let meta = StorageMetadata(); meta.contentType = "image/jpeg"
        print("⬆️ putData to:", ref.fullPath)

        ref.putData(data, metadata: meta) { meta, error in
            if let error = error as NSError? {
                print("❌ putData error:", error.localizedDescription,
                      "code=\(error.code) domain=\(error.domain) userInfo=\(error.userInfo)")
                completion(nil); return
            }
            print("✅ putData ok, size:", meta?.size ?? 0)

            ref.downloadURL { url, err in
                if let err = err {
                    print("❌ downloadURL:", err.localizedDescription)
                    completion(nil); return
                }
                let s = url?.absoluteString
                print("🌐 downloadURL:", s ?? "nil")
                completion(s)
            }
        }
    }
}

