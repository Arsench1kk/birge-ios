import ComposableArchitecture
import SwiftUI

struct DriverAuthView: View {
    @Bindable var store: StoreOf<DriverAuthFeature>

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BIRGEColors.brandPrimary.opacity(0.16),
                    BIRGEColors.surfaceGrouped,
                    BIRGEColors.success.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: BIRGELayout.l) {
                Spacer()

                VStack(spacing: BIRGELayout.s) {
                    Image(systemName: "steeringwheel.circle.fill")
                        .font(.system(size: 62, weight: .semibold))
                        .foregroundStyle(BIRGEColors.brandPrimary)
                        .symbolRenderingMode(.hierarchical)

                    VStack(spacing: BIRGELayout.xxxs) {
                        Text(store.title)
                            .font(BIRGEFonts.title)
                            .foregroundStyle(BIRGEColors.textPrimary)
                        Text("BIRGE Driver")
                            .font(BIRGEFonts.subtext)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                }

                VStack(spacing: BIRGELayout.s) {
                    authField("Email", text: $store.email.sending(\.emailChanged), symbol: "envelope.fill", keyboard: .emailAddress)
                    authField("Пароль", text: $store.password.sending(\.passwordChanged), symbol: "lock.fill", isSecure: true)

                    if store.mode == .register {
                        authField("Телефон", text: $store.phone.sending(\.phoneChanged), symbol: "phone.fill", keyboard: .phonePad)
                        authField("Имя", text: $store.name.sending(\.nameChanged), symbol: "person.fill")
                    }

                    if let error = store.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    BIRGEPrimaryButton(title: store.primaryTitle, isLoading: store.isLoading) {
                        store.send(.submitTapped)
                    }

                    Button {
                        store.send(.modeToggled)
                    } label: {
                        Text(store.mode == .login ? "Создать водительский аккаунт" : "Уже есть аккаунт")
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.brandPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .padding(BIRGELayout.m)
                .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04), isInteractive: true)

                Spacer()
            }
            .padding(BIRGELayout.m)
        }
    }

    private func authField(
        _ title: String,
        text: Binding<String>,
        symbol: String,
        keyboard: UIKeyboardType = .default,
        isSecure: Bool = false
    ) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: symbol)
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 26)

            Group {
                if isSecure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                        .autocorrectionDisabled(keyboard == .emailAddress)
                }
            }
            .font(BIRGEFonts.body)
            .foregroundStyle(BIRGEColors.textPrimary)
        }
        .padding(.horizontal, BIRGELayout.s)
        .frame(height: 54)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.015), isInteractive: true)
    }
}

struct DriverRegistrationView: View {
    @Bindable var store: StoreOf<DriverRegistrationFeature>

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: BIRGELayout.m) {
                    titleBlock
                    stepContent
                }
                .padding(BIRGELayout.m)
                .padding(.bottom, 110)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomCTA
        }
        .background(BIRGEColors.surfaceGrouped.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: BIRGELayout.xxs) {
            HStack {
                Button {
                    store.send(.backTapped)
                } label: {
                    Label("Назад", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                }
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(store.canGoBack ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary)
                .disabled(!store.canGoBack)

                Spacer()

                Text(stepCounter)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            ProgressView(value: store.progress)
                .tint(BIRGEColors.brandPrimary)
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.s)
        .padding(.bottom, BIRGELayout.xs)
        .background(.ultraThinMaterial)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(subtitle)
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch store.step {
        case .personal:
            personalStep
        case .vehicle:
            vehicleStep
        case .documents:
            documentsStep
        case .tier:
            tierStep
        }
    }

    private var personalStep: some View {
        VStack(spacing: BIRGELayout.s) {
            HStack(spacing: BIRGELayout.xs) {
                field("Имя", text: $store.firstName.sending(\.firstNameChanged))
                field("Фамилия", text: $store.lastName.sending(\.lastNameChanged))
            }
            field("Дата рождения", text: $store.birthDate.sending(\.birthDateChanged), placeholder: "ДД.ММ.ГГГГ")
            field("ИИН", text: $store.iin.sending(\.iinChanged), placeholder: "000000000000", keyboard: .numberPad)

            HStack {
                Label("+7 777 ... 45 67", systemImage: "lock.fill")
                    .font(BIRGEFonts.body)
                    .foregroundStyle(BIRGEColors.textSecondary)
                Spacer()
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.02))

            infoCard("Данные используются только для верификации. Пассажиры видят ваше имя, рейтинг и автомобиль.", symbol: "lock.shield.fill", color: BIRGEColors.brandPrimary)
        }
    }

    private var vehicleStep: some View {
        VStack(spacing: BIRGELayout.s) {
            HStack(spacing: BIRGELayout.xs) {
                field("Марка", text: $store.carMake.sending(\.carMakeChanged), placeholder: "Toyota")
                field("Модель", text: $store.carModel.sending(\.carModelChanged), placeholder: "Camry")
            }
            HStack(spacing: BIRGELayout.xs) {
                field("Год", text: $store.carYear.sending(\.carYearChanged), placeholder: "2018", keyboard: .numberPad)
                field("Номер", text: $store.plateNumber.sending(\.plateNumberChanged), placeholder: "123 ABC 02")
            }

            Text("Цвет")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
            HStack(spacing: BIRGELayout.xs) {
                ForEach(CarColor.allCases, id: \.self) { color in
                    Button {
                        store.send(.colorSelected(color))
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Color.black.opacity(color == .white ? 0.12 : 0), lineWidth: 1))
                            .overlay {
                                if store.selectedColor == color {
                                    Circle().stroke(BIRGEColors.brandPrimary, lineWidth: 3)
                                        .padding(-4)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Мест для пассажиров")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textSecondary)
            HStack(spacing: BIRGELayout.xs) {
                ForEach([3, 4, 5, 6], id: \.self) { seats in
                    Button {
                        store.send(.seatsSelected(seats))
                    } label: {
                        Text(store.seats == seats ? "\(seats)✓" : "\(seats)")
                            .font(BIRGEFonts.bodyMedium)
                            .foregroundStyle(store.seats == seats ? BIRGEColors.textOnBrand : BIRGEColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(store.seats == seats ? BIRGEColors.brandPrimary : BIRGEColors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
                    }
                    .buttonStyle(.plain)
                }
            }

            previewCard
        }
    }

    private var documentsStep: some View {
        VStack(spacing: BIRGELayout.s) {
            infoCard("Нужны чёткие фото без бликов. Все 4 угла документа должны быть видны.", symbol: "doc.viewfinder.fill", color: BIRGEColors.warning)
            ForEach(DocumentKind.allCases, id: \.self) { document in
                documentCard(document)
            }
            infoCard("Документы зашифрованы и доступны только службе верификации.", symbol: "checkmark.shield.fill", color: BIRGEColors.success)
        }
    }

    private var tierStep: some View {
        VStack(spacing: BIRGELayout.s) {
            infoCard("Водители BIRGE зарабатывают больше за счёт подписки вместо комиссии.", symbol: "chart.line.uptrend.xyaxis", color: BIRGEColors.brandPrimary)
            ForEach(DriverTier.allCases, id: \.self) { tier in
                tierCard(tier)
            }
        }
    }

    private var bottomCTA: some View {
        VStack(spacing: BIRGELayout.xxs) {
            if let error = store.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            BIRGEPrimaryButton(
                title: store.step == .tier ? "Начать работу" : "Далее",
                isLoading: store.isSaving
            ) {
                store.send(.nextTapped)
            }
            if store.step == .documents {
                Text("Для демо можно продолжить без всех документов")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textTertiary)
            }
        }
        .padding(.horizontal, BIRGELayout.m)
        .padding(.top, BIRGELayout.s)
        .padding(.bottom, BIRGELayout.s)
        .background(.ultraThinMaterial)
    }

    private func field(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(title)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
            TextField(placeholder.isEmpty ? title : placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, BIRGELayout.s)
                .frame(height: 52)
                .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.015), isInteractive: true)
        }
    }

    private var previewCard: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "car.fill")
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 42, height: 42)
                .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.08))
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("\(store.carMake.isEmpty ? "Toyota" : store.carMake) \(store.carModel.isEmpty ? "Camry" : store.carModel) \(store.carYear.isEmpty ? "2018" : store.carYear)")
                    .font(BIRGEFonts.bodyMedium)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text("\(store.selectedColor.rawValue) · \(store.plateNumber.isEmpty ? "123 ABC 02" : store.plateNumber) · \(store.seats) места")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            Spacer()
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
    }

    private func documentCard(_ document: DocumentKind) -> some View {
        let uploaded = store.uploadedDocuments.contains(document)
        return Button {
            store.send(.documentTapped(document))
        } label: {
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: document.symbol)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 42, height: 42)
                    .liquidGlass(.button, tint: BIRGEColors.brandPrimary.opacity(0.08))
                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(document.rawValue)
                        .font(BIRGEFonts.bodyMedium)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(uploaded ? "Загружено" : "Нужно фото")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(uploaded ? BIRGEColors.success : BIRGEColors.textSecondary)
                }
                Spacer()
                Image(systemName: uploaded ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(uploaded ? BIRGEColors.success : BIRGEColors.brandPrimary)
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: uploaded ? BIRGEColors.success.opacity(0.04) : BIRGEColors.brandPrimary.opacity(0.025), isInteractive: true)
        }
        .buttonStyle(.plain)
    }

    private func tierCard(_ tier: DriverTier) -> some View {
        let selected = store.selectedTier == tier
        return Button {
            store.send(.tierSelected(tier))
        } label: {
            VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(tier.rawValue)
                            .font(BIRGEFonts.sectionTitle)
                            .foregroundStyle(BIRGEColors.textPrimary)
                        Text(tier.subtitle)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textSecondary)
                    }
                    Spacer()
                    Text(tier.price)
                        .font(BIRGEFonts.captionBold)
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }

                ForEach(tier.features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(BIRGEFonts.caption)
                        .foregroundStyle(BIRGEColors.textSecondary)
                }
            }
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: selected ? BIRGEColors.brandPrimary.opacity(0.08) : BIRGEColors.brandPrimary.opacity(0.02), isInteractive: true)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: BIRGELayout.radiusM)
                        .stroke(BIRGEColors.brandPrimary.opacity(0.35), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func infoCard(_ text: String, symbol: String, color: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(BIRGEFonts.caption)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .liquidGlass(.card, tint: color.opacity(0.05))
    }

    private var stepCounter: String {
        switch store.step {
        case .personal: return "Шаг 1 из 4"
        case .vehicle: return "Шаг 2 из 4"
        case .documents: return "Шаг 3 из 4"
        case .tier: return "Готово"
        }
    }

    private var title: String {
        switch store.step {
        case .personal: return "Расскажите о себе"
        case .vehicle: return "Ваш автомобиль"
        case .documents: return "Загрузите документы"
        case .tier: return "Выберите тариф"
        }
    }

    private var subtitle: String {
        switch store.step {
        case .personal: return "Личные данные для верификации"
        case .vehicle: return "Данные автомобиля для пассажиров"
        case .documents: return "Проверка занимает 24-48 часов"
        case .tier: return "Изменить можно в любой момент"
        }
    }
}

#Preview {
    DriverRegistrationView(
        store: Store(initialState: DriverRegistrationFeature.State()) {
            DriverRegistrationFeature()
        }
    )
}
