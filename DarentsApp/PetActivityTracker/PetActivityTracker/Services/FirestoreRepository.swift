import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// A generic repository for performing CRUD operations on `Codable` models in Firestore.
final class FirestoreRepository<Model: Codable & Identifiable> where Model.ID == String {

    private let collection: CollectionReference

    /// Initializes a new repository for the given collection.
    /// - Parameter collectionName: The name of the Firestore collection.
    init(collectionName: String) {
        self.collection = Firestore.firestore().collection(collectionName)
    }

    /// Fetches a single document by its ID.
    /// - Parameter id: The ID of the document to fetch.
    /// - Returns: The decoded model, or `nil` if it doesn't exist.
    func get(id: String) async throws -> Model? {
        let document = try await collection.document(id).getDocument()
        return try document.data(as: Model.self)
    }

    /// Fetches all documents from the collection.
    /// - Returns: An array of decoded models.
    func getAll() async throws -> [Model] {
        let snapshot = try await collection.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Model.self) }
    }

    /// Fetches multiple documents by their IDs.
    /// - Parameter ids: An array of document IDs to fetch.
    /// - Returns: An array of decoded models.
    func get(ids: [String]) async throws -> [Model] {
        guard !ids.isEmpty else { return [] }

        var results: [Model] = []
        let chunks = ids.chunked(into: 30)

        for chunk in chunks {
            let snapshot = try await collection.whereField(FieldPath.documentID(), in: chunk).getDocuments()
            let models = try snapshot.documents.compactMap { try $0.data(as: Model.self) }
            results.append(contentsOf: models)
        }

        return results
    }

    /// Creates a new document in the collection.
    /// - Parameter model: The model to create.
    /// - Returns: The created model with its new ID.
    func create(_ model: Model) async throws -> Model {
        var mutableModel = model
        let documentRef = collection.document()
        mutableModel.id = documentRef.documentID
        try documentRef.setData(from: mutableModel)
        return mutableModel
    }

    /// Updates an existing document.
    /// - Parameter model: The model to update.
    func update(_ model: Model) async throws {
        guard let id = model.id else {
            throw NSError(domain: "FirestoreRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model must have an ID to be updated."])
        }
        try collection.document(id).setData(from: model, merge: true)
    }

    /// Deletes a document.
    /// - Parameter model: The model to delete.
    func delete(_ model: Model) async throws {
        guard let id = model.id else {
            throw NSError(domain: "FirestoreRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model must have an ID to be deleted."])
        }
        try await collection.document(id).delete()
    }
}

extension Array {
    /// Splits an array into chunks of a given size.
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
