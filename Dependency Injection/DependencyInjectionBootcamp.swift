//
//  DependencyInjectionBootcamp.swift
//  Dependency Injection
//
//  Created by Marcin Jędrzejak on 14/07/2023.
//

// Link: https://www.youtube.com/watch?v=E3x07blYvdE&ab_channel=SwiftfulThinking

import SwiftUI
import Combine

// PROBLEMS WITH SINGLETONS
// 1. Singleton's are GLOBAL
// 2. Can't customize the init!
// 3. Can't swap out dependencies

struct PostsModel: Identifiable, Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

protocol DataServiceProtocol {
    func getData() -> AnyPublisher<[PostsModel], Error>
}

class ProductionDataService: DataServiceProtocol {
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func getData() -> AnyPublisher<[PostsModel], Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map({ $0.data })
            .decode(type: [PostsModel].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

class MockDataService: DataServiceProtocol {
    
    let testData: [PostsModel]
    
    init(data: [PostsModel]?) {
        self.testData = data ?? [
            PostsModel(userId: 1, id: 1, title: "One", body: "one"),
            PostsModel(userId: 2, id: 2, title: "Two", body: "two")
        ]
    }
    
    func getData() -> AnyPublisher<[PostsModel], Error> {
        Just(testData)
            .tryMap({ $0 })
            .eraseToAnyPublisher()
    }
}

class DependencyInjectionViewModel: ObservableObject {
    
    @Published var dataArray: [PostsModel] = []
    
    var cancellables = Set<AnyCancellable>()
//    let dataService: ProductionDataService
    let dataService: DataServiceProtocol
    
//    init(dataService: ProductionDataService) {
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
        loadPosts()
    }
    
    private func loadPosts() {
        dataService.getData()
            .sink { _ in
                
            } receiveValue: { [weak self] returnedPosts in
                self?.dataArray = returnedPosts
            }
            .store(in: &cancellables)
    }
}

struct DependencyInjectionBootcamp: View {
    
    @StateObject private var vm: DependencyInjectionViewModel
    
//    init(dataService: ProductionDataService) {
    init(dataService: DataServiceProtocol) {
        _vm = StateObject(wrappedValue: DependencyInjectionViewModel(dataService: dataService))
    }
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(vm.dataArray) { post in
                    Text(post.title)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
//    static let dataService = ProductionDataService(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
    static let dataService = MockDataService(data: [
    PostsModel(userId: 1234, id: 1234, title: "test", body: "test")
    ])
    
    static var previews: some View {
        DependencyInjectionBootcamp(dataService: dataService)
    }
}
