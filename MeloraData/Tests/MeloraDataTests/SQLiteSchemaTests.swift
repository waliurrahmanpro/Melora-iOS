import Foundation
import Testing
@testable import MeloraCore
@testable import MeloraData

@Suite("MeloraData SQLite Schema Tests")
struct SQLiteSchemaTests {

    @Test("Verify schema version and DDL definitions")
    func testSchemaDefinitions() {
        #expect(SQLiteSchema.currentVersion == 1)
        #expect(!SQLiteSchema.pragmas.isEmpty)
        #expect(!SQLiteSchema.version1Statements.isEmpty)

        // Verify all core tables exist in DDL statements
        let combined = SQLiteSchema.version1Statements.joined(separator: "\n")
        #expect(combined.contains("CREATE TABLE IF NOT EXISTS tracks"))
        #expect(combined.contains("CREATE TABLE IF NOT EXISTS artists"))
        #expect(combined.contains("CREATE TABLE IF NOT EXISTS albums"))
        #expect(combined.contains("CREATE TABLE IF NOT EXISTS playlists"))
        #expect(combined.contains("CREATE TABLE IF NOT EXISTS playlist_tracks"))
        #expect(combined.contains("CREATE TABLE IF NOT EXISTS playback_history"))
        #expect(combined.contains("CREATE INDEX IF NOT EXISTS idx_tracks_title"))
        #expect(combined.contains("CREATE INDEX IF NOT EXISTS idx_playlist_tracks_pos"))
    }
}
