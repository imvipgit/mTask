import Foundation
import Security
import AuthenticationServices

// MARK: - OAuth Configuration

struct OAuthConfig {
    static let clientId = "YOUR_GOOGLE_CLIENT_ID" // Replace with your actual client ID
    static let scope = "https://www.googleapis.com/auth/tasks"
    static let redirectURI = "com.mtask.app://oauth"
    static let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    static let tokenURL = "https://oauth2.googleapis.com/token"
}

// MARK: - Token Storage

struct TokenStore {
    private let accessTokenKey = "mTask_access_token"
    private let refreshTokenKey = "mTask_refresh_token"
    private let expiresAtKey = "mTask_expires_at"
    
    func saveTokens(accessToken: String, refreshToken: String?, expiresIn: Int) {
        saveToKeychain(key: accessTokenKey, value: accessToken)
        
        if let refreshToken = refreshToken {
            saveToKeychain(key: refreshTokenKey, value: refreshToken)
        }
        
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        UserDefaults.standard.set(expiresAt, forKey: expiresAtKey)
    }
    
    func getAccessToken() -> String? {
        return getFromKeychain(key: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return getFromKeychain(key: refreshTokenKey)
    }
    
    func isTokenExpired() -> Bool {
        guard let expiresAt = UserDefaults.standard.object(forKey: expiresAtKey) as? Date else {
            return true
        }
        return Date() >= expiresAt.addingTimeInterval(-300) // Refresh 5 minutes early
    }
    
    func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: expiresAtKey)
    }
    
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - OAuth Response Models

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

// MARK: - Auth Manager

final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var isAuthenticating: Bool = false
    @Published var authError: String?
    
    private let tokenStore = TokenStore()
    private var authSession: ASWebAuthenticationSession?
    
    private init() {
        checkExistingAuth()
    }
    
    // MARK: - Public Methods
    
    func signIn() {
        guard !isAuthenticating else { return }
        
        isAuthenticating = true
        authError = nil
        
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state = UUID().uuidString
        
        var components = URLComponents(string: OAuthConfig.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: OAuthConfig.clientId),
            URLQueryItem(name: "redirect_uri", value: OAuthConfig.redirectURI),
            URLQueryItem(name: "scope", value: OAuthConfig.scope),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        guard let authURL = components.url else {
            handleAuthError("Failed to create authorization URL")
            return
        }
        
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "com.mtask.app"
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.handleAuthCallback(
                    callbackURL: callbackURL,
                    error: error,
                    codeVerifier: codeVerifier,
                    expectedState: state
                )
            }
        }
        
        authSession?.presentationContextProvider = AuthPresentationContextProvider()
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }
    
    func signOut() {
        tokenStore.clearTokens()
        isSignedIn = false
        authError = nil
    }
    
    func withAccessToken(_ block: @escaping (Result<String, Error>) -> Void) {
        guard isSignedIn else {
            block(.failure(GoogleTasksAPIError.noAccessToken))
            return
        }
        
        if let accessToken = tokenStore.getAccessToken(), !tokenStore.isTokenExpired() {
            block(.success(accessToken))
            return
        }
        
        // Try to refresh the token
        refreshAccessToken { [weak self] success in
            if success, let accessToken = self?.tokenStore.getAccessToken() {
                block(.success(accessToken))
            } else {
                block(.failure(GoogleTasksAPIError.authenticationRequired))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func checkExistingAuth() {
        if let _ = tokenStore.getAccessToken() {
            if !tokenStore.isTokenExpired() {
                isSignedIn = true
            } else {
                // Try to refresh
                refreshAccessToken { [weak self] success in
                    DispatchQueue.main.async {
                        self?.isSignedIn = success
                    }
                }
            }
        }
    }
    
    private func handleAuthCallback(callbackURL: URL?, error: Error?, codeVerifier: String, expectedState: String) {
        isAuthenticating = false
        
        if let error = error {
            handleAuthError("Authentication failed: \(error.localizedDescription)")
            return
        }
        
        guard let callbackURL = callbackURL,
              let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            handleAuthError("Invalid callback URL")
            return
        }
        
        // Check for error in callback
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            handleAuthError("OAuth error: \(error)")
            return
        }
        
        // Verify state
        guard let state = queryItems.first(where: { $0.name == "state" })?.value,
              state == expectedState else {
            handleAuthError("Invalid state parameter")
            return
        }
        
        // Get authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            handleAuthError("No authorization code received")
            return
        }
        
        // Exchange code for tokens
        exchangeCodeForTokens(code: code, codeVerifier: codeVerifier)
    }
    
    private func exchangeCodeForTokens(code: String, codeVerifier: String) {
        var request = URLRequest(url: URL(string: OAuthConfig.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": OAuthConfig.clientId,
            "code": code,
            "code_verifier": codeVerifier,
            "grant_type": "authorization_code",
            "redirect_uri": OAuthConfig.redirectURI
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleTokenResponse(data: data, response: response, error: error)
            }
        }.resume()
    }
    
    private func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = tokenStore.getRefreshToken() else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: URL(string: OAuthConfig.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": OAuthConfig.clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                let success = self?.handleTokenResponse(data: data, response: response, error: error) ?? false
                completion(success)
            }
        }.resume()
    }
    
    @discardableResult
    private func handleTokenResponse(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        if let error = error {
            handleAuthError("Token exchange failed: \(error.localizedDescription)")
            return false
        }
        
        guard let data = data else {
            handleAuthError("No data received from token endpoint")
            return false
        }
        
        do {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            tokenStore.saveTokens(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                expiresIn: tokenResponse.expiresIn
            )
            isSignedIn = true
            authError = nil
            return true
        } catch {
            handleAuthError("Failed to parse token response: \(error.localizedDescription)")
            return false
        }
    }
    
    private func handleAuthError(_ message: String) {
        authError = message
        isSignedIn = false
        isAuthenticating = false
    }
    
    // MARK: - PKCE Helpers
    
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = verifier.data(using: .utf8)!
        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            CC_SHA256($0.bindMemory(to: UInt8.self).baseAddress, CC_LONG(data.count), &buffer)
        }
        return Data(buffer).base64URLEncodedString()
    }
}

// MARK: - Extensions

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// Import CommonCrypto for SHA256
import CommonCrypto

// MARK: - Presentation Context Provider

class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}