//
//  AsyncLet.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 02.10.23.
//

import SwiftUI

struct AsyncLet: View {
    
    @State private var images: [UIImage] = []
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    let url = URL(string: "https://picsum.photos/200")!
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle("Async Let 👁️")
            .onAppear {
                Task {
                    do {
                        // MARK: - Na ovaj nacin ceka se zavrsetak jednog po jednog redom koji su zapisani
//                        let image1 = try await fetchImage()
//                        self.images.append(image1)
//                        
//                        let image2 = try await fetchImage()
//                        self.images.append(image2)
//                        
//                        let image3 = try await fetchImage()
//                        self.images.append(image3)
//                        
//                        let image4 = try await fetchImage()
//                        self.images.append(image4)
                        
                        // MARK: - Da ne bismo pravili veliki broj Taskova kako bi dobili paralelnost izvrsenja, iz prakticnih razloga i vodjenja racuna o svim tim Taskovima, primenicemo async let i dobicemo istovremeno sve fetchovane slike
                        
                        async let fetchImage1 = fetchImage()
                        async let fetchImage2 = fetchImage()
                        async let fetchImage3 = fetchImage()
                        async let fetchImage4 = fetchImage()
                        
                        let (image1, image2, image3, image4) = await (try fetchImage1, try fetchImage2, try fetchImage3, try fetchImage4)
                        
                        self.images.append(contentsOf: [image1, image2, image3, image4])
                        
                    } catch {}
                }
            }
        }
    }
    
    
    func fetchImage() async throws -> UIImage {
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

#Preview {
    AsyncLet()
}
