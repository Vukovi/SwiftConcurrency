//
//  Actors&Non-Isolated.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 07.10.23.
//

import SwiftUI

class MyDataManager {
    static let shared = MyDataManager()
    private init() {}
    
    var data: [String] = []
    
    // MARK: - Race Condition
    func getData() -> String? {
        self.data.append(UUID().uuidString)
        print(Thread.current)
        return data.randomElement()
    }
    
    // MARK: - Resenje za Race Condition
    let lock = DispatchQueue(label: "com.SwiftConcurrency.MyDataManager")
    
    func getData(completionHandler: @escaping (_ title: String?) -> ()) {
        lock.async { [weak self] in
            guard let self = self else { return }
            self.data.append(UUID().uuidString)
            print(Thread.current)
            completionHandler(self.data.randomElement())
        }
    }
}


actor MyActorManager {
    static let shared = MyActorManager()
    private init() {}
    
    var data: [String] = []
    
    func getData() -> String? {
        self.data.append(UUID().uuidString)
        print(Thread.current)
        return data.randomElement()
    }
    
    // MARK: - nonisolated znaci da oznaceni element vise ne pripada async/await/Task
    nonisolated
    let someString = "jhbjhjhjhjhjhjhhjh"
    
    nonisolated
    func getNewData() -> String {
        return "NEW DATA"
    }
    
}


struct HomeView: View {
    
    let manager = MyDataManager.shared
    let actorManager = MyActorManager.shared
    
    @State private var text = ""
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.8).ignoresSafeArea()
            
            Text(text)
                .font(.headline)
        }
        .onAppear {
            // MARK: - nonisolated
            let ns = actorManager.getNewData()
            let someString = actorManager.someString
        }
        .onReceive(timer, perform: { _ in
            /*
            DispatchQueue.global(qos: .background).async {
                // MARK: - Sa Race Condition-om
//                if let data = manager.getData() {
//                    DispatchQueue.main.async {
//                        self.text = data
//                    }
//                }
                // MARK: - Bez Race Condition-a
                manager.getData { title in
                    if let title = title {
                        self.text = title
                    }
                }
            }
            */
            Task {
                if let data = await actorManager.getData() {
                    await MainActor.run {
                        self.text = data
                    }
                }
            }
        })
    }
}

struct BrowseView: View {
    
    let manager = MyDataManager.shared
    let actorManager = MyActorManager.shared
    
    @State private var text = ""
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.8).ignoresSafeArea()
            
            Text(text)
                .font(.headline)
        }
        .onReceive(timer, perform: { _ in
            /*
            DispatchQueue.global(qos: .default).async {
                // MARK: - Sa Race Condition-om
//                if let data = manager.getData() {
//                    DispatchQueue.main.async {
//                        self.text = data
//                    }
//                }
                // MARK: - Bez Race Condition-a
                manager.getData { title in
                    if let title = title {
                        self.text = title
                    }
                }
            }
            */
            Task {
                if let data = await actorManager.getData() {
                    await MainActor.run {
                        self.text = data
                    }
                }
            }
        })
    }
}

struct Actors_Non_Isolated: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    Actors_Non_Isolated()
}
