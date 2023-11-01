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
  .onAppear {
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

### Async Button
Button sa spinerom koji je aktivan dok se async izvrenje ne dovrsi

### Continuations
Pretvaranje funkcija sa @escaping klozerom u async funkcije.
Postoje UNSAFE, UNSAFE_THROWING, CHECKED i CHECKED_THROWING
```
func getDataWithContinuation(url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
                // MARK: - Mora se voditi racuna o tome da se CONTINUATION vrati (resume-uje) samo jednom
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }
            .resume()
        }
    }
```

### Actor & nonisolated keyword
Actor je isto sto i CLASS samo thread-safe
nonisolated keyword znaci da njome oznaceni elementi u ACTORU nisu vise thread-safe i za njih ne vaze async/await pravila
```
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
```

### @globalActor
Obrnuto od NONISOLATED, ono sto je oznaceno globalnim actorom, dodaje se u Actor na specifican nacin i postaje thread-safe.
Klasa (ili struktura) koja je proglasena globalnim actorom, postaje neka vrsta singltona na steriodima, i odnosi se na enkapsulirani actor unutar gloablnog actora, tako da enkapsulirani actor vise ne treba da se koristi, vec se njemu pristupa preko globalnog actora.
```
@globalActor final class MyFirstGlobalActor { // moze i struct
    static var shared = MyActorDataManager()
}
 
actor MyActorDataManager {
    func getDataFromDatabase() -> [String] {
        return ["One", "Two", "Three"]
    }
}

class GlobalActorViewModel: ObservableObject {
    @MainActor
    @Published var dataArray: [String] = []
    let manager = MyFirstGlobalActor.shared
    // MARK: - ovim je ova metoda postala deo actora, tj njegovog thread-safe izvrsenja
    @MyFirstGlobalActor
    func getDataWithActorThreadSafety() {...}
}
```

### Sendable
Obezbedjuje da neki objekat bude thread-safe i da se jedino takav moze poslati actoru.
Sendable se vise odnosi na klase, koje moraju da modifikuju ukoliko imaju varijablne property-je,
sto je obicno i slucaj, a modifikuju se tako sto im se doda neki queue proprerty ili lock, koji je serijski
i koji ce obezbediti da se sve unutar tog objekta odvija thread-safe.

### @unchecked Sendable
Ovim se garantuje kompajleru da ce objekat biti safe thread

### AsyncPublisher
Male upotrebe Combine-a mogu da se zamene upotrebom Async Publisher-a, koji je struktura koja je podvrgnuta protokolu AsyncSequence
```
actor AsyncPublisherDataManager {
    @Published var myData: [String] = []
    
    func addData() async {
        myData.append("Apple")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        myData.append("Banana")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        myData.append("Kiwi")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        myData.append("Orange")
    }
}
```
```
private func addSubscribersAsAsyncPublisher() {
        Task {
            // MARK: - ova petlja se ne izvrsava odmah vec asinhrono, kako se publisuju vrednosti myData niza
            for await value in await manager.$myData.values {
                await MainActor.run {
                    self.dataArray = value
                }
            }
            
            // MARK: - Sve sto je ispod ovakve petlje se nece izvrsiti jer publisher ne zna kada je gotovo publishovanje tako da se zaustavlja u petlji zauvek, osim ako se petlja ne prekine nekim break-om ili se druga potrebna izvrsenja rasporede u druge Task-ove, a ne unutar ovog jednog.
        }
    }
```

### Strong Self
Zasto ne ubacujemo [weak self] kod async/await i na taj nacin ne hendlamo strong reference?
Zato sto Task {} to hendla za nas, osim u slucaju kad se ekran ukine pre kraja izvrsenja ili mi hocemo da prekinemo izvrsenje.
Prekidanje taskova moze da se obavlja i bez naseg hendlanja ovog "problema" u metodama .onAppear() i .onDisappear(), tako sto koristimo metodu .task() koja automatski ovo radi

```
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
```

Mozda nece biti potrebe da se hendla [weak self] ali za svaki slucaj hendlaj:
```
func selfHandling_MAY_NOT_NEEDED() {
  customTask = Task {
     data = await service.getData()
  }
}
```

Ne mora da se koristi [weak self] ako ce se ovo pozivati u .task() metodi:
```
func selfHandling_NOT_NEEDED() async {
  let _ = await service.getData()
}
```

Neka situacija u kojoj namerno hocu da hendlam taskove sam:
```
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
```
UPOTREBA:
```
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
```

### Refreshable - pull to refresh
Refreshable je async metod, a loadData() ako nije bila async ona bi odmah obavila izvrenje koda bez cekanja na eventualni rezultat, zato sam moa async metoda
```
.onAppear { ... }
.refreshable {
    await viewModel.loadData()
}
```

### Searchable
Olaksica za search & filter logiku
```
.onAppear { ... }
.searchable(text: $viewModel.searchText, placement: .automatic, prompt: "Search restaurants")
.searchScopes($viewModel.searchScope, scopes: {
    ForEach(viewModel.allSearchScopes, id: \.self) { scope in
        Text(scope.title)
            .tag(scope)
        }
    })
.searchSuggestions({
    ForEach(viewModel.getSearchSuggestions(), id: \.self) { suggestion in
        Text(suggestion)
            .searchCompletion(suggestion)
        }

    ForEach(viewModel.getSuggestedRestaurants(), id: \.self) { suggestedRestaurant in
        NavigationLink(value: suggestedRestaurant) {
            Text(suggestedRestaurant.title.capitalized)
        }
    }
})
```

### Photo Picker
Umesto UIPhotoPicker-a postioji PhotosUI

```
@Published var imageSelection: PhotosPickerItem?
@Published var imageSelections: [PhotosPickerItem] = []

...

PhotosPicker(selection: $viewModel.imageSelection, matching: .images) {
    Text("Open the photo picker!")
        .foregroundStyle(.red)
}

PhotosPicker(selection: $viewModel.imageSelections, matching: .images) {
    Text("Open the photos picker!")
        .foregroundStyle(.red)
}
```
