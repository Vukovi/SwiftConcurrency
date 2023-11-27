//
//  DoTryCatchThrows.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 01.10.23.
//

import SwiftUI

struct DoTryCatchThrows: View {
    
    @StateObject private var viewModel: DTCT_ViewModel = DTCT_ViewModel()
    
    var body: some View {
        Text(viewModel.text)
            .frame(width: 300, height: 300)
            .background(.blue)
            .onTapGesture {
                viewModel.fetchTitle()
            }
    }
}

#Preview {
    DoTryCatchThrows()
}


// MARK: - View Model
class DTCT_ViewModel: ObservableObject {
    
    @Published var text: String = "Starting text."
    
    let manager = DTCT_DataManager()
    
    func fetchTitle() {
        do {
            // svaki try u do bloku mora da prodje da se ne bi uskocilo u catch blok
            text = try manager.getTitle()
        } catch {
            text = error.localizedDescription
        }
    }

}


// MARK: - Data Manager
class DTCT_DataManager {
    
    var isActive: Bool = false
    
    func getTitle() throws -> String {
        if isActive {
            return "NEW TEXT!"
        } else {
            throw URLError.init(.cancelled)
        }
    }
}
