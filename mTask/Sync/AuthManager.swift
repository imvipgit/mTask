import Foundation

final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var isSignedIn: Bool = false

    // TODO: Implement OAuth 2.0 with AppAuth (SPM)
    func signIn() {
        // Launch OAuth flow, store tokens securely in Keychain.
        isSignedIn = true
    }

    func signOut() {
        // Clear tokens
        isSignedIn = false
    }

    func withAccessToken(_ block: (String) -> Void) {
        // Supply a valid token if signed in.
    }
}