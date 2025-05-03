import SwiftUI

struct HideAndSeekGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GameViewModel

    @State private var targetIndex: Int = 0
    @State private var revealed: [Bool] = Array(repeating: false, count: 12)

    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    private let indices = Array(0..<12)

    var body: some View {
        ZStack {
            // 幼児向けパステル背景
            Color(red: 1.0, green: 0.95, blue: 0.7)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                // タイトル
                Text(viewModel.getLocalizedAnimalCareText(key: "hideAndSeek_title"))
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.purple)
                    .shadow(color: .purple.opacity(0.5), radius: 2, x: 0, y: 2)
                    .padding(.top)
                // 指示 / フィードバック
                Text(viewModel.getLocalizedAnimalCareText(key: currentKey))
                    .font(.headline)
                    .foregroundColor(.brown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // グリッド
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(indices, id: \.self) { i in
                        Button(action: { clickBox(i) }) {
                            ZStack {
                                // 箱画像
                                Image(revealed[i] ? "box_open" : "box_close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                // 子犬 or × マーク
                                if revealed[i] {
                                    if i == targetIndex {
                                        Image("puppy_idle_1")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 160, height: 160)
                                    } else {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 140, height: 140)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            // 白いカード風の装飾
                            .padding(8)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(revealed[i])
                    }
                }
                .padding(.horizontal)

                // リトライ／終了
                if revealed.contains(true) {
                    HStack(spacing: 20) {
                        Button(viewModel.getLocalizedAnimalCareText(key: "hideAndSeek_retry")) {
                            startGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.title)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .frame(minWidth: 180)

                        Button(viewModel.getLocalizedAnimalCareText(key: "hideAndSeek_closeButton")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(.bordered)
                        .font(.title)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                    }
                    .padding(.top)
                }

                Spacer()
            }
        }
        .onAppear { startGame() }
    }

    private var currentKey: String {
        if !revealed.contains(true) {
            return "hideAndSeek_instructions"
        }
        return revealed[targetIndex] ? "hideAndSeek_correct" : "hideAndSeek_wrong"
    }

    private func clickBox(_ index: Int) {
        if !revealed[index] {
            revealed[index] = true
            if index == targetIndex {
                viewModel.puppyHappiness = min(viewModel.puppyHappiness + 25, 100)
            } else {
                viewModel.puppyHappiness = max(viewModel.puppyHappiness - 5, 0)
            }
        }
    }

    private func startGame() {
        targetIndex = indices.randomElement()!
        revealed = Array(repeating: false, count: indices.count)
    }
} 