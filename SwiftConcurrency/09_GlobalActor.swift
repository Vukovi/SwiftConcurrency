//
//  GlobalActor.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 08.10.23.
//

import SwiftUI

// MARK: - @globalActor je singlton na steroidima koji se odnosi na actor koji se enkapsulira u globalActoru. Razlog sto postoji je da bi se neki elementi koda koji nisu u samom actoru ucinili thread-safe i fakticki dodali u taj actor iako fizicki nisu u njemu. Obrnut proces od nonisolated.
// MARK: - Kada se napravi @globalActor onda se glavni actor vise ne koristi i sve treba da ide preko global actora
@globalActor final class MyFirstGlobalActor { // moze i struct
    static var shared = MyActorDataManager()
}
 
actor MyActorDataManager {
    func getDataFromDatabase() -> [String] {
        return ["One", "Two", "Three"]
    }
}

// MARK: - @MainActor moze biti i cela klasa, i to znaci da svi elementi moraju ici na main thread
class GlobalActorViewModel: ObservableObject {
    
    // MARK: - @MainActor je ugradjeni @MyFirstGlobalActor i oznacani element mora ici na main thread
    @MainActor
    @Published var dataArray: [String] = []
    
    let manager = MyFirstGlobalActor.shared
    
    func getData() async {
        let data = await manager.getDataFromDatabase()
        // MARK: - s'obzirom da je dataArray oznacen sa @MainActor mora da se pozove MainActor da bi ovaj property isao na main thread
        await MainActor.run {
            self.dataArray = data
        }
    }
    
    // MARK: - ovim je ova metoda postala deo actora, tj njegovog thread-safe izvrsenja
    @MyFirstGlobalActor
    func getDataWithActorThreadSafety() {
        Task {
            let data = await manager.getDataFromDatabase()
            await MainActor.run {
                self.dataArray = data
            }
        }
    }
}

struct GlobalActorView: View {
    
    @StateObject private var viewModel = GlobalActorViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.dataArray, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.getDataWithActorThreadSafety()
            }
        }
        .task {
            await viewModel.getData()
        }
    }
}

#Preview {
    GlobalActorView()
}
