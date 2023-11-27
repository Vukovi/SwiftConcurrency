//
//  RefreshableView.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 30.10.23.
//

import SwiftUI

// MARK: - Ovo je kao pull to refresh opcija

final class RefreshableService {
 
    func getData() async throws -> [String] {
        try await Task.sleep(nanoseconds: 5_000_000_000)
        return ["Apple", "Orange", "Banana"].shuffled()
    }
}

@MainActor
final class RefreshableViewModel: ObservableObject {
    @Published private(set) var items: [String] = []
    let manager = RefreshableService()
    
    func loadData() async {
        do {
            items = try await manager.getData()
        } catch { print(error) }
    }
}

struct RefreshableView: View {
    
    @StateObject private var viewModel = RefreshableViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(viewModel.items, id: \.self) { item in
                        Text(item)
                            .font(.headline)
                    }
                }
            }
            .refreshable {
                // MARK: - Refreshable je async metod, a loadData() nije bila async i ona bi odmah obavila izvrenje koda bez cekanja na eventualni rezultat, zato sam prepravio *- loadData() -* da bude *- loadData() async -*
                await viewModel.loadData()
            }
            .navigationTitle("Refreshable")
            .task {
                await viewModel.loadData()
            }
            
        }
        
    }
}

#Preview {
    RefreshableView()
}
