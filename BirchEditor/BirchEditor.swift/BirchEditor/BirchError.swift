import Foundation

public enum BirchError: Error {
    case runtimeError(String)
}

extension BirchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .runtimeError(let string):
            return string
        }
    }
}
