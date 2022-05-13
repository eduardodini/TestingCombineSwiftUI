//
//  ContentView.swift
//  TestingCombineSwiftUI
//
//  Created by Eduardo Dini on 13/05/22.
//

import SwiftUI
import Combine

// Model
struct User: Decodable, Identifiable {
    let id: Int
    let name: String
}

// ViewModel
final class ViewModel: ObservableObject {
    @Published var time = ""
    @Published var users = [User]()
    private var cancellable = Set<AnyCancellable>()

    let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }()

    init() {
        setupPublisher()
    }

    private func setupPublisher() {
        setupTimePublisher()
        setupDataTaskPublisher()
    }

    private func setupTimePublisher() {
        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink { value in
                self.time = self.formatter.string(from: value)
            }
            .store(in: &cancellable)
    }

    private func setupDataTaskPublisher() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data, response) in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: [User].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { users in
                self.users = users
            })
            .store(in: &cancellable)
    }

}

// View
struct ContentView: View {

    @StateObject var viewModel = ViewModel()

    var body: some View {
        VStack {
            Text(viewModel.time)
                .padding()
            List(viewModel.users) { user in
                Text(user.name)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
