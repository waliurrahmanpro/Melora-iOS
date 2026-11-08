import Foundation
import MeloraCore

#if canImport(SQLite3)
import SQLite3
#endif

/// Thread-safe SQLite database manager implementing DatabaseServiceProtocol.
///
/// Direct wrapper over Apple's native `libsqlite3` library without external heavy dependencies.
public final class SQLiteDatabase: DatabaseServiceProtocol, @unchecked Sendable {
    private let databasePath: String
    private let queue = DispatchQueue(label: "com.melora.database.queue", qos: .userInitiated)

    #if canImport(SQLite3)
    private var dbPointer: OpaquePointer?
    #endif

    /// Initializes a database connection at a specific file path or in-memory (":memory:").
    public init(databasePath: String) throws {
        self.databasePath = databasePath
        try openConnection()
        try configurePragmas()
    }

    deinit {
        closeConnection()
    }

    private func openConnection() throws {
        #if canImport(SQLite3)
        var pointer: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(databasePath, &pointer, flags, nil)
        guard result == SQLITE_OK, let validPointer = pointer else {
            let errorMsg = pointer != nil ? String(cString: sqlite3_errmsg(pointer)) : "Unable to allocate pointer"
            throw DatabaseError.connectionFailed("Failed to open SQLite database at '\(databasePath)': \(errorMsg)")
        }
        self.dbPointer = validPointer
        #else
        // Platform without SQLite3 module available (e.g. headless mock or non-Apple environment)
        #endif
    }

    private func closeConnection() {
        #if canImport(SQLite3)
        if let pointer = dbPointer {
            sqlite3_close_v2(pointer)
            self.dbPointer = nil
        }
        #endif
    }

    private func configurePragmas() throws {
        for pragma in SQLiteSchema.pragmas {
            try execute(sql: pragma, parameters: [])
        }
    }

    // MARK: - DatabaseServiceProtocol

    public func execute(sql: String, parameters: [SQLValue] = []) throws {
        try queue.sync {
            #if canImport(SQLite3)
            guard let db = dbPointer else {
                throw DatabaseError.connectionFailed("Database connection closed")
            }

            var stmt: OpaquePointer?
            let prepareResult = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
            guard prepareResult == SQLITE_OK, let statement = stmt else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.executionFailed(sql: sql, message: errorMsg)
            }
            defer { sqlite3_finalize(statement) }

            try bindParameters(parameters, to: statement)

            let stepResult = sqlite3_step(statement)
            if stepResult != SQLITE_DONE && stepResult != SQLITE_ROW {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.executionFailed(sql: sql, message: errorMsg)
            }
            #else
            throw DatabaseError.executionFailed(sql: sql, message: "SQLite3 runtime library is unavailable on this host")
            #endif
        }
    }

    public func query(sql: String, parameters: [SQLValue] = []) throws -> [SQLRow] {
        return try queue.sync {
            #if canImport(SQLite3)
            guard let db = dbPointer else {
                throw DatabaseError.connectionFailed("Database connection closed")
            }

            var stmt: OpaquePointer?
            let prepareResult = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
            guard prepareResult == SQLITE_OK, let statement = stmt else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.executionFailed(sql: sql, message: errorMsg)
            }
            defer { sqlite3_finalize(statement) }

            try bindParameters(parameters, to: statement)

            var rows: [SQLRow] = []
            let columnCount = sqlite3_column_count(statement)

            while sqlite3_step(statement) == SQLITE_ROW {
                var row: SQLRow = [:]
                for index in 0..<columnCount {
                    let colName = String(cString: sqlite3_column_name(statement, index))
                    let colType = sqlite3_column_type(statement, index)

                    switch colType {
                    case SQLITE_INTEGER:
                        let val = sqlite3_column_int64(statement, index)
                        row[colName] = .integer(val)
                    case SQLITE_FLOAT:
                        let val = sqlite3_column_double(statement, index)
                        row[colName] = .real(val)
                    case SQLITE_TEXT:
                        if let cStr = sqlite3_column_text(statement, index) {
                            row[colName] = .text(String(cString: cStr))
                        } else {
                            row[colName] = .null
                        }
                    case SQLITE_BLOB:
                        if let bytes = sqlite3_column_blob(statement, index) {
                            let byteCount = sqlite3_column_bytes(statement, index)
                            let data = Data(bytes: bytes, count: Int(byteCount))
                            row[colName] = .blob(data)
                        } else {
                            row[colName] = .null
                        }
                    case SQLITE_NULL:
                        row[colName] = .null
                    default:
                        row[colName] = .null
                    }
                }
                rows.append(row)
            }

            return rows
            #else
            throw DatabaseError.executionFailed(sql: sql, message: "SQLite3 runtime library is unavailable on this host")
            #endif
        }
    }

    public func transaction<T>(_ block: () throws -> T) throws -> T {
        try execute(sql: "BEGIN TRANSACTION;", parameters: [])
        do {
            let result = try block()
            try execute(sql: "COMMIT;", parameters: [])
            return result
        } catch {
            try? execute(sql: "ROLLBACK;", parameters: [])
            throw error
        }
    }

    public func migrate() throws {
        let version = try currentVersion()
        if version < 1 {
            try transaction {
                for statement in SQLiteSchema.version1Statements {
                    try execute(sql: statement, parameters: [])
                }
                try execute(sql: "PRAGMA user_version = 1;", parameters: [])
            }
        }
    }

    public func currentVersion() throws -> Int {
        let rows = try query(sql: "PRAGMA user_version;", parameters: [])
        if let firstRow = rows.first, let firstVal = firstRow.values.first {
            if case .integer(let v) = firstVal {
                return Int(v)
            }
        }
        return 0
    }

    #if canImport(SQLite3)
    private func bindParameters(_ parameters: [SQLValue], to statement: OpaquePointer) throws {
        for (index, param) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)
            var result: Int32 = SQLITE_OK

            switch param {
            case .null:
                result = sqlite3_bind_null(statement, bindIndex)
            case .text(let text):
                result = sqlite3_bind_text(statement, bindIndex, (text as NSString).utf8String, -1, nil)
            case .integer(let intVal):
                result = sqlite3_bind_int64(statement, bindIndex, intVal)
            case .real(let doubleVal):
                result = sqlite3_bind_double(statement, bindIndex, doubleVal)
            case .blob(let data):
                result = data.withUnsafeBytes { rawBuffer in
                    sqlite3_bind_blob(statement, bindIndex, rawBuffer.baseAddress, Int32(data.count), nil)
                }
            }

            if result != SQLITE_OK {
                throw DatabaseError.executionFailed(sql: "BIND", message: "Failed to bind parameter at index \(bindIndex)")
            }
        }
    }
    #endif
}
