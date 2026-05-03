import ComposableArchitecture
import SwiftUI

private struct OnboardingSlide {
    let symbol: String
    let symbolColor: Color
    let title: String
    let body: String
}

private let slides: [OnboardingSlide] = [
    .init(
        symbol: "arrow.down.forward.and.arrow.up.backward",
        symbolColor: BIRGEColors.brandPrimary,
        title: "Экономия до 40%",
        body: "Фиксированные маршруты — меньше пробок, меньше цена. Никаких сюрпризов."
    ),
    .init(
        symbol: "brain.head.profile",
        symbolColor: BIRGEColors.brandPrimary,
        title: "AI подбирает маршрут",
        body: "Умный алгоритм анализирует ваши поездки и предлагает лучший коридор."
    ),
    .init(
        symbol: "leaf.fill",
        symbolColor: BIRGEColors.success,
        title: "Меньше машин — чище город",
        body: "Carpooling снижает выбросы CO2 и разгружает алматинские пробки."
    )
]

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let morningTimes = ["06:30", "07:00", "07:30", "08:00", "08:30", "09:00"]
    private let eveningTimes = ["17:00", "17:30", "18:00", "18:30", "19:00", "19:30"]
    private let dayNumbers = [5, 6, 7, 8, 9, 10, 11]

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar

                TabView(selection: Binding(
                    get: { store.currentPage },
                    set: { store.send(.pageChanged($0)) }
                )) {
                    ForEach(0..<store.totalPages, id: \.self) { page in
                        pageContent(page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: store.currentPage)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                BIRGEColors.brandPrimary.opacity(0.14),
                BIRGEColors.background,
                BIRGEColors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack(spacing: BIRGELayout.xs) {
            HStack {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        _ = store.send(.backTapped)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(store.canGoBack ? BIRGEColors.brandPrimary : .clear)
                        .frame(width: 36, height: 36)
                }
                .disabled(!store.canGoBack)

                Spacer()

                Text(topLabel)
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            progressBar
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.s)
        .padding(.bottom, BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.035))
        .ignoresSafeArea(edges: .top)
    }

    private var topLabel: String {
        if store.isFinishedPage {
            return "Готово"
        }
        if store.isIntroPage {
            return "BIRGE"
        }
        return "Шаг \(store.currentPage - 2) из 5"
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(BIRGEColors.brandPrimary.opacity(0.14))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(BIRGEColors.brandPrimary.gradient)
                        .frame(width: max(8, proxy.size.width * progress))
                }
        }
        .frame(height: 4)
    }

    private var progress: CGFloat {
        CGFloat(store.currentPage + 1) / CGFloat(store.totalPages)
    }

    @ViewBuilder
    private func pageContent(_ page: Int) -> some View {
        switch page {
        case 0, 1, 2:
            introSlide(slides[page])
        case 3:
            originStep
        case 4:
            destinationStep
        case 5:
            timeStep
        case 6:
            daysStep
        default:
            summaryStep
        }
    }

    private func introSlide(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: BIRGELayout.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(slide.symbolColor.opacity(0.12))
                    .frame(width: 188, height: 188)
                Circle()
                    .fill(slide.symbolColor.opacity(0.08))
                    .frame(width: 140, height: 140)
                Image(systemName: slide.symbol)
                    .font(.system(size: 66, weight: .medium))
                    .foregroundStyle(slide.symbolColor)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: BIRGELayout.s) {
                Text(slide.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(slide.body)
                    .font(BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, BIRGELayout.m)
            }

            Spacer()

            introFooter
        }
        .padding(.horizontal, BIRGELayout.m)
    }

    private var introFooter: some View {
        VStack(spacing: BIRGELayout.xs) {
            dotsIndicator(count: 3, active: store.currentPage)

            BIRGEPrimaryButton(title: store.currentPage == 2 ? "Настроить маршрут" : "Далее") {
                advance()
            }

            if store.currentPage < 2 {
                Button("Пропустить") {
                    _ = store.send(.skipTapped)
                }
                .font(BIRGEFonts.body)
                .foregroundStyle(BIRGEColors.textSecondary)
                .birgeTapTarget()
            }
        }
        .padding(.bottom, BIRGELayout.xl)
    }

    private var originStep: some View {
        commuteStep(
            title: "Откуда вы обычно едете?",
            subtitle: "Укажите точку отправления — дом, работа или учёба.",
            primaryTitle: "Далее"
        ) {
            addressField(
                text: store.origin,
                placeholder: "Поиск адреса...",
                action: { store.send(.originChanged($0)) }
            )

            VStack(spacing: BIRGELayout.xs) {
                presetRow(symbol: "house.fill", title: "Добавить дом", subtitle: "Алатау, пр. Аль-Фараби") {
                    store.send(.originPresetTapped("Алатау, пр. Аль-Фараби"))
                }
                presetRow(symbol: "briefcase.fill", title: "Добавить работу", subtitle: "Есентай Парк") {
                    store.send(.originPresetTapped("Есентай Парк, пр. Аль-Фараби 77"))
                }
                presetRow(symbol: "graduationcap.fill", title: "Добавить учёбу", subtitle: "КБТУ, ул. Толе Би 59") {
                    store.send(.originPresetTapped("КБТУ, ул. Толе Би 59"))
                }
            }

            miniMap(symbol: "mappin.and.ellipse")
        }
    }

    private var destinationStep: some View {
        commuteStep(
            title: "Куда вы обычно едете?",
            subtitle: "Укажите пункт назначения.",
            primaryTitle: "Далее"
        ) {
            summaryChip(symbol: "location.fill", text: store.origin)

            addressField(
                text: store.destination,
                placeholder: "Пункт назначения...",
                action: { store.send(.destinationChanged($0)) }
            )

            VStack(spacing: BIRGELayout.xs) {
                presetRow(symbol: "building.2.fill", title: "Есентай Парк", subtitle: "пр. Аль-Фараби 77") {
                    store.send(.destinationPresetTapped("Есентай Парк, 77/8"))
                }
                presetRow(symbol: "graduationcap.fill", title: "КБТУ", subtitle: "ул. Толе Би 59") {
                    store.send(.destinationPresetTapped("КБТУ, ул. Толе Би 59"))
                }
                presetRow(symbol: "cart.fill", title: "MEGA Alma-Ata", subtitle: "ул. Розыбакиева") {
                    store.send(.destinationPresetTapped("MEGA Alma-Ata"))
                }
            }

            routeMap
        }
    }

    private var timeStep: some View {
        commuteStep(
            title: "Когда вы обычно выезжаете?",
            subtitle: "Укажите примерное время. AI подберёт попутчиков с похожим расписанием.",
            primaryTitle: "Далее"
        ) {
            summaryChip(symbol: "arrow.triangle.swap", text: "\(store.origin) -> \(store.destination)")

            timePicker(
                title: "Утром",
                symbol: "sun.max.fill",
                selected: store.morningTime,
                times: morningTimes
            ) { time in
                store.send(.morningTimeSelected(time))
            }

            timePicker(
                title: "Вечером",
                symbol: "moon.stars.fill",
                selected: store.eveningTime,
                times: eveningTimes
            ) { time in
                store.send(.eveningTimeSelected(time))
            }

            BIRGEAIPill("AI учтёт окно +/-15 минут")
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var daysStep: some View {
        commuteStep(
            title: "В какие дни вы едете?",
            subtitle: "Выберите дни недели, когда маршрут повторяется.",
            primaryTitle: "Далее"
        ) {
            summaryChip(
                symbol: "clock.fill",
                text: "\(store.origin) -> \(store.destination) · \(store.morningTime) / \(store.eveningTime)"
            )

            VStack(spacing: BIRGELayout.s) {
                HStack(spacing: BIRGELayout.xxs) {
                    ForEach(Array(OnboardingFeature.CommuteDay.allCases.enumerated()), id: \.element) { index, day in
                        dayButton(day, number: dayNumbers[index])
                    }
                }

                Text("Выбрано: \(store.selectedDays.count) дней в неделю")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.035), isInteractive: true)

            infoCard(
                symbol: "lightbulb.fill",
                text: "Выберите все дни, когда регулярно совершаете этот маршрут. AI учитывает частоту при подборе попутчиков."
            )
        }
    }

    private var summaryStep: some View {
        VStack(spacing: BIRGELayout.m) {
            Spacer(minLength: BIRGELayout.m)

            VStack(spacing: BIRGELayout.xs) {
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(width: 72, height: 72)
                    .background(BIRGEColors.brandPrimary.gradient)
                    .clipShape(Circle())
                    .shadow(color: BIRGEColors.brandPrimary.opacity(0.3), radius: 16, y: 8)

                Text("Маршрут добавлен")
                    .font(BIRGEFonts.title)
                    .foregroundStyle(BIRGEColors.textPrimary)

                Text("AI начинает подбирать попутчиков")
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                Label("Маршрут 1", systemImage: "sparkles")
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)

                Divider()

                VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                    Label(store.origin, systemImage: "location.fill")
                    Image(systemName: "arrow.down")
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .padding(.leading, BIRGELayout.xs)
                    Label(store.destination, systemImage: "flag.checkered")
                }
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textPrimary)

                Divider()

                Label("\(store.morningTime) утром · \(store.eveningTime) вечером", systemImage: "clock.fill")
                Label(selectedDaysText, systemImage: "calendar")

                Divider()

                HStack(spacing: BIRGELayout.xs) {
                    Circle()
                        .fill(BIRGEColors.brandPrimary)
                        .frame(width: 10, height: 10)
                    Text("AI анализирует похожие маршруты...")
                        .font(BIRGEFonts.subtext)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }
            }
            .font(BIRGEFonts.subtext)
            .foregroundStyle(BIRGEColors.textSecondary)
            .padding(BIRGELayout.m)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04), isInteractive: true)

            BIRGESecondaryButton(title: "Добавить ещё маршрут") {
                _ = store.send(.addAnotherRouteTapped)
            }

            Spacer()

            VStack(spacing: BIRGELayout.xxs) {
                BIRGEPrimaryButton(title: "Найти мои коридоры") {
                    store.send(.nextTapped)
                }
                Text("Обычно AI подбирает варианты за 1-2 минуты")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.bottom, BIRGELayout.xl)
    }

    private func commuteStep<Content: View>(
        title: String,
        subtitle: String,
        primaryTitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BIRGELayout.m) {
                VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(BIRGEColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(BIRGEFonts.subtext)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                content()

                Spacer(minLength: BIRGELayout.l)

                BIRGEPrimaryButton(title: primaryTitle) {
                    advance()
                }
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.top, BIRGELayout.l)
            .padding(.bottom, BIRGELayout.xl)
        }
    }

    private func addressField(
        text: String,
        placeholder: String,
        action: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(BIRGEColors.textSecondary)
            TextField(placeholder, text: Binding(get: { text }, set: action))
                .font(BIRGEFonts.body)
                .textInputAutocapitalization(.words)
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025), isInteractive: true)
    }

    private func presetRow(
        symbol: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: symbol)
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 36, height: 36)
                    .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.07))

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(title)
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(subtitle)
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textTertiary)
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.02), isInteractive: true)
        }
        .buttonStyle(.plain)
    }

    private func summaryChip(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(BIRGEFonts.captionBold)
            .foregroundStyle(BIRGEColors.brandPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, BIRGELayout.xs)
            .padding(.vertical, BIRGELayout.xxs)
            .liquidGlass(.pill, tint: BIRGEColors.brandPrimary.opacity(0.06))
    }

    private var miniMap: some View {
        miniMap(symbol: "mappin.and.ellipse")
    }

    private func miniMap(symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .fill(BIRGEColors.brandPrimary.opacity(0.08))

            GridPattern()
                .stroke(BIRGEColors.brandPrimary.opacity(0.08), lineWidth: 1)

            Image(systemName: symbol)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(BIRGEColors.brandPrimary)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }

    private var routeMap: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BIRGELayout.radiusL)
                .fill(BIRGEColors.brandPrimary.opacity(0.08))

            Path { path in
                path.move(to: CGPoint(x: 56, y: 100))
                path.addCurve(
                    to: CGPoint(x: 292, y: 82),
                    control1: CGPoint(x: 120, y: 34),
                    control2: CGPoint(x: 210, y: 148)
                )
            }
            .stroke(BIRGEColors.brandPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 7]))

            HStack {
                mapPoint("location.fill")
                Spacer()
                mapPoint("flag.checkered")
            }
            .padding(.horizontal, BIRGELayout.xl)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusL))
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.025))
    }

    private func mapPoint(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(BIRGEFonts.sectionTitle)
            .foregroundStyle(BIRGEColors.textOnBrand)
            .frame(width: 38, height: 38)
            .background(BIRGEColors.brandPrimary)
            .clipShape(Circle())
            .shadow(color: BIRGEColors.brandPrimary.opacity(0.3), radius: 10, y: 5)
    }

    private func timePicker(
        title: String,
        symbol: String,
        selected: String,
        times: [String],
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Label(title, systemImage: symbol)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)

            VStack(spacing: BIRGELayout.s) {
                Text(selected.replacingOccurrences(of: ":", with: " : "))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BIRGELayout.xxs) {
                        ForEach(times, id: \.self) { time in
                            Button {
                                action(time)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(time)
                                    if time == selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .font(BIRGEFonts.captionBold)
                                .foregroundStyle(time == selected ? BIRGEColors.textOnBrand : BIRGEColors.brandPrimary)
                                .padding(.horizontal, BIRGELayout.xs)
                                .padding(.vertical, BIRGELayout.xxs)
                                .background(time == selected ? BIRGEColors.brandPrimary : BIRGEColors.brandPrimary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, BIRGELayout.xxxs)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.035), isInteractive: true)
        }
    }

    private func dayButton(_ day: OnboardingFeature.CommuteDay, number: Int) -> some View {
        let isActive = store.selectedDays.contains(day)

        return Button {
            store.send(.dayTapped(day))
        } label: {
            VStack(spacing: 2) {
                Text(day.rawValue)
                    .font(BIRGEFonts.captionBold)
                Text("\(number)")
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.82)
            }
            .foregroundStyle(isActive ? BIRGEColors.textOnBrand : BIRGEColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isActive ? BIRGEColors.brandPrimary : BIRGEColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }

    private func infoCard(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
            Image(systemName: symbol)
                .foregroundStyle(BIRGEColors.brandPrimary)
            Text(text)
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
    }

    private func dotsIndicator(count: Int, active: Int) -> some View {
        HStack(spacing: BIRGELayout.xxs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == active ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary.opacity(0.4))
                    .frame(width: index == active ? 24 : 8, height: 8)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                        value: store.currentPage
                    )
            }
        }
    }

    private var selectedDaysText: String {
        let days = OnboardingFeature.CommuteDay.allCases
            .filter { store.selectedDays.contains($0) }
            .map(\.rawValue)
            .joined(separator: ", ")
        return "\(days) (\(store.selectedDays.count) дней)"
    }

    private func advance() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
            _ = store.send(.nextTapped)
        }
    }
}

private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        stride(from: rect.minX, through: rect.maxX, by: 30).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        stride(from: rect.minY, through: rect.maxY, by: 30).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
