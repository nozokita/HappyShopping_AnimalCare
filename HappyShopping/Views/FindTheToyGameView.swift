import SwiftUI

struct FindTheToyGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GameViewModel // viewModelを受け取る

    var body: some View {
        VStack {
            Text(viewModel.getLocalizedAnimalCareText(key: "findToy_title")) // ローカライズ
                .font(.largeTitle)
                .padding()
            
            Text(viewModel.getLocalizedAnimalCareText(key: "findToy_placeholder")) // ローカライズ
                .padding()
            
            Button(viewModel.getLocalizedAnimalCareText(key: "findToy_closeButton")) {
                // TODO: ゲーム結果に応じて機嫌をアップさせる
                viewModel.puppyHappiness = min(viewModel.puppyHappiness + 20, 100) // 仮で機嫌を20アップ
                viewModel.updateLastInteraction() // 操作時間も更新
                presentationMode.wrappedValue.dismiss() // シートを閉じる
            }
            .padding()
        }
    }
}

// プレビュー用
struct FindTheToyGameView_Previews: PreviewProvider {
    static var previews: some View {
        FindTheToyGameView(viewModel: GameViewModel()) // プレビュー用にviewModelを渡す
    }
} 