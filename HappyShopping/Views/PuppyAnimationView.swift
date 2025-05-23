import SwiftUI
import Combine

// 子犬の状態を表す列挙型
enum PuppyState {
    case idle       // 通常状態
    case walking    // 歩いている
    case eating     // 食事中
    case playing    // 遊んでいる
    case sleeping   // 寝ている
    case happy      // 嬉しい
    case sad        // 悲しい
    case hungry     // お腹が空いている
    case petting    // 撫でられている
}

// MARK: - SubViews

// うんち表示用サブビュー
struct PoopView: View {
    let position: CGPoint
    let showCleaning: Bool
    
    var body: some View {
        Image("poop")
            .resizable()
            .scaledToFit()
            .frame(width: 40)
            .position(position)
            .opacity(showCleaning ? 0 : 1)
            .animation(.easeOut(duration: 0.5), value: showCleaning)
    }
}

// 掃除エフェクト用サブビュー
struct CleaningEffectView: View {
    let position: CGPoint
    
    var body: some View {
        Text("✨")
            .font(.system(size: 30))
            .position(position)
    }
}

// 食べ物表示用サブビュー
struct FoodView: View {
    let position: CGPoint
    
    var body: some View {
        Image("food")
            .resizable()
            .scaledToFit()
            .frame(width: 60)
            .position(position)
    }
}

// 会話バブル用サブビュー
struct ConversationBubbleView: View {
    let text: String
    let position: CGPoint
    let opacity: Double
    
    var body: some View {
        VStack(spacing: 0) {
            // 吹き出し
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: 0x4E342E))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: 200)
                .multilineTextAlignment(.center)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE0E0E0), lineWidth: 1)
                )
            
            // 吹き出しの三角形
            Triangle()
                .fill(Color.white)
                .frame(width: 16, height: 8)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
        .position(position)
        .opacity(opacity)
    }
}

// MARK: - Main View
struct PuppyAnimationView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var currentState: PuppyState = .idle
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: 0)
    @State private var walkingDirection: CGFloat = 1  // 1: 右, -1: 左
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.3, on: .main, in: .common)
    @State private var timerCancellable: Cancellable? = nil
    @State private var idleCounter: Int = 0
    @State private var shouldBounce: Bool = false
    @State private var showFood: Bool = false
    @State private var foodPosition: CGPoint = CGPoint(x: 0, y: 0)
    
    // うんち関連の状態管理
    @State private var poopPositions: [CGPoint] = []
    @State private var lastPoopCount: Int = 0
    @State private var showCleaning: Bool = false
    
    // 会話バブル関連
    @State private var conversationAnimating: Bool = false
    @State private var conversationOpacity: Double = 0
    
    // 親ビューから渡されるサイズ
    var size: CGSize
    
    // カスタム画像名を保持するプロパティ
    @State private var _customImageName: String? = nil
    
    // 先頭で食べ物画像名を保持
    @State private var foodImageName: String = ""
    
    var body: some View {
        mainContentView
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                petPuppy()
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // 長押しで会話を表示
                if !viewModel.showConversationBubble && currentState != .eating && currentState != .playing {
                    // ランダムな会話を表示
                    let randomGreeting = viewModel.getPersonalizedGreeting()
                    viewModel.currentConversation = randomGreeting
                    viewModel.showConversationBubble = true
                    viewModel.lastConversationTime = Date()
                    
                    // 操作時間を更新
                    viewModel.updateLastInteraction()
                }
            }
            .onAppear {
                startAnimation()
                // 初期うんち生成
                updatePoopDisplay()
                
                // 画面表示時に自動的に挨拶を表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !viewModel.showConversationBubble {
                        let greeting = viewModel.getPersonalizedGreeting()
                        viewModel.currentConversation = greeting
                        viewModel.showConversationBubble = true
                        viewModel.lastConversationTime = Date()
                    }
                }
            }
            .onDisappear {
                timerCancellable?.cancel()
            }
            .onChange(of: viewModel.showEatingAnimation) { _, isEating in
                if isEating {
                    showEatingAnimation()
                }
            }
            .onChange(of: viewModel.showPlayingAnimation) { _, isPlaying in
                if isPlaying {
                    showPlayingAnimation()
                }
            }
            .onChange(of: viewModel.showPettingAnimation) { _, isPetting in
                if isPetting {
                    showPettingAnimation()
                }
            }
            .onChange(of: viewModel.showCleaningAnimation) { _, isCleaning in
                if isCleaning {
                    showCleaningAnimation()
                }
            }
            .onChange(of: viewModel.poopCount) { _, count in
                // うんちの数が変化したら表示を更新
                updatePoopDisplay()
                
                // うんちの数が変わったら状態も再計算
                if count >= 3 && (currentState != .eating && currentState != .playing && currentState != .petting) {
                    currentState = determineState()
                }
            }
            .onChange(of: viewModel.showConversationBubble) { _, isShowing in
                if !isShowing {
                    // 会話バブルが非表示になったらアニメーション状態をリセット
                    conversationAnimating = false
                    conversationOpacity = 0
                }
            }
    }
    
    // メインコンテンツビュー
    private var mainContentView: some View {
        ZStack {
            // うんち画像（ある場合に表示）
            poopsView
            
            // 掃除効果（キラキラエフェクト）
            cleaningEffectsView
            
            // 食べ物画像（条件付きで表示）
            if showFood {
                Image(foodImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .position(foodPosition)
            }
            
            // 子犬画像
            puppyView
            
            // 会話バブル
            conversationBubbleView
        }
    }
    
    // うんち表示ビュー
    private var poopsView: some View {
        ForEach(0..<poopPositions.count, id: \.self) { index in
            if index < poopPositions.count {
                PoopView(position: poopPositions[index], showCleaning: showCleaning)
            }
        }
    }
    
    // 掃除エフェクトビュー
    private var cleaningEffectsView: some View {
        Group {
            if showCleaning {
                ForEach(0..<poopPositions.count, id: \.self) { index in
                    if index < poopPositions.count {
                        CleaningEffectView(position: poopPositions[index])
                    }
                }
            }
        }
    }
    
    // 子犬ビュー
    private var puppyView: some View {
        Image(currentImageName)
            .resizable()
            .scaledToFit()
            .frame(width: 120)
            .position(position)
            .scaleEffect(shouldBounce ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: shouldBounce)
    }
    
    // 会話バブルビュー
    private var conversationBubbleView: some View {
        Group {
            if viewModel.showConversationBubble {
                // 会話バブルの推定サイズ
                let bubbleWidth: CGFloat = 200
                let bubbleHalfWidth: CGFloat = bubbleWidth / 2
                
                // 会話バブルが画面内に収まるようにX座標を調整
                let safeX = min(max(position.x, bubbleHalfWidth + 20), size.width - bubbleHalfWidth - 20)
                
                ConversationBubbleView(
                    text: viewModel.currentConversation,
                    position: CGPoint(x: safeX, y: position.y - 70),
                    opacity: conversationOpacity
                )
                .onAppear {
                    // 会話バブルのアニメーション
                    conversationAnimating = true
                    withAnimation(.easeIn(duration: 0.3)) {
                        conversationOpacity = 1
                    }
                    
                    // 5秒後に会話を非表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            if conversationAnimating {
                                conversationOpacity = 0
                                conversationAnimating = false
                                
                                // ビューモデルのフラグを更新
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.showConversationBubble = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 現在の状態に応じた画像名を取得
    private var currentImageName: String {
        get {
            switch currentState {
                case .idle:
                    // 待機状態の場合は puppy_idle_1 を使用
                    return "puppy_idle_1"
                case .eating:
                    // カスタム画像があればそちらを優先、それ以外はデフォルト
                    return _customImageName ?? "puppy_eating_1"
                case .playing:
                    // カスタムアニメーションで制御
                    return _customImageName ?? "puppy_playing_1"
                case .sleeping:
                    return "puppy_sleeping_1"
                case .happy:
                    return "puppy_happy_1"
                case .sad:
                    return "puppy_sad_1"
                case .hungry:
                    return "puppy_hungry_1"
                case .petting:
                    return "puppy_pet"
                case .walking:
                    if walkingDirection > 0 {
                        return "puppy_walk_l1"
                    } else {
                        return "puppy_walk_r1"
                    }
            }
        }
        set {
            _customImageName = newValue
        }
    }
    
    // 状態決定ロジック
    private func determineState() -> PuppyState {
        // お腹が空いている場合
        if viewModel.puppyHunger < 20 {
            return .hungry
        }
        
        // 機嫌が悪い場合
        if viewModel.puppyHappiness < 20 {
            return .sad
        }
        
        // うんちが3つ以上貯まっている場合
        if viewModel.poopCount >= 3 {
            return .sad
        }
        
        // ランダムに状態を変更
        let randomValue = Int.random(in: 0...100)
        
        if randomValue < 50 {
            return .walking  // 歩行確率を少し下げる
        } else if randomValue < 65 {
            return .happy
        } else if randomValue < 85 {
            return .idle     // 待機状態の確率を上げる
        } else if randomValue < 90 && viewModel.puppyHunger < 70 {
            return .hungry
        } else {
            return .idle     // それ以外は待機状態
        }
    }
    
    // アニメーション開始
    private func startAnimation() {
        // 初期位置を設定 - 床にきちんと接地するよう調整
        position = CGPoint(x: CGFloat.random(in: 50..<size.width-50), y: size.height - 40)
        
        // 初期状態を設定
        currentState = determineState()
        
        // アニメーションタイマーを開始（0.3秒間隔）
        timer = Timer.publish(every: 0.3, on: .main, in: .common)
        timerCancellable = timer.connect()
        
        // タイマーを購読
        timerCancellable = timer.sink { _ in
            updateAnimation()
        }
    }
    
    // アニメーション更新
    private func updateAnimation() {
        // 状態に応じたアニメーション
        switch currentState {
            case .walking:
                // 歩行アニメーション
                moveAround()
                
                // 歩行中にidleCounterをインクリメントして歩行アニメーションを表現
                idleCounter += 1
                
                // 一定確率で待機状態に切り替え
                if Int.random(in: 0...30) == 0 {
                    currentState = .idle
                    idleCounter = 0
                }
                
            case .idle:
                // 待機状態では動かない
                // カウンターを進めてアニメーションを表現（現在は単一フレームのみ）
                idleCounter += 1
                
                // 一定時間(約3秒)待機した後に、新しい状態に遷移するか歩き出す
                if idleCounter > 10 {
                    idleCounter = 0
                    // 60%の確率で歩き出す、40%の確率で他の状態に遷移
                    if Int.random(in: 0...100) < 60 {
                        currentState = .walking
                    } else {
                        currentState = determineState()
                    }
                }
                
            case .eating:
                // 食事状態は長めに維持（約6秒）
                idleCounter += 1
                if idleCounter > 20 { // 約6秒後
                    idleCounter = 0
                    currentState = determineState()
                    
                    // 食事が終わったら食べ物を非表示
                    showFood = false
                }
                
            case .playing:
                // 遊び状態は長めに維持（約6秒）
                idleCounter += 1
                if idleCounter > 20 { // 約6秒後
                    idleCounter = 0
                    currentState = determineState()
                    _customImageName = nil
                }
                
            case .petting:
                // 撫でられている状態（約3秒）
                idleCounter += 1
                if idleCounter > 10 { // 約3秒後
                    idleCounter = 0
                    currentState = .happy // 撫でた後は嬉しい状態に
                }
                
            case .sleeping, .happy, .sad, .hungry:
                // その他の状態は一定時間経過後に戻る
                idleCounter += 1
                if idleCounter > 10 { // 約3秒後
                    idleCounter = 0
                    currentState = determineState()
                }
        }
    }
    
    // ランダムに移動
    private func moveAround() {
        // 画面端からの最小マージン
        let screenMargin: CGFloat = 80
        
        // 画面端に達したら方向転換（子犬の幅と安全マージンを考慮）
        if position.x < screenMargin {
            walkingDirection = 1
        } else if position.x > size.width - screenMargin {
            walkingDirection = -1
        }
        // ランダムで方向転換（確率を下げて、より長く同じ方向に移動するように）
        else if Int.random(in: 0...40) == 0 {
            walkingDirection *= -1
        }
        
        // 現在の方向に応じて移動（移動速度を遅く）
        let newX = position.x + (walkingDirection * 5)
        // 子犬が確実に画面内に収まるように制限（子犬の幅を考慮）
        position.x = max(screenMargin, min(newX, size.width - screenMargin))
        
        // Y座標もわずかに変動させるが、地面から浮かないよう制限（変動を小さく）
        if Int.random(in: 0...8) == 0 {
            let newY = position.y + CGFloat.random(in: -2...2)
            // 床との接地を維持するため、Y座標の変動を制限
            position.y = max(size.height - 45, min(newY, size.height - 35))
        }
    }
    
    // 子犬を撫でる
    private func petPuppy() {
        // 撫でられた状態にする
        currentState = .petting
        idleCounter = 0
        
        // バウンスアニメーション
        shouldBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shouldBounce = false
        }
        
        // 機嫌アップ（最大100まで）
        viewModel.puppyHappiness = min(viewModel.puppyHappiness + 5, 100)
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // 食事アニメーション
    private func showEatingAnimation() {
        // 選択した食べ物に応じた子犬のアニメーション画像をセット
        let puppyImageName: String
        switch viewModel.selectedFoodType {
        case .weird_dog_food:
            puppyImageName = "puppy_eating_weird_dog_food"
        case .dog_food:
            puppyImageName = "puppy_eating_1"
        case .treat:
            puppyImageName = "puppy_eating_treat"
        case .tasty_meat:
            puppyImageName = "puppy_eating_tasty_meat"
        }
        // カスタム画像として保持
        _customImageName = puppyImageName
        // 子犬の状態を食事中に
        currentState = .eating
        idleCounter = 0
        // 食事アニメーション用の小物（フードアイコン）は不要なら非表示
        showFood = false

        // 食事アニメーションが終わった後も食べ物を表示しておく
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            // 食事状態が終了したらカスタム画像をクリア
            if self.currentState != .eating {
                self._customImageName = nil
            }
        }
    }
    
    // 遊びアニメーション
    private func showPlayingAnimation() {
        print("🎮 遊びアニメーション開始")
        // 遊び状態に変更
        currentState = .playing
        idleCounter = 0
        
        // 遊びアニメーション - 画像を交互に切り替える
        animatePlayingImages()
    }
    
    // 遊びアニメーション - 画像を交互に切り替える
    private func animatePlayingImages() {
        var counter = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            // 状態が変わったらアニメーション停止
            if self.currentState != .playing {
                timer.invalidate()
                return
            }
            
            // playing_1とplaying_2を交互に表示
            counter += 1
            let suffix = counter % 2 == 0 ? "2" : "1"
            self._customImageName = "puppy_playing_\(suffix)"
            
            // 最大10回（約3秒）で停止
            if counter >= 10 {
                timer.invalidate()
            }
        }
        
        // タイマーを即時起動
        timer.fire()
    }
    
    // 撫でるアニメーション
    private func showPettingAnimation() {
        print("✋ 撫でるアニメーション開始")
        // 撫でられた状態にする
        currentState = .petting
        idleCounter = 0
        
        // バウンスアニメーション
        shouldBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shouldBounce = false
        }
    }
    
    // うんちの表示を更新
    private func updatePoopDisplay() {
        // 現在のうんちの数を取得
        let count = viewModel.poopCount
        
        // うんちが増えた場合は新しいうんちを追加
        if count > poopPositions.count {
            for _ in poopPositions.count..<count {
                // ランダムな位置にうんちを配置（床に接地するよう調整）
                let randomX = CGFloat.random(in: 50..<size.width-50)
                let randomY = CGFloat.random(in: size.height-50..<size.height-30)
                poopPositions.append(CGPoint(x: randomX, y: randomY))
            }
        }
        // うんちが減った場合は配列を切り詰める
        else if count < poopPositions.count {
            poopPositions = Array(poopPositions.prefix(count))
        }
        
        // 現在のうんちの数を記録
        lastPoopCount = count
    }
    
    // 掃除アニメーション
    private func showCleaningAnimation() {
        print("🧹 掃除アニメーション開始")
        showCleaning = true
        
        // 2秒後にエフェクトを消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCleaning = false
            // うんちの配列をクリア
            self.poopPositions = []
        }
    }
} 