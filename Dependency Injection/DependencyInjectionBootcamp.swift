//
//  DependencyInjectionBootcamp.swift
//  Dependency Injection
//
//  Created by Marcin Jędrzejak on 14/07/2023.
//

import SwiftUI
import Combine

// PROBLEMS WITH SINGLETONS
// 1. Singleton's are GLOBAL
// 2. Can't customize the init!
// 3. Can't swap out services

struct PostsModel: Identifiable, Codable {
    let userID: Int
    let id: Int
    let title: String
    let body: String
}

class ProductionDataService {
    
    static let instance = ProductionDataService() // Singletion
    
    let url: URL = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    
    func getData() -> AnyPublisher<[PostsModel], Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map({ $0.data })
            .decode(type: [PostsModel].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

class DependencyInjectionViewModel: ObservableObject {
    
    @Published var dataArray: [PostsModel] = []
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        loadPosts()
    }
    
    private func loadPosts() {
        ProductionDataService.instance.getData()
            .sink { _ in
                
            } receiveValue: { [weak self] returnedPosts in
                self?.dataArray = returnedPosts
            }
            .store(in: &cancellables)
    }
}

struct DependencyInjectionBootcamp: View {
    
    @StateObject private var vm = DependencyInjectionViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Dupa")
                ForEach(vm.dataArray) { post in
                    Text(post.title)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        DependencyInjectionBootcamp()
    }
}
