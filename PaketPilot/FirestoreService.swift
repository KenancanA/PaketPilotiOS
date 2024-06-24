import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct QRData: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    var gönderilenSehir: String
    var gidecegiSehir: String
    var tur: String
    var adet: String
}

class FirestoreService: ObservableObject {
    private var db = Firestore.firestore()

    func saveData(qrData: QRData, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("qrData").addDocument(from: qrData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    func fetchData(completion: @escaping (Result<[QRData], Error>) -> Void) {
        db.collection("qrData").order(by: "id", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                let data = documents.compactMap { doc -> QRData? in
                    return try? doc.data(as: QRData.self)
                }
                print("Fetched data: \(data)")
                completion(.success(data))
            }
        }
    }

    func deleteData(documentID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("qrData").document(documentID).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func deleteAllData(completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("qrData").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let batch = self.db.batch()
            snapshot?.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
