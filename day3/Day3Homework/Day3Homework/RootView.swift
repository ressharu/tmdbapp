import SwiftUI

enum Tab {
    case popular
    case favorite
}

struct RootView: View {
    var body: some View {
        TabView {
            PopularView()
                .tag(Tab.popular)
                .tabItem {
                    Label(
                        title: { Text("人気") },
                        icon: { Image(systemName: "crown.fill") }
                    )
                }
                FavoriteView()
                .tag(Tab.favorite)
                .tabItem {
                    Label(
                        title: { Text("お気に入り") },
                        icon: { Image(systemName: "list.star") }
                    )
                }
        }
    }
}


#Preview {
    RootView()
}

