import SwiftUI
import SDWebImageSwiftUI

struct FavoriteView: View {
    @State private var favoritedMovies: [Movie] = []
    @State private var showingDetails = false
    @State private var selectedMovie: Movie?

    var body: some View {
        List(favoritedMovies, id: \.id) { movie in
            HStack {
                WebImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.thumbnailURL)"))
                    .resizable()
                    .frame(width: 80, height: 120)
                VStack(alignment: .leading) {
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
            .swipeActions {
                Button(role: .destructive) {
                    removeFavorite(movie: movie)
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingDetails) {
                    // ポップアップとしてMovieDetailView2を表示
                    if let movie = selectedMovie {
                        MovieDetailView2(movie: movie)
                    }
                }
        .onAppear {
            loadFavorites()
        }
        .refreshable {
            loadFavorites()
        }
    }

    private func loadFavorites() {
        // UserDefaultsからお気に入り映画の数を取得
        let count = UserDefaults.standard.string(forKey: "count") ?? "0"
        var loadedMovies: [Movie] = []
        let decoder = JSONDecoder()

        for i in 1...Int(count)! {
            // UserDefaultsから映画データを取得し、デコード
            if let savedMovie = UserDefaults.standard.object(forKey: String(i)) as? Data {
                if let decodedMovie = try? decoder.decode(Movie.self, from: savedMovie) {
                    loadedMovies.append(decodedMovie)
                }
            }
        }

        favoritedMovies = loadedMovies
    }

    private func removeFavorite(movie: Movie) {
        // 特定の映画をUserDefaultsから削除する処理
        if let index = favoritedMovies.firstIndex(where: { $0.id == movie.id }) {
            UserDefaults.standard.removeObject(forKey: "\(movie.id)")
            favoritedMovies.remove(at: index)
            // お気に入りの数を更新
            let newCount = favoritedMovies.count
            UserDefaults.standard.set("\(newCount)", forKey: "count")
        }
    }
}

// MovieDetailView: 映画の詳細情報を表示するためのビュー
struct MovieDetailView2: View {
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
                Text(isFavorite ? "お気に入り登録する" : "お気に入りを解除する")
                    .foregroundColor(.white)
                                   .frame(minWidth: 0, maxWidth: .infinity)
                                   .padding()
                                   .background(isFavorite ? Color.blue : Color.gray)
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

