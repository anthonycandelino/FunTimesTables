//
//  ContentView.swift
//  FunTimesTables
//
//  Created by Anthony Candelino on 2024-06-27.
//

import SwiftUI

class GameState: ObservableObject {
    @Published var loadGame: Bool = false
    @Published var numberOfQuestions: Int = 5
    @Published var maxTableNumber: Int = 2
    @Published var inGame: Bool = false
    @Published var questionList: [Question]  = []
    @Published var gettingQuestion = false
}

struct Question {
    let question: String
    let answer: Int
}

struct RoundButton: View {
    var text: String
    var textColor: Color = .purple
    var onTap: () -> Void
    var isDisabled = false
    var isOutlined = false
    
    var body: some View {
        Button(action: onTap, label: {
            Text(text).font(.system(size: 60)).foregroundStyle(!isDisabled ? textColor : .gray).bold()
        })
        .frame(width: 85, height: 85)
        .background(.white)
        .cornerRadius(25)
        .disabled(isDisabled)
        .shadow(radius: 5, x: 0, y: 3)
        .overlay(
            isOutlined && !isDisabled ? RoundedRectangle(cornerRadius: 25).stroke(textColor, lineWidth: 5) : nil
        )
        .padding(10)
    }
}

struct SettingsView: View {
    @ObservedObject var gameState: GameState
    private var questionAmountOptions = [5, 10, 15, 20]
    
    init(gameState: GameState) {
        self.gameState = gameState
    }
    
    var body: some View {
        Text("Fun × Tables")
            .font(.system(size: 50))
            .foregroundStyle(.white)
            .bold()
            .offset(y: gameState.loadGame ? -UIScreen.main.bounds.height : 0)
            .shadow(radius: 10)
            .padding(.top, 30)
            .padding(.bottom, 50)
        VStack {
            VStack {
                Text("Number of Questions").font(.title).foregroundStyle(.purple).bold()
                Picker("Number of Questions", selection: $gameState.numberOfQuestions) {
                    ForEach(questionAmountOptions, id: \.self) { option in
                        Text("\(option)")
                    }
                }
                .pickerStyle(.segmented)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.purple, lineWidth: 2)
                )
            }
            .padding(30)
            .background(.white)
            .cornerRadius(20)
            .padding(.bottom)
            .offset(x: gameState.loadGame ? -UIScreen.main.bounds.width : 0)
            VStack {
                Text("Max times tables").font(.title).foregroundStyle(.purple).bold()
                Text(String(gameState.maxTableNumber)).font(.title2).foregroundStyle(.secondary)
                HStack {
                    Text("2")
                    Slider(value: Binding(
                        get: { Double(gameState.maxTableNumber) },
                        set: { newValue in gameState.maxTableNumber = Int(newValue) }
                    ), in: 2...12, step: 1).accentColor(.purple)
                    Text("12")
                }
            }
            .padding(30)
            .background(.white)
            .cornerRadius(20)
            .offset(x: gameState.loadGame ? UIScreen.main.bounds.width : 0)
        }
        .padding()
        .shadow(radius: 3, x: 0, y: 3)
        Spacer()
        Button(action: startGame, label: {
            Text("Start Game")
        })
        .padding(25)
        .font(.title)
        .bold()
        .background(.white)
        .foregroundStyle(.blue)
        .clipShape(.capsule)
        .shadow(radius: 3, x: 0, y: 3)
        .padding(.bottom)
        .opacity(gameState.loadGame ? 0: 1)
    }
    
    func getQuestionList() -> [Question] {
        var questionList = [Question]()
        for _ in 0..<gameState.numberOfQuestions {
            let num1 = Int.random(in: 2...gameState.maxTableNumber)
            let num2 = Int.random(in: 2...12)
            
            questionList.append(Question(question: "\(num1) x \(num2)", answer: num1 * num2))
        }
        return questionList
    }
    
    func startGame() {
        withAnimation(.snappy(duration: 0.7)) {
            gameState.loadGame.toggle()
            gameState.gettingQuestion = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            gameState.inGame.toggle()
            gameState.questionList = getQuestionList()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            gameState.gettingQuestion = false
        }
    }
}

struct GameView: View {
    @ObservedObject var gameState: GameState
    @State private var questionNumber = 0
    @State private var questionAnswer = ""
    @State private var score = 0
    @State private var isGameOver = false
    @State private var scoreIndicationColor: Color?
    @State private var disableButtonInput = false
    let numpadOptions = Array(1...9)
    
    init(gameState: GameState) {
        self.gameState = gameState
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: resetGame, label: {
                    Text("New Game").bold()
                })
                .padding(10)
                .foregroundColor(.white)
                .background(.purple)
                .clipShape(.capsule)
                .shadow(radius: 3, x: 0, y: 1)
                Spacer()
                Text("Question \(questionNumber + 1)/\(gameState.numberOfQuestions)").font(.title2).foregroundStyle(.white).bold()
            }
            Text("\(gameState.questionList[questionNumber].question)")
                .font(.system(size: 90))
                .foregroundStyle(.white)
                .bold()
                .shadow(radius: 10)
                .padding(.bottom)
                .offset(x: gameState.gettingQuestion ? getOffset() : 0)
                .animation(.bouncy, value: gameState.gettingQuestion)
            Text(questionAnswer.isEmpty ? "0" : questionAnswer)
                .font(.system(size: 60))
                .fontWeight(questionAnswer.isEmpty ? .light : .bold)
                .frame(width: UIScreen.main.bounds.width * 0.8, height: 100)
                .background(.white)
                .foregroundStyle(scoreIndicationColor ?? getInputTextColor())
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(scoreIndicationColor ?? .blue, lineWidth: 5)
                )
            ForEach(0..<3) { rowIndex in
                HStack {
                    ForEach(0..<3, id: \.self) { columnIndex in
                        let buttonNumber = numpadOptions[rowIndex * 3 + columnIndex]
                        RoundButton(text: "\(buttonNumber)", onTap: {
                            if questionAnswer.count < 3 {
                                questionAnswer += String(buttonNumber)
                            }
                        }, isDisabled: disableButtonInput)
                    }
                }
            }
            HStack {
                RoundButton(text: "✘", textColor: .red, onTap: {
                    questionAnswer = ""
                }, isDisabled: disableButtonInput, isOutlined: true)
                RoundButton(text: "0", onTap: {
                    if !questionAnswer.isEmpty && questionAnswer.count < 3 { questionAnswer += "0"
                    }
                }, isDisabled: disableButtonInput)
                RoundButton(text: "✓", textColor: .green, onTap: checkAnswer, isDisabled: disableButtonInput || questionAnswer.isEmpty, isOutlined: true)
            }
        }.alert("Game Over", isPresented: $isGameOver) {
            Button("Yes", action: resetGame)
        } message: {
            Text("You scored \(score)/\(gameState.numberOfQuestions). Wanna play again?")
        }.padding()
    }
    
    func getOffset() -> CGFloat {
        disableButtonInput ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width
    }
    
    func getInputTextColor() -> Color {
        questionAnswer.isEmpty ? .gray : .purple
    }
    
    
    func checkAnswer() {
        print("checked answer")
        disableButtonInput.toggle()
        if Int(questionAnswer) == gameState.questionList[questionNumber].answer {
            score += 1
            scoreIndicationColor = .green
        } else {
            scoreIndicationColor = .red
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            questionAnswer = ""
            scoreIndicationColor = nil
            disableButtonInput.toggle()
            if questionNumber < gameState.numberOfQuestions - 1 {
                questionNumber += 1
                gameState.gettingQuestion.toggle()
            } else {
                isGameOver.toggle()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            gameState.gettingQuestion.toggle()
        }
    }
    
    func resetGame() {
        gameState.inGame = false
        gameState.numberOfQuestions = 5
        gameState.maxTableNumber = 2
        gameState.loadGame = false
        questionNumber = 0
        questionAnswer = ""
        score = 0
        isGameOver = false
        scoreIndicationColor = nil
        disableButtonInput = false
    }
}

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.mint, .blue, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack {
                if !gameState.inGame {
                    SettingsView(gameState: gameState)
                } else {
                    GameView(gameState: gameState)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
