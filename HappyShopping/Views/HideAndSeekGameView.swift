import SwiftUI
import AVFoundation

struct HideAndSeekGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GameViewModel

    @State private var targetIndex: Int = 0
    @State private var isGameOver: Bool = false
    @State private var messageKey: String = "hideAndSeek_instructions"
    @State private var feedbackCorrect: Bool = false

    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(viewModel.getLocalizedAnimalCareText(key: "hideAndSeek_title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text(viewModel.getLocalizedAnimalCareText(key: messageKey))
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(feedbackCorrect ? .green : .primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .animation(.easeInOut, value: messageKey)
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(0..<9) { index in
                        Button {
                            if !isGameOver {
                                cellTapped(index)
                            }
                        } label: {
                            if isGameOver && index == targetIndex {
                                Image("puppy_idle_1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                            } else {
                                Image("puppy_missing")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .opacity(0.6)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isGameOver)
                    }
                }
                .padding(.horizontal, 30)
                Spacer()
                if isGameOver {
                    Button(viewModel.getLocalizedAnimalCareText(key: "hideAndSeek_closeButton")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 40)
                    .background(Color.blue)
                    .cornerRadius(25)
                    .shadow(radius: 3)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer(minLength: 30)
            }
            .padding(.vertical, 30)
        }
        .onAppear(perform: setupGame)
    }

    private func setupGame() {
        targetIndex = Int.random(in: 0..<9)
        isGameOver = false
        feedbackCorrect = false
        messageKey = "hideAndSeek_instructions"
    }

    private func cellTapped(_ index: Int) {
        if index == targetIndex {
            messageKey = "hideAndSeek_correct"
            feedbackCorrect = true
            isGameOver = true
            viewModel.puppyHappiness = min(viewModel.puppyHappiness + 25, 100)
            viewModel.updateLastInteraction()
            playSound("success")
        } else {
            messageKey = "hideAndSeek_wrong"
            feedbackCorrect = false
            viewModel.puppyHappiness = max(viewModel.puppyHappiness - 5, 0)
            playSound("failure")
        }
    }

    private func playSound(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
} 