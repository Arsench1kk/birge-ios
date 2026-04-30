import ComposableArchitecture
import SwiftUI

@ViewAction(for: SearchingFeature.self)
struct SearchingView: View {
    @Bindable var store: StoreOf<SearchingFeature>
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1E3A5F")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Center Content
            VStack(spacing: 0) {
                // RADAR ANIMATION
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 180, height: 180)
                        .scaleEffect(isAnimating ? 1.8 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(0.6),
                            value: isAnimating
                        )
                    
                    Circle()
                        .fill(Color.blue.opacity(0.35))
                        .frame(width: 130, height: 130)
                        .scaleEffect(isAnimating ? 1.8 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(0.3),
                            value: isAnimating
                        )
                    
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.8 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.blue)
                        )
                }
                .padding(.bottom, 32)
                
                // STATUS TEXT
                Text("Ищем водителя" + String(repeating: ".", count: store.dotsCount))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    // Added fixed width to avoid layout jittering when dots are appended
                    .frame(width: 250, alignment: .center)
                
                Text("Обычно это занимает менее минуты")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 4)
                
                // TIMER
                Text(String(format: "%d:%02d", store.secondsElapsed / 60, store.secondsElapsed % 60))
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                send(.cancelTapped)
            } label: {
                Text("Отменить поиск")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.clear)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear {
            isAnimating = true
            send(.onAppear)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SearchingView(
        store: Store(initialState: SearchingFeature.State()) {
            SearchingFeature()
        }
    )
}
