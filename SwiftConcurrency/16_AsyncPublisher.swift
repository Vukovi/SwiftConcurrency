//
//  AsyncPublisherView.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 19.10.23.
//

import SwiftUI
import Combine

// MARK: - Male upotrebe Combine-a mogu da se zamene upotrebom Async Publisher-a, koji je struktura koja je podvrgnuta protokolu AsyncSequence

actor AsyncPublisherDataManager {
    @Published var myData: [String] = []
    
    func addData() async {
        myData.append("Apple")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        myData.append("Banana")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        myData.append("Kiwi")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        myData.append("Orange")
    }
}

class AsyncPublisherViewModel: ObservableObject {
    @MainActor @Published var dataArray: [String] = []
    
    let manager = AsyncPublisherDataManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
//        addSubscribers()
        addSubscribersAsAsyncPublisher()
    }
    
    private func addSubscribers() {
        Task {
            await manager.$myData
                .receive(on: DispatchQueue.main)
                .sink { value in
                    DispatchQueue.main.async { [weak self] in
                        self?.dataArray = value
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func addSubscribersAsAsyncPublisher() {
        Task {
            
            // MARK: - ova petlja se ne izvrsava odmah vec asinhrono, kako se publisuju vrednosti myData niza
            // MARK: - .values je ASYNC_PUBLISHER
            for await value in await manager.$myData.values {
                await MainActor.run {
                    self.dataArray = value
                }
            }
            
            // MARK: - Sve sto je ispod ovakve petlje se nece izvrsiti jer publisher ne zna kada je gotovo publishovanje tako da se zaustavlja u petlji zauvek, osim ako se petlja ne prekine nekim break-om ili se druga potrebna izvrsenja rasporede u druge Task-ove, a ne unutar ovog jednog.
        }
    }
    
    func start() async {
        await manager.addData()
    }
}

struct AsyncPublisherView: View {
    
    @StateObject private var viewModel = AsyncPublisherViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.dataArray, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
        }
        .task {
            await viewModel.start()
        }
    }
}

#Preview {
    AsyncPublisherView()
}
