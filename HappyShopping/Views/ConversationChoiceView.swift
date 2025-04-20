import SwiftUI

struct ConversationChoiceView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            Text("子犬に話しかける")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x5D4037))
                .padding(.top, 30)
            
            Text("どんな話をする？")
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(Color(hex: 0x8D6E63))
                .padding(.bottom, 10)
            
            // 選択肢ボタン
            VStack(spacing: 15) {
                ForEach(viewModel.conversationChoicesArray, id: \.userPrompt) { choice in
                    Button(action: {
                        // 選択された選択肢に対して子犬が応答
                        viewModel.respondToUserChoice(choice: choice)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(choice.userPrompt)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: 0x8D6E63))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: 0xE0E0E0), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // キャンセルボタン
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("キャンセル")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: 0x757575))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(Color(hex: 0xF5F5F5))
                    .cornerRadius(25)
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xFAFAFA))
        .cornerRadius(20)
        .edgesIgnoringSafeArea(.bottom)
    }
}

// プレビュー用
struct ConversationChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationChoiceView(viewModel: GameViewModel())
    }
} 