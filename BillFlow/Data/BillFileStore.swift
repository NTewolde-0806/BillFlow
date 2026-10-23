import Foundation

/// Serializes file operations away from the main actor. Only bytes cross this boundary.
actor BillFileStore {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func readOrCreate(initialData: Data) throws -> Data {
        try Task.checkCancellation()
        do {
            return try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            // Only a missing file is a first launch. Other errors must reach the UI.
            try write(initialData)
            return initialData
        }
    }

    func write(_ data: Data) throws {
        try Task.checkCancellation()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        // Atomic replacement avoids leaving a partially written JSON file.
        try data.write(to: fileURL, options: .atomic)
    }
}
