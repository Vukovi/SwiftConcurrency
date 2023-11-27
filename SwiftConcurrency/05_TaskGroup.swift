//
//  TaskGroup.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 02.10.23.
//

import SwiftUI

class TaskGroupDataManager {
    
    func fetchImagesWithTaskGroup() async throws -> [UIImage] {
        
        let urlStrings = [
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300"
        ]
        
        return try await withThrowingTaskGroup(of: UIImage?.self) { [weak self] group in
            guard let self = self else { return [] }
            
            var images: [UIImage] = []
            images.reserveCapacity(urlStrings.count)
            
            for urlString in urlStrings {
                group.addTask {
                    try? await self.fetchImage(urlString: urlString)
                }
            }
            
            // ceka se ovde da se svi ovi taskovi u petlji iznad izvrse
            for try await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            
            return images
        }
    }
    
    func fetchImagesWithAsyncLet() async throws -> [UIImage] {
        async let fetchImages1 = fetchImage(urlString: "https://picsum.photos/300")
        async let fetchImages2 = fetchImage(urlString: "https://picsum.photos/300")
        async let fetchImages3 = fetchImage(urlString: "https://picsum.photos/300")
        async let fetchImages4 = fetchImage(urlString: "https://picsum.photos/300")
        
        let (image1, image2, image3, image4) = await (try fetchImages1, try fetchImages2, try fetchImages3, try fetchImages4)
        
        return [image1, image2, image3, image4]
        
     }
    
    private func fetchImage(urlString: String) async throws -> UIImage {
        
        guard let url = URL(string: urlString) else {
            throw URLError.init(.badURL)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            if let image = UIImage(data: data) {
                return image
            } else {
                throw URLError.init(.badURL)
            }
        } catch {
            throw error
        }
    }
    
}

class TaskGroupViewModel: ObservableObject {
    
    @Published var images: [UIImage] = []
    
    let manager = TaskGroupDataManager()
    
    func getImages() async  {
        if let images = try? await manager.fetchImagesWithTaskGroup() {
            self.images.append(contentsOf: images)
        }
    }
    
}

struct TaskGroupView: View {
    
    @StateObject private var viewModel = TaskGroupViewModel()
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(viewModel.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle("Async Let 👁️")
            .task {
                await viewModel.getImages()
            }
        }
    }
}

#Preview {
    TaskGroupView()
}
