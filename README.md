### do-catch blok
Ukoliko jedan TRY ne uspe od vise TRY-eva koji postoje unutar DO bloka, uskace se u CATCH blok

### MainActor.run
MainActor.run { ... slicno kao blok DispatchQueue.main.async ... }

### Task
@State var someTask: Task<Void, Never>?

- sve sto se nalazi u jednom TASK-u izvrsava se proceduralno, tako da se prati redosled kojim su se dodavali elementi u taj TASK
```
  Task {
             ...1...
             ...2...
             ...3...
  }
```

- paralelnost se dobija dodavanjem vise TASK-ova u jednom sinhronom blolu kao sto je:
  ```
 .onAppear{
             Task {
                        ...1...
                        ...2...
             }
             Task {
                        ...1...
                        ...2...
             }
  }
  ```

 - Task priority -> high, usedDefined, medium, low, utility, background

 - Task.yield() -> inverzija prioriteta se dobija tako sto TASK-u viseg prioriteta kazemo da propusti TASK-ove nizeg prioriteta pomocu YIELD() metode
 - ```
    Task(priority: .high) {
           await Task.yield()
    }
   ```
  
 - Nasledjivanje prioriteta -> child Tasku ne navedemo prioritet, tako da on preuzme prioritet parenta
   ```
    Task(priority: .high) {
           Task(priority: .high) { -> ovaj isto ima HIGH prioritet od parenta
                Task.sleep(nanoseconds: 2_000_000_000)
           }
    }
   ```

  - Task.detached { ... ovim se ponistava priority parenta ali Apple kaze da se ovo izbegava ... }

### async let
Pomocu async let dobija se paralelnost unutar jednog Task-a

SERIJSKI, CEKA SE SVAKI IMG1,2,3 DA SE DOBIJE PO REDU:
```
Task { 
   let img1 = await fetchImage()
   let img2 = await fetchImage()
   let img3 = await fetchImage()
}
```

PARALELNO, SVAKI IMG1,2,3 SE DOBIJA NEZAVISNO I MANJE SE CEKA, ALI KOD JE MASIVAN:
```
Task { 
   Task {
      let img1 = await fetchImage()
   }
   Task {
      let img2 = await fetchImage()
   }
   Task {
      let img3 = await fetchImage()
   }
}
```

ASYNC LET OMOGUCAVA PARALELNOST IZVRESNJA UNUTAR JEDNOG TASKA I TAD SE NE KORISTI AWAIT KEYWORD
```
Task { 
   async let img1 = fetchImage()
   async let img2 = fetchImage()
   async let img3 = fetchImage()
}
```

### Task Group
Takodje se koristi za paralelna izvrenja i moze biti withThrowingTaskGroup(...) { } ili withTaskGroup(...) { }
```
func fetchImagesWithTaskGroup() async throws -> [UIImage] {
        
        let urlStrings = [
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300"
        ]
        
        return try await withThrowingTaskGroup(of: UIImage?.self) { [weak self] group in
            guard let self = self else { return [] }
            
            var images: [UIImage] = []
            images.reserveCapacity(urlStrings.count)
            
            for urlString in urlStrings {
                group.addTask {
                    try? await self.fetchImage(urlString: urlString)
                }
            }
            
            // ceka se ovde da se svi ovi taskovi u petlji iznad izvrse
            for try await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            
            return images
        }
    }
```
