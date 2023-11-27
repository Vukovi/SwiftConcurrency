//
//  AsyncImageDownload.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 01.10.23.
//

import SwiftUI
import Combine

struct AsyncImageDownload: View {
    
    @StateObject private var viewModel = AID_ViewModel()
    
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }
        }
        .onAppear {
//            viewModel.fetchImage()
//            viewModel.fetchImageWithCombine()
            Task {
                await viewModel.fetchImageAsync()
            }
        }
    }
}

#Preview {
    AsyncImageDownload()
}


class AID_Manager {
    let url = URL(string: "https://picsum.photos/200")!
    
    func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard let data = data,
              let image = UIImage(data: data),
              let response = response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
                  return nil
        }
        
        return image
    }
    
    // MARK: - 1. stari escaping nacin
    func downloadWithEscaping(completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        URLSession.shared.dataTask(with: URLRequest(url: url)) { [weak self] data, response, error in
            let image = self?.handleResponse(data: data, response: response)
            completion(image, error)
        }
        .resume()
    }
    
    // MARK: - 2. Combine nacin
    func downloadWithCombine() -> AnyPublisher<UIImage?, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 3. async nacin
    func downloadWithAsync() async throws -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
            return handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }
}


class AID_ViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    
    let loader = AID_Manager()
    
    private var cancellable = Set<AnyCancellable>()
    
    
    func fetchImage() {
        loader.downloadWithEscaping { [weak self] image, error in
            guard error == nil else { return }
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
    
    func fetchImageWithCombine() {
        loader.downloadWithCombine()
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] image in
                self?.image = image
            }
            .store(in: &cancellable)

    }
    
    func fetchImageAsync() async {
        let image = try? await loader.downloadWithAsync()
        // MainActor je slicno kao Main thread
        await MainActor.run {
            self.image = image
        }
    }
    
}
