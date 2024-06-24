import SwiftUI
import UIKit

struct ContentView: View {
    
    @State private var gönderilenSehir = ""
    @State private var gidecegiSehir = ""
    @State private var tur = ""
    @State private var adet = ""
    @State private var QRCodeImage: UIImage?
    @ObservedObject var firestoreService = FirestoreService()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.gray, .white]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack {
                        TextField("Gönderilen Şehir", text: $gönderilenSehir)
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding([.leading, .trailing, .top])
                        
                        TextField("Gideceği Şehir", text: $gidecegiSehir)
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding([.leading, .trailing])
                        
                        TextField("Tür", text: $tur)
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding([.leading, .trailing])
                        
                        TextField("Adet", text: $adet)
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding([.leading, .trailing, .bottom])
                        
                        Button("Oluştur") {
                            let combinedText = "\(gönderilenSehir).\(gidecegiSehir).\(tur).\(adet)"
                            if let qrCodeImage = UIImage.qrCode(from: combinedText) {
                                QRCodeImage = qrCodeImage
                                
                                // QR kod içeriğini Firestore'a ekleyin
                                let qrData = QRData(gönderilenSehir: gönderilenSehir, gidecegiSehir: gidecegiSehir, tur: tur, adet: adet)
                                firestoreService.saveData(qrData: qrData) { result in
                                    switch result {
                                    case .success():
                                        print("Data saved successfully")
                                    case .failure(let error):
                                        print("Error saving data: \(error.localizedDescription)")
                                    }
                                }
                                
                                // QR kod içeriğini UserDefaults'a kaydedin
                                saveQRCodeContent(content: combinedText)
                            } else {
                                // QR kod oluşturma başarısız oldu
                                QRCodeImage = nil
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .buttonStyle(.bordered)
                        .clipShape(Capsule())
                        .padding()
                        
                        if let qrCodeImage = QRCodeImage {
                            QRCodeView(QRCodeImage: $QRCodeImage, gönderilenSehir: $gönderilenSehir, gidecegiSehir: $gidecegiSehir, tur: $tur, adet: $adet)
                                .padding()
                            
                            Button("QR kodu galeriye kaydet") {
                                UIImageWriteToSavedPhotosAlbum(qrCodeImage, nil, nil, nil)
                            }
                        } else {
                            Text("Lütfen Gerekli Alanları Doldurunuz")
                                .foregroundColor(.red)
                                .font(.headline)
                                .frame(width: 400, height: 200)
                                .padding()
                        }
                        
                        NavigationLink(
                            destination: HistoryView(firestoreService: firestoreService),
                            label: {
                                Text("Paket listesini gör")
                                    .foregroundColor(.indigo)
                                    .padding()
                            })
                    }
                }
                .padding([.leading, .trailing, .bottom])
                .navigationTitle(Text("QR Kod Oluşturucu"))
            }
        }
    }
    
    func saveQRCodeContent(content: String) {
        var savedContents = UserDefaults.standard.stringArray(forKey: "savedQRCodeContents") ?? []
        savedContents.insert(content, at: 0) // Yeni içerikleri başa ekleyin
        UserDefaults.standard.set(savedContents, forKey: "savedQRCodeContents")
        print("QR code content saved: \(content)")
    }
}

extension UIImage {
    static func qrCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(data, forKey: "inputMessage")
        
        guard let ciImage = filter?.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        guard let cgImage = CIContext().createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

struct QRCodeView: View {
    
    @Binding var QRCodeImage: UIImage?
    @Binding var gönderilenSehir: String
    @Binding var gidecegiSehir: String
    @Binding var tur: String
    @Binding var adet: String
    
    var body: some View {
        VStack {
            Image(uiImage: QRCodeImage!)
                .resizable()
                .frame(width: 200, height: 200)
                .cornerRadius(5)
                .padding()
            
            HStack {
                Text("Gönderilen Şehir:")
                Spacer()
                Text(gönderilenSehir)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Gideceği Şehir:")
                Spacer()
                Text(gidecegiSehir)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Tür:")
                Spacer()
                Text(tur)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Adet:")
                Spacer()
                Text(adet)
            }
            .padding(.horizontal)
        }
    }
}
