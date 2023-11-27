//
//  AsyncButton.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 04.10.23.
//

import SwiftUI

// MARK: - Photo view
struct PhotoView: View {
    var photo: Photo
    var onLike: () async -> Void
    
    var body: some View {
        VStack {
            Image(uiImage: photo.image)
            Text(photo.description)
            
            AsyncButton(
                systemImageName: "hand.thumbsup.fill",
                action: onLike
            )
            .disabled(photo.isLiked)
        }
    }
}

// MARK: - Preview
#Preview {
    return PhotoView(photo: photo, onLike: mockAsyncCall)
}

let photo = Photo(isLiked: false, image: UIImage(systemName: "ferry.fill")!, description: "Ferry boat")

func mockAsyncCall() async {
    try? await Task.sleep(nanoseconds: 5_000_000_000)
}

// MARK: - Photo model
struct Photo {
    let isLiked: Bool
    let image: UIImage
    let description: String
}

// MARK: - AsyncButton
struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    var actionOptions = Set(ActionOption.allCases)
    @ViewBuilder var label: () -> Label

    @State private var isDisabled = false
    @State private var showProgressView = false

    var body: some View {
        Button(
            action: {
                if actionOptions.contains(.disableButton) {
                    isDisabled = true
                }
            
                Task {
                    var progressViewTask: Task<Void, Error>?

                    if actionOptions.contains(.showProgressView) {
                        progressViewTask = Task {
                            try await Task.sleep(nanoseconds: 150_000_000)
                            showProgressView = true
                        }
                    }

                    await action()
                    progressViewTask?.cancel()

                    isDisabled = false
                    showProgressView = false
                }
            },
            label: {
                ZStack {
                    label().opacity(showProgressView ? 0 : 1)

                    if showProgressView {
                        ProgressView()
                    }
                }
            }
        )
        .disabled(isDisabled)
    }
}

extension AsyncButton {
    enum ActionOption: CaseIterable {
        case disableButton
        case showProgressView
    }
}

extension AsyncButton where Label == Text {
    init(_ label: String,
         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
         action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}

extension AsyncButton where Label == Image {
    init(systemImageName: String,
         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
         action: @escaping () async -> Void) {
        self.init(action: action) {
            Image(systemName: systemImageName)
        }
    }
}
