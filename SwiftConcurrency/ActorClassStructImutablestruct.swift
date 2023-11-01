//
//  ActorClassStructImutablestruct.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 07.10.23.
//

import SwiftUI

struct MyStruct {
    var title: String
    
    func updateTitle(_ title: String) -> MyStruct {
        MyStruct(title: title)
    }
    
    mutating func updateTitle2(_ title: String) {
        self.title = title
    }
    
    // MARK: - MUTATING:
    // MARK: - Obe funkcije updateTitle, prva sa return typeom i druga sa keywordom mutating, su iste funkcije, tj pomocu mutating keyword-a se dobija isto ponasanje kao kod funkcije iznad sa return type-om
}

struct MyImutableStruct {
    let title: String
    
    func updateTitle(_ title: String) -> MyImutableStruct {
        MyImutableStruct(title: title)
    }
}

class MyClass {
    var title: String
    
    init(title: String) {
        self.title = title
    }
}

// MARK: - Actor je isto sto i class, samo thread safe i property-ji mu se ne mogu menjati van njega, vec unutar njega npr odgovarajucim metodama
actor MyActor {
    var title: String
    
    init(title: String) {
        self.title = title
    }
    
    func updateTitle(_ title: String) {
        self.title = title
    }
}

func structVSclass() {
    let s1: MyStruct = MyStruct(title: "s1")
    var s2: MyStruct = s1
    s2.title = "s2" // Posto je ovo value type, promenom property-ja title, menja se ceo objekat s2, dakle i objekat S2 i property TITLE moraju biti mutabilni, tj objekat S2 mora biti VAR, kao sto i property TITLE mora biti VAR
    
    let c1: MyClass = MyClass(title: "c1")
    let c2: MyClass = c1
    c2.title = "c2" // Posto je ovo reference type, promenom property-ja title, NE menja se ceo objekat c2, jer i c1 i c2 su reference istog objeta, tako da se samo menja property title, koji ce sad u oba slucaja biti "c2" i jedino ovaj property TITLE mora biti mutabilan, tj VAR, a objekat C2 moze ostati LET
}

func structVSimutableStruct() {
    var s1: MyStruct = MyStruct(title: "1")
    s1.title = "2" // Opet, da bi ovo bilo moguce, struct s1 mora biti var
    print(s1.title)
    
    var s2: MyStruct = MyStruct(title: "1")
    s2 = MyStruct(title: "2") // Ovde se dogadja isto sto se dogadja na drugoj liniji kod strukture S1
    print(s2.title)
    
    var s3: MyStruct = MyStruct(title: "1")
    s3 = s3.updateTitle("2") // Ovde se dogadja isto sto se dogadja na drugoj liniji kod strukture S1 i na drugoj liniji S2
    print(s3.title)
    
    var s4: MyStruct = MyStruct(title: "1")
    s4.updateTitle2("2") // Ovde se dogadja isto sto se dogadja na drugoj liniji kod strukture S1 i na drugoj liniji S2, kao i na drugoj liniji S3
    print(s4.title)
    
}

// MARK: - Funkcije sa actorima imaju ili async ili Task unutar sebe
func actorAction() async {
    let a1 = MyActor(title: "1")
    let a2 = a1
//    a2.title = "2" // nema menjanja van actora
    await a2.updateTitle("2") // ali ovako moze
}

func actorAction() {
    Task {
        let a1 = MyActor(title: "1")
        let a2 = a1
    //    a2.title = "2" // nema menjanja van actora
        await a2.updateTitle("2") // ali ovako moze
    }
}

struct ActorClassStructImutablestruct: View {
    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    ActorClassStructImutablestruct()
}
