import SwiftUI
import SDWebImageSwiftUI


// Movie構造体: 映画の情報を格納するためのモデルです。
// IdentifiableはIDを持つことを意味し、DecodableとEncodableはJSONエンコーディング/デコーディングをサポートすることを意味します。
struct Movie: Identifiable, Decodable, Encodable {
    // プロパティ: 映画の各種情報を定義
    var id: Int
    var title: String
    var thumbnailURL: String
    var overview: String
    var release_date: String
    var vote_average: Float
    var original_language: String
    // ...
    // CodingKeys: JSONのキーとプロパティのマッピングを定義
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnailURL = "poster_path"
        case overview
        case release_date
        case vote_average
        case original_language
    }
}

// PopularViewModel: 映画のリストをフェッチして保持するためのViewModel。
class PopularViewModel: ObservableObject {
    @Published var movies: [Movie] = []

    func fetchPopularMovies() {
        guard let accessToken = ProcessInfo.processInfo.environment["API_read_access_token"] else {
            print("Access token not found")
            return
        }

        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        // APIから映画データを取得し、JSONとしてデコードする処理
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                // APIからの応答をプリントして確認
                print(String(data: data, encoding: .utf8) ?? "Invalid response")

                do {
                    let decodedResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.movies = decodedResponse.results
                    }
                } catch {
                    print("Decoding failed: \(error)")
                }
            }

        }.resume()
    }
}

// MovieResponse構造体: APIレスポンスのためのモデルです。
struct MovieResponse: Decodable {
    var results: [Movie]
}

// PopularView: UIを表現するViewコンポーネント。
struct PopularView: View {
    @StateObject var viewModel = PopularViewModel()
    @State private var favoritedMovies: [Int: Bool] = [:]
    @State private var showingDetails = false
    @State private var selectedMovie: Movie?

    var body: some View {
        // 映画リストを表示するためのリストビュー
        List(viewModel.movies, id: \.id) { movie in
            // 各映画のレイアウトを定義
            HStack {
                // 映画の画像を表示
                // SDWebImageSwiftUIを使用して映画の画像を表示
                WebImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.thumbnailURL)"))
                    .resizable()
                    .frame(width: 80, height: 120)

                VStack(alignment: .leading) {
                    // 映画のタイトルや評価などの詳細を表示
                    Text(movie.title)
                        .bold()
                        .frame(width: 200, alignment: .leading)

                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", movie.vote_average))
                        Text(movie.original_language)
                            .foregroundColor(.white)
                            .background(.gray)
                            .cornerRadius(5.0)
                    }

                    Text(movie.release_date)
                        .frame(width: 200, alignment: .leading)

                    Text(movie.overview)
                        .frame(width: 200, alignment: .leading)
                        .lineLimit(3)
                        .truncationMode(.tail)
                }
            }
            .onTapGesture {
                            self.selectedMovie = movie
                            self.showingDetails = true
                        }
        }
        .sheet(isPresented: $showingDetails) {
                    // 映画の詳細を表示するビュー
                    if let movie = selectedMovie {
                        MovieDetailView(movie: movie)
                    }
                }
        // ビューが表示された時と更新が必要な時に映画リストをフェッチ
        .onAppear {
            viewModel.fetchPopularMovies()
        }
        .refreshable {
            viewModel.fetchPopularMovies()
        }
    }

    private func saveToFavorites(saveMovie: Movie) {
        // 選択した映画をお気に入りに保存するロジック
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(saveMovie) {
            let count = UserDefaults.standard.integer(forKey: "count")
            var isDuplicate = false

            for i in 1...count {
                if let savedData = UserDefaults.standard.object(forKey: String(i)) as? Data,
                   let savedMovie = try? JSONDecoder().decode(Movie.self, from: savedData) {
                    if savedMovie.id == saveMovie.id {
                        // 重複が見つかった場合、削除
                        UserDefaults.standard.removeObject(forKey: String(i))
                        isDuplicate = true
                        break
                    }
                }
            }

            if !isDuplicate {
                // 新しい映画を保存
                UserDefaults.standard.set(encoded, forKey: String(count + 1))
                UserDefaults.standard.set(count + 1, forKey: "count")
            }
        }
        
    }
}


// MovieDetailView: 映画の詳細情報を表示するためのビュー
struct MovieDetailView: View {
    var movie: Movie
    @State private var isFavorite: Bool = false

    
    var body: some View {
        VStack {
            // 映画の詳細情報を表示
            Text(movie.title).font(.title)
            WebImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.thumbnailURL)"))
                .resizable()
                .frame(width: 200, height: 300)
            Text("Release Date: \(movie.release_date)")
            Text("Rating: \(String(movie.vote_average))")
            Text("Language: \(movie.original_language)")
            Text("Overview:")
                .font(.headline)
            ScrollView {
                Text(movie.overview)
            }
            // お気に入りボタン
            Button(action: {
                self.isFavorite.toggle()
                saveToFavorites(saveMovie: movie)
            }) {
                Text(isFavorite ? "お気に入りを解除する" : "お気に入り登録する")
                    .foregroundColor(.white)
                                   .frame(minWidth: 0, maxWidth: .infinity)
                                   .padding()
                                   .background(isFavorite ? Color.gray : Color.blue)
                                   .cornerRadius(10)
            }
        }
        .padding()
    }
    private func saveToFavorites(saveMovie: Movie) {
        // 選択した映画をお気に入りに保存するロジック
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(saveMovie) {
            let count = UserDefaults.standard.integer(forKey: "count")
            var isDuplicate = false

            for i in 1...count {
                if let savedData = UserDefaults.standard.object(forKey: String(i)) as? Data,
                   let savedMovie = try? JSONDecoder().decode(Movie.self, from: savedData) {
                    if savedMovie.id == saveMovie.id {
                        // 重複が見つかった場合、削除
                        UserDefaults.standard.removeObject(forKey: String(i))
                        isDuplicate = true
                        break
                    }
                }
            }

            if !isDuplicate {
                // 新しい映画を保存
                UserDefaults.standard.set(encoded, forKey: String(count + 1))
                UserDefaults.standard.set(count + 1, forKey: "count")
            }
        }
        
    }
    
    private func checkIfFavorite(_ movie: Movie) -> Bool {
            let count = UserDefaults.standard.integer(forKey: "count")
            for i in 1...count {
                if let savedData = UserDefaults.standard.object(forKey: String(i)) as? Data,
                   let savedMovie = try? JSONDecoder().decode(Movie.self, from: savedData) {
                    if savedMovie.id == movie.id {
                        return true
                    }
                }
            }
            return false
        }
}
