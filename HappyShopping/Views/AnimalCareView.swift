import SwiftUI

struct AnimalCareView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showStatusMessage: Bool = false
    @State private var statusMessage: String = ""
    @State private var showMiniGame: Bool = false
    @State private var showNameInputDialog: Bool = false
    @State private var showOwnerNameInputDialog: Bool = false
    @State private var animationTimer: Timer? = nil
    
    // 画面サイズ取得用
    @State private var containerSize: CGSize = .zero
    
    // 背景切り替え用のデバッグボタンを表示するかどうか（開発時のみtrue）
    private let showDebugToggle = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色（画像がカバーしきれない部分用）
                Color(hex: viewModel.isDaytime ? 0xE1F5FE : 0x263238)
                    .ignoresSafeArea()
                
                // 背景画像
                Image(viewModel.isDaytime ? "bg_room_day_portrait" : "bg_room_night_portrait")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height * 1.1)
                    .scaleEffect(1.15) // 1.15に戻して適切なズーム率を維持
                    .offset(y: -20) // 上に少しずらして下部をカバー
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 1.0), value: viewModel.isDaytime)
                
                VStack(spacing: 16) {
                    // ヘッダー
                    HStack {
                        // ホームボタン
                        Button(action: {
                            viewModel.gameState = .initialSelection
                        }) {
                            Image(systemName: "house.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: 0x795548))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(22)
                                .shadow(radius: 2)
                        }
                        
                        Spacer()
                        
                        Text(viewModel.getLocalizedAnimalCareText(key: "room_title"))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x4E342E))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        
                        Spacer()
                        
                        // 時計アイコン
                        Text(formattedLastCareTime)
                            .font(.caption)
                            .foregroundColor(Color(hex: 0x795548))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(22)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // デバッグ用時間切り替えボタン（開発用）
                    if showDebugToggle {
                        Button(action: {
                            viewModel.toggleTimeOfDay()
                        }) {
                            Text(viewModel.isDaytime ? "🌞 昼間 → 🌙 夜に切替" : "🌙 夜 → 🌞 昼間に切替")
                                .font(.caption)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    
                    // 子犬の名前と飼育日数パネル
                    VStack(spacing: 4) {
                        HStack {
                            // 名前ラベル
                            Text(viewModel.puppyName == "まだ名前がありません" ? viewModel.getLocalizedAnimalCareText(key: "name_placeholder") : viewModel.puppyName)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                            
                            // 名前変更ボタン
                            Button(action: {
                                showNameInputDialog = true
                            }) {
                                Image(systemName: "pencil.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: 0x8D6E63))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            // 飼育日数
                            Text(viewModel.getLocalizedAnimalCareText(key: "days_together").replacingOccurrences(of: "{days}", with: "\(viewModel.puppyDaysWithYou)"))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: 0x8D6E63))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: 0xFFF3E0).opacity(0.8))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                    
                    // ステータスパネル
                    VStack(spacing: 8) {
                        // パネルヘッダー
                        HStack {
                            Text(viewModel.getLocalizedAnimalCareText(key: "status"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                            Spacer()
                            // 自動更新インジケーター
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                Text(viewModel.getLocalizedAnimalCareText(key: "auto_update"))
                                    .font(.caption2)
                            }
                            .foregroundColor(Color(hex: 0x9E9E9E))
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                        
                        Divider()
                            .background(Color(hex: 0xE0E0E0))
                            .padding(.horizontal, 8)
                        
                        // 満腹度
                        HStack {
                            Image(systemName: statusIcon(for: viewModel.puppyHunger, type: "hunger"))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(statusColor(for: viewModel.puppyHunger))
                                .cornerRadius(6)
                                .shadow(radius: 1)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.getLocalizedAnimalCareText(key: "stomach"))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: 0x5D4037))
                                
                                ProgressBar(value: viewModel.puppyHunger, color: statusColor(for: viewModel.puppyHunger))
                                    .frame(height: 7)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        
                        // 機嫌
                        HStack {
                            Image(systemName: statusIcon(for: viewModel.puppyHappiness, type: "happiness"))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(statusColor(for: viewModel.puppyHappiness))
                                .cornerRadius(6)
                                .shadow(radius: 1)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.getLocalizedAnimalCareText(key: "mood"))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: 0x5D4037))
                                
                                ProgressBar(value: viewModel.puppyHappiness, color: statusColor(for: viewModel.puppyHappiness))
                                    .frame(height: 7)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8) // パディングを縮小して縦スペースを確保
                    
                    // アニメーション表示エリア
                    ZStack {
                        // 床の影 - 下部に配置して床に接地しているように見せる
                        Ellipse()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 220, height: 55)
                            .offset(y: geometry.size.height * 0.15)
                            .zIndex(0)
                        
                        // 子犬のアニメーション表示
                        PuppyAnimationView(viewModel: viewModel, size: CGSize(width: geometry.size.width, height: geometry.size.height * 0.4))
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                            .scaleEffect(1.15) // 子犬自体のサイズを15%拡大
                            .zIndex(1)
                        
                        // インライン会話選択肢（子犬の近くに表示）
                        if viewModel.showInlineConversationChoices {
                            VStack(spacing: 12) {
                                ForEach(viewModel.conversationChoicesArray, id: \.userPrompt) { choice in
                                    Button(action: {
                                        // 選択された会話に応答
                                        selectConversation(choice)
                                    }) {
                                        Text(choice.userPrompt)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(Color(hex: 0x5D4037))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .fill(Color.white.opacity(0.95))
                                                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .stroke(Color(hex: 0xE0E0E0), lineWidth: 1)
                                            )
                                    }
                                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .offset(y: -40) // 子犬の上に配置
                            .transition(.opacity)
                            .zIndex(2)
                        }
                        
                        // ステータスメッセージ
                        if showStatusMessage {
                            VStack {
                                Text(statusMessage)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: 0x5D4037))
                                    .padding(12)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.9))
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white, lineWidth: 1.5)
                                        }
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        // 吹き出しの矢印
                                        Triangle()
                                            .fill(Color.white.opacity(0.9))
                                            .frame(width: 20, height: 10)
                                            .rotationEffect(.degrees(180))
                                            .offset(y: 12),
                                        alignment: .bottom
                                    )
                            }
                            .offset(y: -110)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6)),
                                    removal: .opacity.animation(.easeOut(duration: 0.2))
                                )
                            )
                            .zIndex(3)
                        }
                    }
                    .frame(height: geometry.size.height * 0.4) // 表示エリアを小さく
                    
                    // アニメーション表示とアクションパネルの間にスペーサーを追加
                    Spacer(minLength: 15)
                    
                    // アクションパネル
                    VStack(spacing: 3) {
                        // パネルヘッダー
                        HStack {
                            Text(viewModel.getLocalizedAnimalCareText(key: "action"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        
                        Divider()
                            .background(Color(hex: 0xE0E0E0))
                            .padding(.horizontal, 8)
                            .padding(.bottom, 2)
                        
                        // アクションボタングリッド
                        HStack(spacing: 20) {
                            // 餌やりボタン
                            ActionButton(
                                action: feedAction,
                                imageName: "icon_feed",
                                color: .orange,
                                isDisabled: viewModel.puppyHunger >= 90
                            )
                            
                            // 遊ぶボタン
                            ActionButton(
                                action: playAction,
                                imageName: "icon_play",
                                color: .orange,
                                isDisabled: viewModel.showPlayingAnimation
                            )
                            
                            // 撫でるボタン
                            ActionButton(
                                action: petAction,
                                imageName: "icon_pet",
                                color: .purple,
                                isDisabled: viewModel.showPettingAnimation
                            )
                            
                            // 掃除ボタン
                            ActionButton(
                                action: cleanAction,
                                imageName: "icon_clean",
                                color: .green,
                                isDisabled: viewModel.poopCount == 0 || viewModel.showCleaningAnimation
                            )
                            
                            // 会話ボタン
                            ActionButtonSF(
                                action: conversationAction,
                                systemName: "bubble.left.fill",
                                color: .cyan,
                                isDisabled: viewModel.showConversationBubble || viewModel.showInlineConversationChoices,
                                iconSize: 16,
                                circleSize: 40
                            )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 5) // 底部パディングをさらに減らす
                    
                    // 下部に小さなスペーサーを追加（上に押し上げすぎないように調整）
                    Spacer(minLength: 10)
                }
            }
            .onAppear {
                // 画面表示時に最新の状態に更新
                viewModel.updatePuppyStatus()
                
                // 時間帯の自動切り替えを開始
                viewModel.startTimeOfDayTimer()
                
                // 子犬との操作時間を更新
                viewModel.updateLastInteraction()
                
                // アニメーションタイマーをリセット
                animationTimer?.invalidate()
                animationTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                    // 2.5秒ごとにステータスメッセージを非表示
                    withAnimation {
                        showStatusMessage = false
                    }
                }
                
                // 飼い主名が未設定なら、名前入力ダイアログを表示
                if viewModel.ownerName.isEmpty {
                    // 少し遅延させて画面が完全に表示された後に表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOwnerNameInputDialog = true
                    }
                }
            }
            .onDisappear {
                // 画面を離れる時にタイマーを停止
                viewModel.stopTimeOfDayTimer()
                
                // アニメーションタイマーを無効化
                animationTimer?.invalidate()
                animationTimer = nil
            }
        }
        .sheet(isPresented: $showNameInputDialog) {
            PuppyNameInputView(viewModel: viewModel, isPresented: $showNameInputDialog)
        }
        .sheet(isPresented: $showOwnerNameInputDialog) {
            OwnerNameInputView(viewModel: viewModel, isPresented: $showOwnerNameInputDialog)
        }
    }
    
    // 最終ケア時刻のフォーマット
    var formattedLastCareTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: viewModel.lastAnimalCareTime)
    }
    
    // ステータスに応じたアイコンを取得
    func statusIcon(for value: Double, type: String) -> String {
        if type == "hunger" {
            if value < 30 { return "exclamationmark.triangle.fill" }
            if value < 70 { return "fork.knife" }
            return "fork.knife.circle.fill"
        } else {
            if value < 30 { return "heart.slash.fill" }
            if value < 70 { return "heart" }
            return "heart.fill"
        }
    }
    
    // ステータスに応じた色を取得
    func statusColor(for value: Double) -> Color {
        if value < 30 { return Color(hex: 0xF44336) }
        if value < 70 { return Color(hex: 0xFF9800) }
        return Color(hex: 0x4CAF50)
    }
    
    // 餌やりアクション
    private func feedAction() {
        if !viewModel.showEatingAnimation { // 既に食事中なら何もしない
            viewModel.feedPuppy()
            statusMessage = viewModel.getLocalizedAnimalCareText(key: "fed_message")
            showStatusMessage = true
            
            // 操作時間を更新
            viewModel.updateLastInteraction()
        }
    }
    
    // 遊びアクション
    private func playAction() {
        if !viewModel.showPlayingAnimation { // 既に遊んでいる途中なら何もしない
            viewModel.playWithPuppy()
            statusMessage = viewModel.getLocalizedAnimalCareText(key: "played_message")
            showStatusMessage = true
            
            // 操作時間を更新
            viewModel.updateLastInteraction()
        }
    }
    
    // 撫でるアクション
    private func petAction() {
        if !viewModel.showPettingAnimation { // 既に撫でている途中なら何もしない
            viewModel.puppyHappiness = min(viewModel.puppyHappiness + 5, 100)
            viewModel.showPettingAnimation = true
            statusMessage = viewModel.getLocalizedAnimalCareText(key: "petted_message")
            showStatusMessage = true
            
            // 操作時間を更新
            viewModel.updateLastInteraction()
        }
    }
    
    // うんち掃除アクション
    private func cleanAction() {
        if viewModel.poopCount > 0 && !viewModel.showCleaningAnimation { // うんちがあり、掃除中でなければ
            viewModel.cleanPoops()
            viewModel.showCleaningAnimation = true
            statusMessage = viewModel.getLocalizedAnimalCareText(key: "cleaned_message")
            showStatusMessage = true
            
            // 操作時間を更新
            viewModel.updateLastInteraction()
        }
    }
    
    // 会話アクション
    private func conversationAction() {
        if !viewModel.showConversationBubble && !viewModel.showInlineConversationChoices {
            // 通常タップは会話選択肢を表示
            showInlineConversationChoices()
            statusMessage = viewModel.getLocalizedAnimalCareText(key: "talking_message")
            showStatusMessage = true
        }
    }

    // インライン会話選択肢の表示（タップ時）- 直接表示（新）
    private func showInlineConversationChoices() {
        // 選択肢を生成
        let shuffledChoices = viewModel.conversationChoices.shuffled()
        viewModel.conversationChoicesArray = Array(shuffledChoices.prefix(2))
        viewModel.showInlineConversationChoices = true
        
        // 操作時間も更新
        viewModel.updateLastInteraction()
    }

    // 会話選択肢を選んだときの処理
    private func selectConversation(_ choice: GameViewModel.ConversationChoice) {
        // 選択された会話に子犬が応答
        if let response = choice.puppyResponses.randomElement() {
            viewModel.currentConversation = response
            viewModel.showConversationBubble = true
            viewModel.showInlineConversationChoices = false
            
            // ステータスメッセージも表示
            statusMessage = "「\(choice.userPrompt)」と話しかけました"
            showStatusMessage = true
        }
        
        // 操作時間を更新
        viewModel.updateLastInteraction()
    }
}

// アクションボタンコンポーネント（新しいカスタムアイコン用に修正）
struct ActionButton: View {
    var action: () -> Void
    var imageName: String
    var color: Color
    var isDisabled: Bool
    
    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .opacity(isDisabled ? 0.5 : 1.0)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDisabled)
    }
}

// ステータスバーコンポーネント
struct ProgressBar: View {
    var value: Double // 0-100
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // ベース
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                
                // プログレス
                Capsule()
                    .fill(color)
                    .frame(width: min(CGFloat(value) / 100 * geometry.size.width, geometry.size.width))
            }
        }
        .frame(height: 12)
    }
}

// 三角形の描画（吹き出しの矢印用）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// プレビュー用
struct AnimalCareView_Previews: PreviewProvider {
    static var previews: some View {
        AnimalCareView(viewModel: GameViewModel())
    }
}

// 子犬の名前入力ビュー
struct PuppyNameInputView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isPresented: Bool
    @State private var newPuppyName: String = ""
    @State private var showError: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            Text(viewModel.getLocalizedAnimalCareText(key: "enter_puppy_name"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x5D4037))
                .padding(.top, 20)
            
            // 現在の名前
            if viewModel.puppyName != "まだ名前がありません" {
                Text(viewModel.getLocalizedAnimalCareText(key: "current_name") + viewModel.puppyName)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(Color(hex: 0x8D6E63))
            }
            
            // 入力フィールド
            TextField(viewModel.getLocalizedAnimalCareText(key: "enter_puppy_name_placeholder"), text: $newPuppyName)
                .font(.system(size: 18))
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: 0xBDBDBD), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .focused($isTextFieldFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTextFieldFocused = true
                    }
                }
            
            // エラーメッセージ
            if showError {
                Text(viewModel.getLocalizedAnimalCareText(key: "name_required"))
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // 飼育開始日の選択（初めて名前をつける場合のみ）
            if viewModel.puppyName == "まだ名前がありません" {
                Text(viewModel.getLocalizedAnimalCareText(key: "start_from_today"))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: 0x8D6E63))
            }
            
            // ボタン
            HStack(spacing: 20) {
                // キャンセルボタン
                Button(action: {
                    isPresented = false
                }) {
                    Text(viewModel.getLocalizedAnimalCareText(key: "cancel"))
                        .font(.system(size: 16, weight: .medium))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(Color.gray)
                        .cornerRadius(8)
                }
                
                // 保存ボタン
                Button(action: {
                    if newPuppyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showError = true
                        return
                    }
                    
                    // 名前を保存
                    viewModel.savePuppyName(newPuppyName)
                    
                    // 初めて名前を付ける場合は飼育開始日も保存
                    if viewModel.puppyName == "まだ名前がありません" {
                        viewModel.savePuppyAdoptionDate(Date())
                    }
                    
                    // ダイアログを閉じる
                    isPresented = false
                }) {
                    Text(viewModel.getLocalizedAnimalCareText(key: "save"))
                        .font(.system(size: 16, weight: .bold))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Color(hex: 0x4CAF50))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // 現在の名前を初期値としてセット（まだ名前がない場合は空文字）
            if viewModel.puppyName != "まだ名前がありません" {
                newPuppyName = viewModel.puppyName
            }
        }
    }
}

// SFSymbols用のアクションボタンコンポーネント
struct ActionButtonSF: View {
    var action: () -> Void
    var systemName: String
    var color: Color
    var isDisabled: Bool
    var iconSize: CGFloat = 20  // デフォルトサイズを設定
    var circleSize: CGFloat = 50  // 背景円のサイズ
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: circleSize, height: circleSize)
                
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(.white)
            }
            .opacity(isDisabled ? 0.5 : 1.0)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDisabled)
    }
}

// 飼い主の名前入力ビュー
struct OwnerNameInputView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isPresented: Bool
    @State private var newOwnerName: String = ""
    @State private var showError: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            Text(viewModel.getLocalizedAnimalCareText(key: "enter_your_name"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x5D4037))
                .padding(.top, 20)
                .multilineTextAlignment(.center)
            
            // 子犬画像を追加
            Image("puppy")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .padding(.vertical, 10)
            
            Text(viewModel.getLocalizedAnimalCareText(key: "puppy_will_call_you"))
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color(hex: 0x8D6E63))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 入力フィールド
            TextField(viewModel.getLocalizedAnimalCareText(key: "enter_name"), text: $newOwnerName)
                .font(.system(size: 18))
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: 0xBDBDBD), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .focused($isTextFieldFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTextFieldFocused = true
                    }
                }
            
            // エラーメッセージ
            if showError {
                Text(viewModel.getLocalizedAnimalCareText(key: "name_required"))
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // ボタンエリア
            HStack(spacing: 15) {
                // スキップボタン
                Button(action: {
                    isPresented = false
                }) {
                    Text(viewModel.getLocalizedAnimalCareText(key: "skip"))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: 0x9E9E9E))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(hex: 0xEEEEEE))
                        .cornerRadius(25)
                }
                
                // 保存ボタン
                Button(action: {
                    if newOwnerName.trimmingCharacters(in: .whitespaces).isEmpty {
                        showError = true
                    } else {
                        viewModel.saveOwnerName(newOwnerName.trimmingCharacters(in: .whitespaces))
                        isPresented = false
                    }
                }) {
                    Text(viewModel.getLocalizedAnimalCareText(key: "save"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 25)
                        .background(Color(hex: 0x8D6E63))
                        .cornerRadius(25)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: 350)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
} 