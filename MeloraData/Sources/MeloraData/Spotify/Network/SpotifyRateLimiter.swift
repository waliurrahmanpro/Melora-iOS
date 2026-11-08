import Foundation

/// Coordinates request throttling and handles Spotify Web API rate limits (HTTP 429).
public actor SpotifyRateLimiter {
    private var cooldownUntil: Date?

    public init() {}

    /// Checks if the client is currently in a rate-limited cooldown period.
    public var isRateLimited: Bool {
        guard let cooldown = cooldownUntil else { return false }
        return Date() < cooldown
    }

    /// Number of seconds remaining in the current rate limit cooldown, if active.
    public var remainingCooldownSeconds: Double {
        guard let cooldown = cooldownUntil else { return 0.0 }
        return max(0.0, cooldown.timeIntervalSince(Date()))
    }

    /// Records a rate limit event extracted from a response's Retry-After header.
    public func recordRateLimit(retryAfterSeconds: Int) {
        let safeSeconds = max(1, retryAfterSeconds)
        self.cooldownUntil = Date().addingTimeInterval(TimeInterval(safeSeconds))
    }

    /// Inspects an HTTP response. If status is 429, extracts Retry-After and records the rate limit.
    public func inspectResponse(_ response: HTTPURLResponse) -> Int? {
        guard response.statusCode == 429 else { return nil }

        var retrySeconds = 5 // Default fallback
        if let retryHeader = response.value(forHTTPHeaderField: "Retry-After"),
           let parsed = Int(retryHeader) {
            retrySeconds = parsed
        }

        recordRateLimit(retryAfterSeconds: retrySeconds)
        return retrySeconds
    }

    /// Resets the active rate limiter cooldown.
    public func reset() {
        self.cooldownUntil = nil
    }

    /// Awaits any active cooldown before permitting a new request to proceed.
    public func waitForCooldownIfNeeded() async {
        let remaining = remainingCooldownSeconds
        if remaining > 0 {
            let nanoseconds = UInt64(remaining * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            reset()
        }
    }
}
