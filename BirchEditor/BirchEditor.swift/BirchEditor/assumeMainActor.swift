//
//  assumeMainActor.swift
//  BirchEditor
//

import Foundation

/// Runs `body` on the main actor after asserting at runtime that the caller
/// is already executing on the main thread — like `MainActor.assumeIsolated`,
/// but usable from nonisolated overrides and deinits of main-actor classes,
/// where region analysis rejects capturing non-Sendable `self`.
///
/// Safety: the body executes synchronously on the current thread, and
/// `MainActor.assumeIsolated` traps first if that thread is not the main
/// thread, so laundering the closure's captures cannot introduce a data race.
func assumeMainActor<T: Sendable>(_ body: @MainActor () throws -> T) rethrows -> T {
    nonisolated(unsafe) let body = body
    return try MainActor.assumeIsolated { try body() }
}
