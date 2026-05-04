import Combine
import SwiftUI

// MARK: - BoardingCodeView

struct BoardingCodeView: View {
    let code: String
    let onDismiss: () -> Void

    @State private var countdown: Int = 60
    @State private var codeOpacity: Double = 1.0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            BIRGEColors.background.ignoresSafeArea()

            VStack(spacing: BIRGELayout.xl) {
                // Header
                VStack(spacing: BIRGELayout.xs) {
                    ZStack {
                        Circle()
                            .fill(BIRGEColors.brandPrimary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(BIRGEColors.brandPrimary)
                    }
                    Text("Код посадки")
                        .font(BIRGEFonts.title)
                    Text("Покажите водителю для подтверждения")
                        .font(BIRGEFonts.subtext)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Code display
                VStack(spacing: BIRGELayout.s) {
                    Text(code)
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(BIRGEColors.textPrimary)
                        .tracking(8)
                        .opacity(codeOpacity)
                        .animation(.easeInOut(duration: 0.3), value: codeOpacity)

                    // Countdown progress bar
                    VStack(spacing: BIRGELayout.xxxs) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(BIRGEColors.textTertiary.opacity(0.2))
                                Capsule()
                                    .fill(BIRGEColors.brandPrimary)
                                    .frame(width: geo.size.width * CGFloat(countdown) / 60)
                                    .animation(.linear(duration: 1), value: countdown)
                            }
                        }
                        .frame(height: 4)

                        Text("Обновится через \(countdown) сек")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                }
                .padding(BIRGELayout.xl)
                .birgeGlassCard()

                // Info note
                HStack(spacing: BIRGELayout.xs) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(BIRGEColors.brandPrimary)
                    Text("Код виден только вам и водителю")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
                .padding(BIRGELayout.s)
                .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))

                BIRGESecondaryButton(title: "Закрыть") {
                    onDismiss()
                }
            }
            .padding(.horizontal, BIRGELayout.m)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onReceive(timer) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                // Reset countdown
                countdown = 60
                withAnimation { codeOpacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { codeOpacity = 1 }
                }
            }
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            BoardingCodeView(code: "847 291", onDismiss: {})
        }
}
