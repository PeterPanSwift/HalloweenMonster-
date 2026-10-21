import SwiftUI

struct ContentView: View {
    @StateObject private var model = MonsterViewModel()
    @State private var showFavorites = false

    private let pumpkin = Color(red: 1, green: 0.5, blue: 0.05)

    var body: some View {
        GeometryReader { geo in
            // iPhone Duo unfolded (and landscape) gives a wide canvas: put the picture next to the details.
            let isWide = geo.size.width > 600 || geo.size.width > geo.size.height * 1.2

            ZStack {
                HauntedBackground()

                VStack(spacing: 16) {
                    header
                    Picker("圖片來源", selection: $model.source) {
                        ForEach(ImageSource.allCases) { source in
                            Text(source.title).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("sourcePicker")
                    .onChange(of: model.source) { _, _ in model.summon() }

                    if isWide {
                        HStack(alignment: .center, spacing: 24) {
                            portrait
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            VStack(spacing: 16) {
                                details
                                Spacer(minLength: 0)
                                actions
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        portrait
                            .frame(maxHeight: .infinity)
                        details
                        actions
                    }
                }
                .padding()
            }
        }
        .task {
            if model.monster == nil { model.summon() }
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(favorites: model.favorites)
                .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🎃 萬聖節怪物召喚機")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(pumpkin)
                Text("已召喚 \(model.summonCount) 隻怪物")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("summonCount")
            }
            Spacer()
            Button {
                showFavorites = true
            } label: {
                Label("\(model.favorites.count)", systemImage: "heart.text.square.fill")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .tint(pumpkin)
            .accessibilityIdentifier("favoritesButton")
        }
    }

    @ViewBuilder
    private var portrait: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(pumpkin.opacity(0.6), lineWidth: 2)
                )
                .shadow(color: pumpkin.opacity(0.35), radius: 24)

            switch model.phase {
            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(pumpkin)
                    Text("正在從網路召喚怪物…")
                        .foregroundStyle(.secondary)
                }
            case .failed(let message):
                VStack(spacing: 12) {
                    Text("🕸️").font(.system(size: 64))
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            case .loaded:
                if let monster = model.monster {
                    Image(uiImage: monster.image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(16)
                        .id(monster.id)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.3).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .accessibilityLabel("\(monster.name)的圖片")
                        .accessibilityIdentifier("monsterImage")
                }
            }
        }
    }

    @ViewBuilder
    private var details: some View {
        if let monster = model.monster {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(monster.emoji) \(monster.name)")
                        .font(.title.weight(.bold))
                        .accessibilityIdentifier("monsterName")
                    Spacer()
                    Text(monster.species)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(pumpkin.opacity(0.25), in: Capsule())
                }
                HStack(spacing: 4) {
                    Text("恐怖指數")
                        .foregroundStyle(.secondary)
                    ForEach(1...5, id: \.self) { level in
                        Text(level <= monster.fear ? "💀" : "▫️")
                    }
                }
                Label(monster.power, systemImage: "wand.and.stars")
                Label("弱點：\(monster.weakness)", systemImage: "bolt.heart")
                Text(monster.credit)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .id(monster.id)
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                model.toggleFavorite()
            } label: {
                Image(systemName: model.isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .tint(.pink)
            .disabled(model.monster == nil)
            .accessibilityIdentifier("favoriteButton")

            Button {
                model.summon()
            } label: {
                Text(model.isLoading ? "召喚中…" : "召喚怪物 👻")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        LinearGradient(colors: [pumpkin, Color(red: 0.85, green: 0.2, blue: 0.05)], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .foregroundStyle(.black)
            }
            .accessibilityIdentifier("summonButton")
        }
    }
}

struct FavoritesView: View {
    let favorites: [Monster]

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView("還沒有收藏的怪物", systemImage: "heart.slash", description: Text("按下愛心把喜歡的怪物收藏起來"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                            ForEach(favorites) { monster in
                                VStack(spacing: 6) {
                                    Image(uiImage: monster.image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    Text("\(monster.emoji) \(monster.name)")
                                        .font(.headline)
                                        .lineLimit(1)
                                }
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("我的怪物收藏")
            .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityIdentifier("favoritesSheet")
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
