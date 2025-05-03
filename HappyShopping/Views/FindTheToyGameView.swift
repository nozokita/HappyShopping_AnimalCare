import SwiftUI
import AVFoundation

struct FindTheToyGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GameViewModel

    // ゲーム状態
    @State private var targetToy: Toy? = nil
    @State private var displayedToys: [Toy] = []
    @State private var messageKey: String = "findToy_instructions"
    @State private var isGameOver: Bool = false
    @State private var showFeedback: Bool = false
    @State private var feedbackCorrect: Bool = false

    // グリッドの定義
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3) // 3列グリッド

    var body: some View {
        ZStack {
            // 背景色
            Color.orange.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 1. タイトル
                Text(viewModel.getLocalizedAnimalCareText(key: "findToy_title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xBF360C))

                // 2. 指示メッセージ or フィードバック
                if let target = targetToy {
                    let instructionText = viewModel.getLocalizedAnimalCareText(key: messageKey)
                    let toyName = viewModel.getLocalizedAnimalCareText(key: "\(target.key)_name")
                    let fullInstruction = instructionText.replacingOccurrences(of: "この おもちゃ", with: toyName)
                                                    .replacingOccurrences(of: "Find this toy", with: toyName)
                    
                    Text(isGameOver ? viewModel.getLocalizedAnimalCareText(key: messageKey) : fullInstruction)
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(feedbackCorrect ? Color.green : (messageKey == "findToy_wrong" ? Color.red : Color(hex: 0x5D4037)))
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: messageKey)
                }

                // 3. おもちゃグリッド
                LazyVGrid(columns: columns, spacing: 25) {
                    ForEach(displayedToys) { toy in
                        Button { // タップ時のアクション
                            if !isGameOver {
                                toyTapped(toy)
                            }
                        } label: {
                            Image(toy.imageName) // おもちゃの画像
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .padding(10)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(15)
                                .shadow(radius: 3)
                        }
                        .buttonStyle(PlainButtonStyle()) // ボタンのデフォルトスタイルを解除
                        .disabled(isGameOver)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // 4. ゲーム終了ボタン（ゲームオーバー時に表示）
                if isGameOver {
                    Button(viewModel.getLocalizedAnimalCareText(key: "findToy_closeButton")) {
                        presentationMode.wrappedValue.dismiss() // シートを閉じる
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 40)
                    .background(Color.orange)
                    .cornerRadius(25)
                    .shadow(radius: 3)
                    .transition(.scale.combined(with: .opacity)) // 表示アニメーション
                }
                
                Spacer(minLength: 30)
            }
            .padding(.vertical, 30)
        }
        .onAppear {
            setupGame()
        }
    }

    // ゲームの初期設定
    func setupGame() {
        let toys = viewModel.availableToys // ローカル変数にコピー
        guard !toys.isEmpty else {
            print("Error: No available toys found.")
            messageKey = "エラー"
            return
        }
        
        // ターゲットのおもちゃをランダムに選択
        targetToy = toys.randomElement()!
        
        // 表示するおもちゃリストを作成 (ターゲット + ダミー3つ)
        var toysToShow = [targetToy!]
        let currentTargetKey = targetToy!.key // キーをキャプチャ
        var distractors = toys.filter { $0.key != currentTargetKey }.shuffled()
        let neededDistractors = min(distractors.count, 3) // 最大3つのダミー
        toysToShow.append(contentsOf: distractors.prefix(neededDistractors))
        
        // リストをシャッフル
        displayedToys = toysToShow.shuffled()
        
        // 初期メッセージを設定
        messageKey = "findToy_instructions"
        isGameOver = false
        showFeedback = false
    }

    // おもちゃがタップされた時の処理
    func toyTapped(_ tappedToy: Toy) {
        guard let target = targetToy else { return }

        if tappedToy.key == target.key {
            // 正解
            messageKey = "findToy_correct"
            isGameOver = true
            feedbackCorrect = true
            // 機嫌をアップ（ゲーム成功ボーナス）
            viewModel.puppyHappiness = min(viewModel.puppyHappiness + 25, 100) // 正解で25アップ
            viewModel.updateLastInteraction() // 操作時間も更新
            playSound("success") // 正解音
        } else {
            // 不正解
            messageKey = "findToy_wrong"
            feedbackCorrect = false
            // 不正解ペナルティ（少し機嫌ダウン）
            viewModel.puppyHappiness = max(viewModel.puppyHappiness - 5, 0)
            playSound("failure") // 不正解音
            // メッセージを少し遅れてリセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // ゲームオーバーになっていなければ指示に戻す
                if !isGameOver {
                    messageKey = "findToy_instructions"
                }
            }
        }
        showFeedback = true
    }
    
    // 効果音再生ヘルパー
    private func playSound(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            // メモリリークを防ぐため、再生終了後にplayerを解放する仕組みが必要だが、
            // このビュー内では簡易的に再生のみ行う
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}

// プレビュー用
struct FindTheToyGameView_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用にいくつかおもちゃを設定したViewModelを作成
        let previewViewModel = GameViewModel()
//        previewViewModel.availableToys = [
//            Toy(key: "toy_ball", imageName: "toy_ball"),
//            Toy(key: "toy_bone", imageName: "toy_bone"),
//            Toy(key: "toy_duck", imageName: "toy_duck"),
//            Toy(key: "toy_plush", imageName: "toy_plush")
//        ]
        return FindTheToyGameView(viewModel: previewViewModel)
    }
}
 