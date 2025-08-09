import Foundation

// MARK: - Google Tasks Data Models

struct GTaskList: Codable, Identifiable {
    var id: String
    var title: String
    var updated: Date?
    var etag: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, updated, etag
    }
}

struct GTask: Codable, Identifiable {
    var id: String
    var title: String?
    var notes: String?
    var due: Date?
    var status: String?      // needsAction | completed
    var parent: String?
    var position: String?
    var updated: Date?
    var deleted: Bool?
    var etag: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, notes, due, status, parent, position, updated, deleted, etag
    }
}

// MARK: - API Response Models

struct TaskListsResponse: Codable {
    let kind: String
    let etag: String?
    let nextPageToken: String?
    let items: [GTaskList]?
}

struct TasksResponse: Codable {
    let kind: String
    let etag: String?
    let nextPageToken: String?
    let items: [GTask]?
}

// MARK: - API Error Types

enum GoogleTasksAPIError: LocalizedError {
    case invalidURL
    case noAccessToken
    case networkError(Error)
    case invalidResponse
    case authenticationRequired
    case rateLimited
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noAccessToken:
            return "No valid access token available"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Google Tasks API"
        case .authenticationRequired:
            return "Authentication required"
        case .rateLimited:
            return "API rate limit exceeded"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

// MARK: - Google Tasks API Client

final class GoogleTasksAPI {
    static let shared = GoogleTasksAPI()
    
    private let baseURL = URL(string: "https://www.googleapis.com/tasks/v1")!
    private let session = URLSession.shared
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private init() {}
    
    // MARK: - Task Lists API
    
    func listTaskLists(updatedMin: Date? = nil, pageToken: String? = nil, token: String) async throws -> ([GTaskList], String?) {
        var components = URLComponents(url: baseURL.appendingPathComponent("users/@me/lists"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = []
        if let updatedMin = updatedMin {
            queryItems.append(URLQueryItem(name: "updatedMin", value: dateFormatter.string(from: updatedMin)))
        }
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        queryItems.append(URLQueryItem(name: "maxResults", value: "100"))
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw GoogleTasksAPIError.invalidURL
        }
        
        let request = authorizedRequest(for: url, token: token)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let dateFormatter = self.dateFormatter
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        
        let apiResponse = try decoder.decode(TaskListsResponse.self, from: data)
        return (apiResponse.items ?? [], apiResponse.nextPageToken)
    }
    
    func createTaskList(title: String, token: String) async throws -> GTaskList {
        let url = baseURL.appendingPathComponent("users/@me/lists")
        var request = authorizedRequest(for: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let taskList = GTaskList(id: "", title: title, updated: nil, etag: nil)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(taskList)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GTaskList.self, from: data)
    }
    
    func updateTaskList(listId: String, title: String, token: String, ifMatch: String? = nil) async throws -> GTaskList {
        let url = baseURL.appendingPathComponent("users/@me/lists/\(listId)")
        var request = authorizedRequest(for: url, token: token)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let ifMatch = ifMatch {
            request.setValue(ifMatch, forHTTPHeaderField: "If-Match")
        }
        
        let taskList = GTaskList(id: listId, title: title, updated: nil, etag: nil)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(taskList)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GTaskList.self, from: data)
    }
    
    func deleteTaskList(listId: String, token: String) async throws {
        let url = baseURL.appendingPathComponent("users/@me/lists/\(listId)")
        var request = authorizedRequest(for: url, token: token)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Tasks API
    
    func listTasks(listId: String, updatedMin: Date? = nil, pageToken: String? = nil, showCompleted: Bool = true, showDeleted: Bool = false, token: String) async throws -> ([GTask], String?) {
        var components = URLComponents(url: baseURL.appendingPathComponent("lists/\(listId)/tasks"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "maxResults", value: "100"),
            URLQueryItem(name: "showCompleted", value: showCompleted ? "true" : "false"),
            URLQueryItem(name: "showDeleted", value: showDeleted ? "true" : "false"),
            URLQueryItem(name: "showHidden", value: "true")
        ]
        
        if let updatedMin = updatedMin {
            queryItems.append(URLQueryItem(name: "updatedMin", value: dateFormatter.string(from: updatedMin)))
        }
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw GoogleTasksAPIError.invalidURL
        }
        
        let request = authorizedRequest(for: url, token: token)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let dateFormatter = self.dateFormatter
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        
        let apiResponse = try decoder.decode(TasksResponse.self, from: data)
        return (apiResponse.items ?? [], apiResponse.nextPageToken)
    }
    
    func insertTask(listId: String, task: GTask, parent: String? = nil, previous: String? = nil, token: String) async throws -> GTask {
        var components = URLComponents(url: baseURL.appendingPathComponent("lists/\(listId)/tasks"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = []
        if let parent = parent {
            queryItems.append(URLQueryItem(name: "parent", value: parent))
        }
        if let previous = previous {
            queryItems.append(URLQueryItem(name: "previous", value: previous))
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw GoogleTasksAPIError.invalidURL
        }
        
        var request = authorizedRequest(for: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let dateFormatter = self.dateFormatter
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let container = encoder.singleValueContainer()
            try container.encode(dateFormatter.string(from: date))
        }
        request.httpBody = try encoder.encode(task)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let dateFormatter = self.dateFormatter
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        
        return try decoder.decode(GTask.self, from: data)
    }
    
    func updateTask(listId: String, taskId: String, task: GTask, token: String, ifMatch: String? = nil) async throws -> GTask {
        let url = baseURL.appendingPathComponent("lists/\(listId)/tasks/\(taskId)")
        var request = authorizedRequest(for: url, token: token)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let ifMatch = ifMatch {
            request.setValue(ifMatch, forHTTPHeaderField: "If-Match")
        }
        
        let encoder = JSONEncoder()
        let dateFormatter = self.dateFormatter
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let container = encoder.singleValueContainer()
            try container.encode(dateFormatter.string(from: date))
        }
        request.httpBody = try encoder.encode(task)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        
        return try decoder.decode(GTask.self, from: data)
    }
    
    func moveTask(listId: String, taskId: String, parent: String? = nil, previous: String? = nil, token: String) async throws -> GTask {
        var components = URLComponents(url: baseURL.appendingPathComponent("lists/\(listId)/tasks/\(taskId)/move"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = []
        if let parent = parent {
            queryItems.append(URLQueryItem(name: "parent", value: parent))
        }
        if let previous = previous {
            queryItems.append(URLQueryItem(name: "previous", value: previous))
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw GoogleTasksAPIError.invalidURL
        }
        
        var request = authorizedRequest(for: url, token: token)
        request.httpMethod = "POST"
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let dateFormatter = self.dateFormatter
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        
        return try decoder.decode(GTask.self, from: data)
    }
    
    func deleteTask(listId: String, taskId: String, token: String) async throws {
        let url = baseURL.appendingPathComponent("lists/\(listId)/tasks/\(taskId)")
        var request = authorizedRequest(for: url, token: token)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Helper Methods
    
    private func authorizedRequest(for url: URL, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleTasksAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw GoogleTasksAPIError.authenticationRequired
        case 429:
            throw GoogleTasksAPIError.rateLimited
        case 400...499:
            throw GoogleTasksAPIError.invalidResponse
        case 500...599:
            throw GoogleTasksAPIError.serverError(httpResponse.statusCode)
        default:
            throw GoogleTasksAPIError.invalidResponse
        }
    }
}