import Foundation
import SwiftData

/// Navigation routes for the macOS detail NavigationStack.
/// We route by SwiftData `PersistentIdentifier` so that the path is Hashable
/// and we can resolve models from the shared `ModelContext`.
enum AppRoute: Hashable {
    case project(PersistentIdentifier)
    case projectEntries(PersistentIdentifier)
    case entry(PersistentIdentifier)
    case commitment(PersistentIdentifier)
    case reflection(PersistentIdentifier)
    case person(PersistentIdentifier)
    /// New periodic reflection creation (e.g. weekly reflection flow)
    case newPeriodicReflection(ReflectionPeriodType)
}


