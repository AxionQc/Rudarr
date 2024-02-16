import Foundation

enum ValidationError: Error {
    case urlNotValid
    case urlNotReachable(_ error: Error)
    case badAppName(_ name: String)
    case badStatusCode(_ code: Int)
    case badResponse(_ error: Error)
    case errorResponse(_ code: Int, _ message: String)
}

extension ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .urlNotValid:
            return "Invalid URL"
        case .urlNotReachable:
            return "URL Not Reachable"
        case .badAppName:
            return "Wrong Instance Type"
        case .badStatusCode:
            return "Invalid Status Code"
        case .badResponse:
            return "Invalid Server Response"
        case .errorResponse:
            return "Server Error Response"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .urlNotValid:
            return "Enter a valid URL."
        case .urlNotReachable(let error):
            return error.localizedDescription
        case .badAppName(let name):
            return "URL returned a \(name) instance."
        case .badStatusCode(let code):
            return "URL returned status \(code)."
        case .badResponse(let error):
            return error.localizedDescription
        case .errorResponse(let code, let message):
            return "[\(code)] \(message)"
        }
    }
}