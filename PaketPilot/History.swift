import SwiftUI

struct HistoryView: View {
    @ObservedObject var firestoreService: FirestoreService
    @State private var qrDataList: [QRData] = []
    @State private var savedQRCodeContents: [String] = []
    @State private var showAlert = false
    @State private var confirmDeleteAll = false
    @State private var contentToDelete: String?
    @State private var qrDataToDelete: QRData?

    var body: some View {
        VStack {
            List {
                ForEach(savedQRCodeContents, id: \.self) { content in
                    HStack {
                        Text(content)
                            .padding()
                        Spacer()
                        Button(action: {
                            contentToDelete = content
                            qrDataToDelete = nil
                            showAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }

                ForEach(qrDataList) { qrData in
                    VStack(alignment: .leading) {
                        Text("Gönderilen Şehir: \(qrData.gönderilenSehir)")
                        Text("Gideceği Şehir: \(qrData.gidecegiSehir)")
                        Text("Tür: \(qrData.tur)")
                        Text("Adet: \(qrData.adet)")
                    }
                    .padding(.vertical)
                    HStack {
                        Spacer()
                        Button(action: {
                            qrDataToDelete = qrData
                            contentToDelete = nil
                            showAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Paket Takip")
            Button(action: {
                confirmDeleteAll = true
            }) {
                Text("Tüm Verileri Sil")
                    .foregroundColor(.red)
                    .padding()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Veriyi silmek istediğinize emin misiniz?"),
                    primaryButton: .destructive(Text("Evet")) {
                        if let content = contentToDelete {
                            deleteContent(content)
                        } else if let qrData = qrDataToDelete {
                            deleteQRData(qrData)
                        }
                    },
                    secondaryButton: .destructive(Text("Hayır").foregroundColor(.blue))
                )
            }
            .alert(isPresented: $confirmDeleteAll) {
                Alert(
                    title: Text("Tüm verileri silmek istediğinize emin misiniz?"),
                    primaryButton: .destructive(Text("Evet")) {
                        clearAllData()
                    },
                    secondaryButton: .cancel(Text("Hayır"))
                )
            }
        }
        .onAppear {
            fetchQRData()
            loadQRCodeContents()
        }
    }

    private func fetchQRData() {
        firestoreService.fetchData { result in
            switch result {
            case .success(let data):
                print("Data fetched successfully: \(data)")
                qrDataList = data
            case .failure(let error):
                print("Error fetching data: \(error.localizedDescription)")
            }
        }
    }

    private func loadQRCodeContents() {
        savedQRCodeContents = UserDefaults.standard.stringArray(forKey: "savedQRCodeContents") ?? []
        print("Loaded QR code contents: \(savedQRCodeContents)")
    }

    private func clearStoredQRCodeContents() {
        UserDefaults.standard.removeObject(forKey: "savedQRCodeContents")
        savedQRCodeContents.removeAll()
        print("Stored QR code contents cleared.")
    }

    private func clearFirestoreData(completion: @escaping (Bool) -> Void) {
        firestoreService.deleteAllData { result in
            switch result {
            case .success():
                print("All Firestore data cleared.")
                qrDataList.removeAll()
                completion(true)
            case .failure(let error):
                print("Error clearing Firestore data: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    private func clearAllData() {
        clearFirestoreData { success in
            if success {
                clearStoredQRCodeContents()
            } else {
                print("Failed to clear Firestore data")
            }
        }
    }

    private func deleteContent(_ content: String) {
        if let index = savedQRCodeContents.firstIndex(of: content) {
            savedQRCodeContents.remove(at: index)
            UserDefaults.standard.set(savedQRCodeContents, forKey: "savedQRCodeContents")
            print("Deleted content: \(content)")
        }
    }

    private func deleteQRData(_ qrData: QRData) {
        if let id = qrData.id {
            firestoreService.deleteData(documentID: id) { result in
                switch result {
                case .success():
                    print("Deleted Firestore data: \(id)")
                    qrDataList.removeAll { $0.id == id }
                case .failure(let error):
                    print("Error deleting Firestore data: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    HistoryView(firestoreService: FirestoreService())
}
