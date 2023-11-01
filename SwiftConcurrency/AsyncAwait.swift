//
//  AsyncAwait.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 01.10.23.
//

import SwiftUI

class AsyncAwaitViewModel: ObservableObject {
    @Published var data: [String] = []
    
    func addTitle1() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.data.append("Title 1: \(Thread.current)")
        }
    }
    
    func addTitle2() {
        DispatchQueue.global() .asyncAfter(deadline: .now() + 2) { [weak self] in
            let title2 = "Title 2: \(Thread.current)"
            DispatchQueue.main.async {
                self?.data.append(title2)
            }
        }
    }
    
    func addAuthor() async {
        
        for i in 0..<100 {
            print("no \(i)")
            // MARK: - Nekad, iako je task obustavljen, dogadja se da unutar taska postoje neki dugotrajni proces kao sto je npr ovaj loop, koji nece dozvoliti tasku da se zaista zavrsi i blokirace app, zato se u tim slucjevima na dugotrajnim mestima kao sto je ovaj loop koristi ovaj Task.checkCancellation() koji ce baciti error ako je konkretni Task cancellovan
            do {
                try Task.checkCancellation()
            } catch {}
        }
        
        let author1 = "Author 1: \(Thread.current)"
        await MainActor.run {
            data.append(author1)
        }
        
        try? await Task.sleep(nanoseconds: 2_000_000_000) // slicno kao DispatchQueue.main.asyncAfter
        let author2 = "Author 2: \(Thread.current)"
        
        await MainActor.run {  // slicno kao DispatchQueue.main
            self.data.append(author2)
            
            let author3 = "Author 3: \(Thread.current)"
            self.data.append(author3)
        }
    }
}

struct AsyncAwait: View {
    
    @StateObject private var viewModel = AsyncAwaitViewModel()
    
    @State private var fetchTask: Task<Void, Never>?
    
    var body: some View {
        List {
            ForEach(viewModel.data, id: \.self) { item in
                Text(item)
            }
        }
        // MARK: - Sa ovim .task ne more da sa brine o zavrsetku taska, koji se henlda u onDisappear, i nema potrebe za blokom Task
        .task {
            await viewModel.addAuthor()
        }
        .onDisappear {
            fetchTask?.cancel()
        }
        .onAppear {
            // MARK: - sve sto se nalazi u jednom Task-u izvrsava se proceduralno, tako da se prati redosled kojim su se dodavali elementi u taj pojedinacni Task, zato ce final uvek biti na kraju ako samo jedan Task postoji
            fetchTask = Task {
//                await viewModel.addAuthor()
                
                let final = "Final: \(Thread.current)"
                await MainActor.run {
                    self.viewModel.data.append(final)
                }
            }
            // MARK: - medjutim paralelnost se dobija sa vise taskova u jednom sindnom sinhronom bloku kao sto je onAppear
            Task {
                let concurrent = "Concurrent String"
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    self.viewModel.data.append(concurrent)
                }
            }
            // MARK: - Task priority
            Task(priority: .high) {
                // MARK: - Ako hocemo da napravimo inverziju prioriteta i da .high Task kao najprioritetniji propusti druge Taskove to cemo da uradimo ovako:
                await Task.yield()
                print("1 high: \(Task.currentPriority)")
            }
            Task(priority: .userInitiated) {
                print("2 userInitiated: \(Task.currentPriority)")
            }
            Task(priority: .medium) {
                print("3 medium: \(Task.currentPriority)")
            }
            Task(priority: .low) {
                print("4 low: \(Task.currentPriority)")
            }
            Task(priority: .utility) {
                print("5 utility: \(Task.currentPriority)")
            }
            Task(priority: .background) {
                print("6 background: \(Task.currentPriority)")
            }
            // MARK: - Nasledjivanje prioriteta, child Task ce iako mu nije naznacen prioritet preuzeti prioritet parenta, mada se child Taskovi ne prave na ovaj nacin
            Task(priority: .medium) {
                print("parent Task: \(Task.currentPriority)")
                Task {
                    print("child Task: \(Task.currentPriority)")
                }
                // MARK: - detached ovim se ponistava priority parenta, ali Apple kaze da se ovo izbegava
                Task.detached {
                    print("fake child Task: \(Task.currentPriority)")
                }
            }
        }
    }
}

#Preview {
    AsyncAwait()
}
