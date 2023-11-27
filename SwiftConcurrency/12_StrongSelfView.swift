//
//  StrongSelfView.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 24.10.23.
//

import SwiftUI

final class StrongSelfService {
    func getData() async -> String {
        return "Updated data!"
    }
}

final class StrongSelfViewModel: ObservableObject {
    
    @Published var data: String = "Some title!"
    
    let service = StrongSelfService()
    
    private var customTask: Task<Void, Never>?
    private var tasks: [Task<Void, Never>] = []
    
    // MARK: - prekidanje taskova
    func cancelTasks() {
        // za jedan task hendlanje
        customTask?.cancel()
        customTask = nil
        
        // za vise taskova henldanje
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    
    
    // MARK: - Zasto ne ubacujemo [weak self] i na taj nacin ne hendlamo strong reference
    // Zato sto Task {} to hendla za nas, osim u slucaju kad se ekran ukine pre kraja izvrsenja ili mi hocemo da prekinemo izvrsenje
    // Prekidanje taskova se obavlja i bez naseg hendlanja u metodama .onAppear() i .onDisappear(), tako sto koristimo metodu .task() koja automatski ovo radi
    
    // Mozda nece biti potrebe da se hendla [weak self] ali za svaki slucaj hendlaj
    func selfHandling_MAY_NOT_NEEDED() {
        customTask = Task {
            data = await service.getData()
        }
    }
    
    // Ne mora da se koristi [weak self] jer ce se ovo pozivati u .task() metodi
    func selfHandling_NOT_NEEDED() async {
        let _ = await service.getData()
    }
    
    // Neka situacija u kojoj namerno hocu da hendlam taskove sam
    func selfHandlin_NEEDED() {
        let task1 = Task {
            data = await service.getData()
        }
        tasks.append(task1)
        
        let task2 = Task {
            data = await service.getData()
        }
        tasks.append(task2)
    }
}
 struct StrongSelfView: View {
    
    @StateObject private var viewModel = StrongSelfViewModel()
    
    var body: some View {
        Text(viewModel.data)
            .onAppear {
                viewModel.selfHandling_MAY_NOT_NEEDED()
                viewModel.selfHandlin_NEEDED()
            }
            .onDisappear {
                viewModel.cancelTasks()
            }
            .task {
                await viewModel.selfHandling_NOT_NEEDED()
            }
    }
}
 
#Preview {
    StrongSelfView()
}
