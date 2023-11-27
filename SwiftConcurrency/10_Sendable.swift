//
//  Sendable.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 08.10.23.
//

import SwiftUI

// Sendable protokol onzacava nesto da bude thread safe i da moze da se ubaci u actor

actor CurrentUserManager {
    
    func updateDatabase(userInfo: MyClassUserInfo) {
        
    }
}

// MARK: - struct je svakako sendable jer je to value type, ali zbog boljih performansi kompajlera bilo bi dobro i strukturu podvrgnuti Senadble protokolu
struct MyUserInfo {
    let info: String
}

final class MyClassUserInfo: @unchecked Sendable {
    // MARK: - Dok je sve bilo konstata nije bilo problema i to je potpuni Sendable objekat
    // Medjutim ako se umesto konstate [let] koristi promenljiva [var]
    // onda to prestaje da bude safe-thread objekat jer se na bilo kom threadu iz bilo kog dela aplikacije moze menjati ovaj objekt, naravno ako je siroko i koriscen sto je obicno i slucaj
    // zbog toga se ispred Sendable dodaje keyword @unchecked cime se govori kompajleru da smo mi zaduzeni da ovaj objekat postane thread-safe
    // a to cemo da postignemo dodavanjem queue-a i enkapsuliranim modifikovanjem varijable, koja bi zbog siguransoti mogla da postane private
    
    private var info: String
    
    let lock = DispatchQueue(label: "com.SwiftConurrency.MyClassUserInfo")
    
    init(info: String) {
        self.info = info
    }
    
    func updateInfo(_ newInfo: String) {
        lock.async { [weak self] in
            self?.info = newInfo
        }
    }
}

class SendableViewModel: ObservableObject {
    let manager = CurrentUserManager()
    
    func updateCurrentUser() async {
        
        let info = MyClassUserInfo(info: "USER INFO")
        
        await manager.updateDatabase(userInfo: info)
    }
}

struct SendableView: View {
    
    @StateObject private var viewModel = SendableViewModel()
    
    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    SendableView()
}
