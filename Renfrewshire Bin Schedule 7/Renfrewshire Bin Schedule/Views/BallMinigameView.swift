//
//  PongMinigameView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 25/02/2025.
//


import SwiftUI
import Combine

class GameEngine: ObservableObject {
    // Published properties for game state
    @Published var ballPosition: CGPoint
    @Published var ballVelocity: CGVector
    @Published var leftPaddleY: CGFloat
    @Published var rightPaddleY: CGFloat
    @Published var leftScore: Int = 0
    @Published var rightScore: Int = 0

    // Constants
    let paddleWidth: CGFloat = 10
    let paddleHeight: CGFloat = 80
    let ballSize: CGFloat = 20

    // Size of the game view (set from the view)
    private var viewSize: CGSize = .zero

    private var displayLink: CADisplayLink?

    init() {
        // Initialize game state
        self.ballPosition = CGPoint(x: 200, y: 200)
        self.ballVelocity = CGVector(dx: 200, dy: 150)
        self.leftPaddleY = 200
        self.rightPaddleY = 200

        // Setup CADisplayLink
        setupDisplayLink()
    }

    deinit {
        displayLink?.invalidate()
    }

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .default)
    }

    func setViewSize(_ size: CGSize) {
        self.viewSize = size
        // Initialize ball position to center if size is valid
        if ballPosition == .zero {
            ballPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }

    @objc private func update(displayLink: CADisplayLink) {
        guard viewSize != .zero else { return }
        let deltaTime = displayLink.targetTimestamp - displayLink.timestamp
        updateGame(in: viewSize, deltaTime: deltaTime)
    }

    func updateGame(in size: CGSize, deltaTime: TimeInterval) {
        // Update ball position
        ballPosition.x += ballVelocity.dx * CGFloat(deltaTime)
        ballPosition.y += ballVelocity.dy * CGFloat(deltaTime)

        // Bounce off top and bottom edges.
        if ballPosition.y <= ballSize / 2 {
            ballPosition.y = ballSize / 2
            ballVelocity.dy = abs(ballVelocity.dy)
        } else if ballPosition.y >= size.height - ballSize / 2 {
            ballPosition.y = size.height - ballSize / 2
            ballVelocity.dy = -abs(ballVelocity.dy)
        }

        // Check collision with left paddle.
        let leftPaddleRect = CGRect(
            x: paddleWidth * 2 - paddleWidth / 2,
            y: leftPaddleY - paddleHeight / 2,
            width: paddleWidth,
            height: paddleHeight
        )
        if leftPaddleRect.contains(ballPosition) && ballVelocity.dx < 0 {
            // Increase speed by 5%
            ballVelocity.dx = abs(ballVelocity.dx) * 1.05
            ballVelocity.dy *= 1.05
        }

        // Simple AI: move right paddle toward ball.
        let paddleSpeed: CGFloat = 150
        if rightPaddleY < ballPosition.y {
            rightPaddleY = min(rightPaddleY + paddleSpeed * CGFloat(deltaTime), ballPosition.y)
        } else {
            rightPaddleY = max(rightPaddleY - paddleSpeed * CGFloat(deltaTime), ballPosition.y)
        }

        // Check collision with right paddle.
        let rightPaddleRect = CGRect(
            x: size.width - paddleWidth * 2 - paddleWidth / 2,
            y: rightPaddleY - paddleHeight / 2,
            width: paddleWidth,
            height: paddleHeight
        )
        if rightPaddleRect.contains(ballPosition) && ballVelocity.dx > 0 {
            ballVelocity.dx = -abs(ballVelocity.dx) * 1.05
            ballVelocity.dy *= 1.05
        }

        // If ball goes off screen, update score and reset ball.
        if ballPosition.x < 0 {
            // Ball left the screen on the left side; right (AI) scores.
            rightScore += 1
            resetBall(in: size)
        } else if ballPosition.x > size.width {
            // Ball left the screen on the right side; left (user) scores.
            leftScore += 1
            resetBall(in: size)
        }
    }

    private func resetBall(in size: CGSize) {
        ballPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        // Reset with base speed (you could also carry over increased speed if desired)
        ballVelocity = CGVector(
            dx: Bool.random() ? 200 : -200,
            dy: CGFloat.random(in: -150...150)
        )
    }
}

struct BallMinigameView: View {
    @StateObject private var gameEngine = GameEngine()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Game objects
                // Ball
                Circle()
                    .fill(Color.white)
                    .frame(width: gameEngine.ballSize, height: gameEngine.ballSize)
                    .position(gameEngine.ballPosition)

                // Left paddle (user controlled)
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: gameEngine.paddleWidth, height: gameEngine.paddleHeight)
                    .position(x: gameEngine.paddleWidth * 2, y: gameEngine.leftPaddleY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newY = value.startLocation.y + value.translation.height
                                gameEngine.leftPaddleY = min(
                                    max(newY, gameEngine.paddleHeight / 2),
                                    geometry.size.height - gameEngine.paddleHeight / 2
                                )
                            }
                    )

                // Right paddle (simple AI)
                Rectangle()
                    .fill(Color.red)
                    .frame(width: gameEngine.paddleWidth, height: gameEngine.paddleHeight)
                    .position(
                        x: geometry.size.width - gameEngine.paddleWidth * 2,
                        y: gameEngine.rightPaddleY
                    )

                // Score display
                VStack {
                    HStack {
                        Text("You: \(gameEngine.leftScore)")
                        Spacer()
                        Text("AI: \(gameEngine.rightScore)")
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    Spacer()
                }
            }
            .background(Color.black)
            .onAppear {
                gameEngine.setViewSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                gameEngine.setViewSize(newSize)
            }
        }
        .navigationTitle("Ball Minigame")
    }
}

struct BallMinigameView_Previews: PreviewProvider {
    static var previews: some View {
        BallMinigameView()
            .previewInterfaceOrientation(.landscapeRight)
    }
}
