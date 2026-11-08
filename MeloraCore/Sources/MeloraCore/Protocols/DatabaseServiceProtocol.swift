import Foundation

/// Primitive SQL query parameters supported across SQLite statements.
public enum SQLValue: Equatable, Sendable {
    case null
    case text(String)
    case integer(Int64)
    case real(Double)
    case blob(Data)

    public var rawValue: Any? {
        switch self {
        case .null: return nil
        case .text(let str): return str
        case .integer(let val): return val
        case .real(let val): return val
        case .blob(let data): return data
        }
    }
}

/// Key-value representation of an extracted SQLite row.
public typealias SQLRow = [String: SQLValue]

/// Common errors encountered during database interactions.
public enum DatabaseError: Error, LocalizedError, Equatable, Sendable {
    case connectionFailed(String)
    case executionFailed(sql: String, message: String)
    case migrationFailed(version: Int, message: String)
    case recordNotFound(table: String, identifier: String)
    case constraintViolation(message: String)
    case transactionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg):
            return "SQLite Connection Error: \(msg)"
        case .executionFailed(let sql, let msg):
            return "SQLite Execution Error: \(msg) [SQL: \(sql)]"
        case .migrationFailed(let ver, let msg):
            return "SQLite Migration Error at version \(ver): \(msg)"
        case .recordNotFound(let tbl, let id):
            return "Record not found in '\(tbl)' with ID: \(id)"
        case .constraintViolation(let msg):
            return "SQLite Constraint Violation: \(msg)"
        case .transactionFailed(let msg):
            return "SQLite Transaction Failed: \(msg)"
        }
    }
}

/// Abstract contract for low-level SQLite database services.
public protocol DatabaseServiceProtocol: AnyObject, Sendable {
    /// Executes a SQL statement (e.g. INSERT, UPDATE, DELETE, CREATE TABLE) with bound parameters.
    func execute(sql: String, parameters: [SQLValue]) throws

    /// Executes a SELECT query with bound parameters and returns an array of row dictionaries.
    func query(sql: String, parameters: [SQLValue]) throws -> [SQLRow]

    /// Executes a block of database operations within an isolated SQLite transaction.
    func transaction<T>(_ block: () throws -> T) throws -> T

    /// Applies pending schema migrations.
    func migrate() throws

    /// Returns the active schema version stored in the database `user_version` pragma.
    func currentVersion() throws -> Int
}
