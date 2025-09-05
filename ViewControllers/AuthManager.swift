import FirebaseAuth

class AuthManager: ObservableObject {
    init() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("❌ Auth error:", error.localizedDescription)
                } else {
                    print("✅ Signed in with UID:", result?.user.uid ?? "")
                }
            }
        }
    }
}
