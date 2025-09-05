import Foundation
import FirebaseFirestore
import FirebaseAuth

class GameRoomManager: ObservableObject {
    let db = Firestore.firestore()
    @Published var funFacts: [funFact] = []
    @Published var players: [Player] = []
    
//    func storeFunFacts(in roomCode: String, userID: String) {
//        db.collection("gameRooms")
//            .document(roomCode)
//            .collection("players")
//            .document(userID)
//    }
    
    func calculateWinner(in roomCode: String) async throws -> [String]{
        let snap = try await db.collection("gameRooms")
            .document(roomCode)
            .collection("players")
            .order(by: "totalPoints", descending: true)
            .getDocuments()
        
        let docs = snap.documents
        guard let first = docs.first else { return [] }
        
        let topScore = (first.data()["totalPoints"] as? Int) ?? 0
        
        let winners = docs
            .filter { ($0.data()["totalPoints"] as? Int ?? 0) == topScore}
            .map { $0.data()["id"] as? String ?? $0.documentID }
        return winners
    }
    
    func increasePoint(in roomCode: String, userID: String) {
        db.collection("gameRooms")
            .document(roomCode)
            .collection("players")
            .document(userID)
            .updateData(["totalPoints": FieldValue.increment(Int64(1))]) { err in
                if let err = err {
                    print("there is this \(err)")
                }
            }
    }

    func listenToPlayers(in roomCode: String) {
        db.collection("gameRooms")
            .document(roomCode)
            .collection("players")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self.players = documents.compactMap { doc in
                        let data = doc.data()
                        let name = data["name"] as? String ?? "Unknown"
                        let id = doc.documentID
                        let funFact = data["funFact"] as? String ?? "Empty"
                        let avatarULR = data["avatarURL"] as? String ?? "Empty"
                        return Player(id: id, name: name, funFact: funFact, avatarURL: avatarULR)
                    }
                }
            }
    }
    
    func submitFunFact(to roomCode: String, funfact: String) {
        // getting userId
        guard let userId = Auth.auth().currentUser?.uid else {
            print("cannot access userId")
            return
        }
        db.collection("gameRooms")
            .document(roomCode)
            .collection("players")
            .document(userId)
            .updateData(["funFact": funfact]) { error in
                if let error = error {
                    print("❌ Failed to add the fun fact: \(error.localizedDescription)")
                    return
                } else {
                    print("✅ Fun Fact is added")
                    return
                }
            }
    }

    func addPlayer(to roomCode: String, name: String, isHost: Bool = false, avatarURL: String?, completion: @escaping (Bool) -> Void) {
        
        print("player is being added to the room")
        print("🧪 Current User ID:", Auth.auth().currentUser?.uid ?? "nil")

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let playerData: [String: Any] = [
            "uid": userId,
            "name": name,
            "isHost": isHost,
            "avatarURL": avatarURL as Any,
            "joinedAt": Timestamp()
        ]
        print(playerData)
        
        print("player is being added to the room")
        print(playerData, " has the id of ", userId, " and is in the room \(roomCode)")
        db.collection("gameRooms")
            .document(roomCode)
            .collection("players")
            .document(userId)
            .setData(playerData, merge: true) { error in
                if let error = error {
                    print("❌ Failed to add player: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Player added to room \(roomCode)")
                    completion(true)
                }
            }
    }
}
