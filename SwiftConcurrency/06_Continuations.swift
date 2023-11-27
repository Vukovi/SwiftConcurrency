//
//  Continuations.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 06.10.23.
//

import SwiftUI

class ContinuationsManager {
    func getData(url: URL) async throws -> Data {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch  {
            throw error
        }
    }
    
    func getDataWithContinuation(url: URL) async throws -> Data {
        // MARK: - Postoji 4 continuation: unsafe, unsafeThrowing, checked i checkedThrowing. Najbolje je koristiti checked, a throwing ako polazna metoda, kao ova getDataWithContinuation, ima throws u sebi
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
                // MARK: - Mora se voditi racuna o tome da se CONTINUATION vrati (resume-uje) samo jednom
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }
            .resume()
        }
    }
    
    func getHeartImageFromDatabase(completionHandler: @escaping (_ image: UIImage) -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            completionHandler(UIImage(systemName: "heart.fill")!)
        }
    }
    
    func getHeartImageFromDatabase() async -> UIImage {
        return await withCheckedContinuation { continuation in
            getHeartImageFromDatabase { image in
                continuation.resume(returning: image)
            }
        }
    }
}

class ContinuationsViewModel: ObservableObject {
    @Published var image: UIImage?
    
    let url = URL(string: "https://picsum.photos/200")
    
    let manager = ContinuationsManager()
    
    func getImage() async {
        guard let imageUrl = url else { return }
        do {
            let data = try await manager.getDataWithContinuation(url: imageUrl)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.image = image
                }
            }
        } catch  { }
    }
    
    func getHeartImage() async {
        image = await manager.getHeartImageFromDatabase()
    }
}

struct ContinuationsView: View {
    
    @StateObject private var viewModel = ContinuationsViewModel()
        
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Text("nema slike")
            }
        }
        .task {
//            await viewModel.getImage()
            await viewModel.getHeartImage()
        }
    }
}

#Preview {
    ContinuationsView()
}
