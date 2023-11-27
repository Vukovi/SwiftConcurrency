//
//  SearchableView.swift
//  SwiftConcurrency
//
//  Created by Vuk Knezevic on 30.10.23.
//

import SwiftUI
import Combine

struct Restaurant: Identifiable, Hashable {
    let id: String
    let title: String
    let cusine: CusineOption
}

enum CusineOption: String {
    case american, italian, japanese
}

final class RestaurantManager {
    func getAllRestaurants() async throws -> [Restaurant] {
        
        return [
            Restaurant(id: "1", title: "Burger House", cusine: .american),
            Restaurant(id: "2", title: "Pasta Palace", cusine: .italian),
            Restaurant(id: "3", title: "Sushi Heaven", cusine: .japanese),
            Restaurant(id: "4", title: "Local Market", cusine: .american)
        ]
    }
}

@MainActor
final class SearchableViewModel: ObservableObject {
    
    // MARK: - Enum kreiran za SEARCH SCOPE
    enum SearchScopeOption: Hashable {
        case all
        case cusine(option: CusineOption)
        
        var title: String {
            switch self {
            case .all: return "All"
            case .cusine(option: let option): return option.rawValue.capitalized
            }
        }
    }
    
    @Published private(set) var allRestaurants: [Restaurant] = []
    @Published private(set) var filteredRestaurants: [Restaurant] = []
    @Published var searchText: String = ""
    @Published var searchScope: SearchScopeOption = .all
    @Published private(set) var allSearchScopes: [SearchScopeOption] = []
    let manager = RestaurantManager()
    private var cancellables = Set<AnyCancellable>()
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    var showSearchSuggeation: Bool {
        searchText.count <  5
    }
    
    init() {
        addSubscribers()
    }
    
    private func addSubscribers() {
        $searchText
            .combineLatest($searchScope) // Bilo koji od ova dva [$searchText ili $searchScope] koji bude emitovan ide dalje na debounce
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] (searchedText, searchScope) in
                self?.filterRestaurants(searchedText, currentSearchScopeOption: searchScope)
            }
            .store(in: &cancellables )
    }
    
    private func filterRestaurants(_ searchedText: String, currentSearchScopeOption: SearchScopeOption) {
        guard !searchedText.isEmpty else {
            filteredRestaurants = []
            searchScope = .all
            return
        }
        
        // Filter on search scope
        var restaurantsInScope = allRestaurants
        switch currentSearchScopeOption {
        case .all: break
        case .cusine(option: let option):
            restaurantsInScope = allRestaurants.filter({ restaurant in
                restaurant.cusine == option
            })
        }
        
        // Filter on search text
        let search = searchedText.lowercased()
        filteredRestaurants = restaurantsInScope.filter({ restaurant in
            let titleContainsSearch = restaurant.title.lowercased().contains(search)
            let cusineContainsSearch = restaurant.cusine.rawValue.lowercased().contains(search)
            
            return titleContainsSearch || cusineContainsSearch
        })
    }
       
    
    func loadRestaurants() async {
        do {
            
            allRestaurants = try await manager.getAllRestaurants()
            
            let allCusines = Set(allRestaurants.map { $0.cusine })
            
            allSearchScopes = [.all] + allCusines.map({ option in
                SearchScopeOption.cusine(option: option)
            })
            
        } catch { print(error) }
    }
    
    
    func getSearchSuggestions() -> [String] {
        guard showSearchSuggeation else { return [] }
         
        var suggestions: [String] = []
        
        let search = searchText.lowercased()
        
        if search.contains("pa") {
            suggestions.append("Pasta")
        }
        if search.contains("su") {
            suggestions.append("Sushi")
        }
        if search.contains("bu") {
            suggestions.append("Burger")
        }
        
        suggestions.append("Market")
        suggestions.append("Grocery")
        
        suggestions.append(CusineOption.italian .rawValue.capitalized)
        suggestions.append(CusineOption.japanese.rawValue.capitalized)
        suggestions.append(CusineOption.american.rawValue.capitalized)
        
        return suggestions
    }
    
    func getSuggestedRestaurants() -> [Restaurant] {
        guard showSearchSuggeation else { return [] }
         
        var suggestions: [Restaurant ] = []
        
        let search = searchText.lowercased()
        
        if search.contains("ita") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cusine == .italian }))
        }
        if search.contains("jap") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cusine == .japanese }))
        }
        if search.contains("ame") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cusine == .american }))
        }
        
        return suggestions
    }
}

struct SearchableView: View {
    
    @StateObject private var viewModel = SearchableViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.isSearching ? viewModel.filteredRestaurants : viewModel.allRestaurants) { restaurant in
                    NavigationLink(value: restaurant) {
                        restaurantRow(restaurant)
                    }
                }
            }
            .padding()
        }
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
        .navigationTitle("Restaurants")
        .task {
            await viewModel.loadRestaurants()
        }
        .navigationDestination(for: Restaurant.self) { restaurant in
            Text(restaurant.title.uppercased())
        }
    }
    
    
    private func restaurantRow(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restaurant.title)
                .font(.headline)
                .foregroundColor(.red)
            Text(restaurant.cusine.rawValue.capitalized)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05))
        .tint(.primary)
    }
}

#Preview {
    NavigationStack {
    SearchableView()
    }
}
