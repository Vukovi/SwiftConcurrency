//
//  17_AsyncStream.swift
//  SwiftConcurrency
//
//  Created by Vuk Knežević on 27.11.23..
//

import SwiftUI

// MARK: - Svaki put kad imamo vise completionHandler-a koji se izvrsavaju nekoliko puta koristi se async stream.
// MARK: - Continuation se koristi za to pretvranje ali je ograncenje samo jedan continuation po completionHandler-u. Kad imamo seriju vracanja, npr neka Firebaseova funkcija koja vraca isti completion nekoliko puta, ne bi mogla da se prevede u async/await pomocu continutaion-a vec bi morala preko asyncStream-a


class AsyncStreamDataManager {
    
    func getAsyncStream() -> AsyncThrowingStream<Int, Error> {
        // MARK: - AsyncStream(Int.self) je kad nemamo potrebe da bacimo i error
        // MARK: - AsyncThrowingStream(Int.self) mam otvara mogucnost da continuation baci error
        AsyncThrowingStream(Int.self) { [weak self] continuation in
            self?.getFakeData(completionHandler: { value in
                continuation.yield(value)
            }, onFinish: { error in
                if let error = error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            })
        }
    }
    
    // MARK: - Serija vracanja, prakticno 10 vracanja i @escaping jer ce klozer ziveti i posle uklanjanja funkcije
    func getFakeData(
        completionHandler: @escaping (_ value: Int) -> Void,
        onFinish: @escaping (_ error: Error?) -> Void) {
        let items: [Int] = [1,2,3,4,5,6,7,8,9,10]
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                completionHandler(item)
                print("NEW DATA: \(item)")
                
                // MARK: - DA BISMO ZNALI KAD PUBLISHOVANJE PRESTAJE!!!!!
                if item == items.last {
                    onFinish(nil)
                }
            }
        }
    }
}

@MainActor final class AsyncStreamViewModel: ObservableObject {
    
    let manager = AsyncStreamDataManager()
    @Published private(set) var currentNumber: Int = 0
    
    func onViewAppear() {
//        manager.getFakeData { [weak self] value in
//            self?.currentNumber = value
//        }
        
//        Task {
//            do {
        // MARK: - NA AsyncStream-u mozemo koristiti Combine-ove pipeline-ove!!!!!!
//                for try await value in manager.getAsyncStream().dropFirst()  {
//                    currentNumber = value
//                }
//            } catch {}
//        }
        
        // MARK: - VAZNO - ukoliko ukinemo samo Task to ne znaci da ce se ukinuti sam AsyncStream iz managera. To ce morati da se uradi nekom dodatnom metodom
        
        let task = Task {
            do {
                for try await value in manager.getAsyncStream(){
                    currentNumber = value
                }
            } catch {}
        }
        
        // MARK: - Prekidamo Task npr posle 5 sekundi, to znaci da ce se na ekranu zaustiviti na broju 4, ali ce stream nastaviti da publishuje
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            task.cancel()
            print("TASK HAS BEEN CANCELLED!")
        }
    }
    
}

struct AsyncStreamBootcamp: View {
    
    @StateObject private var viewModel = AsyncStreamViewModel()
    
    var body: some View {
        Text("\(viewModel.currentNumber)")
            .onAppear {
                viewModel.onViewAppear()
            }
    }
}

#Preview {
    AsyncStreamBootcamp()
}
