import BIRGECore
import ComposableArchitecture
import SwiftUI

@ViewAction(for: ProjectDemoFeature.self)
struct ProjectDemoView: View {
    @Bindable var store: StoreOf<ProjectDemoFeature>

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                header
                tabPicker

                if let message = store.errorMessage {
                    BIRGEToast(message: message, style: .error)
                }

                if store.isLoading && store.demoState == nil {
                    loadingCard
                } else {
                    content
                }
            }
            .padding(BIRGELayout.s)
        }
        .background(BIRGEColors.surfaceGrouped.ignoresSafeArea())
        .navigationTitle("Демо проекта")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { send(.refreshTapped) } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading || store.isMutating)
                .accessibilityLabel("Обновить demo state")

                Menu {
                    Button { send(.seedTapped) } label: {
                        Label("Seed demo data", systemImage: "plus.circle")
                    }
                    Button(role: .destructive) { send(.resetTapped) } label: {
                        Label("Reset demo data", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(store.isMutating)
                .accessibilityLabel("Demo actions")
            }
        }
        .task { send(.onAppear) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: "rectangle.stack.badge.play")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .frame(width: 54, height: 54)
                    .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.08), isInteractive: true)

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text("BIRGE Defense Mode")
                        .font(BIRGEFonts.title)
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text("Live backend, Postgres, Redis, WebSocket и AI matching в одном месте.")
                        .font(BIRGEFonts.subtext)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            apiBaseURLCard
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.info.opacity(0.08), isInteractive: true)
    }

    private var apiBaseURLCard: some View {
        HStack(spacing: BIRGELayout.xs) {
            Image(systemName: "network")
                .foregroundStyle(BIRGEColors.info)
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Current API base URL")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.textTertiary)
                Text(store.demoState?.apiBaseURL ?? BIRGEAPIConfiguration.baseURLString)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 0)
        }
        .padding(BIRGELayout.xs)
        .liquidGlass(.card, tint: BIRGEColors.info.opacity(0.06))
    }

    private var tabPicker: some View {
        Picker(
            "Demo section",
            selection: Binding(
                get: { store.selectedTab },
                set: { send(.tabSelected($0)) }
            )
        ) {
            ForEach(ProjectDemoFeature.DemoTab.allCases) { tab in
                Label(tab.title, systemImage: tab.symbol)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var content: some View {
        switch store.selectedTab {
        case .overview:
            overviewTab
        case .database:
            databaseTab
        case .live:
            liveTab
        case .ai:
            aiTab
        }
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            sectionTitle("Архитектура", symbol: "point.3.connected.trianglepath.dotted")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: BIRGELayout.xs)], spacing: BIRGELayout.xs) {
                overviewCard("Passenger", "создаёт ride, видит статус и GPS", "iphone", BIRGEColors.brandPrimary)
                overviewCard("Driver", "получает offers, accept/decline, отправляет GPS", "car.fill", BIRGEColors.success)
                overviewCard("Vapor", "JWT API, WebSocket hub, бизнес-логика", "server.rack", BIRGEColors.info)
                overviewCard("Postgres", "таблицы users, rides, payments, corridors", "cylinder.split.1x2", BIRGEColors.warning)
                overviewCard("Redis", "OTP, refresh sessions, blacklist", "bolt.horizontal.circle", BIRGEColors.danger)
                overviewCard("WebSocket", "ride.status_changed и ride.location_update", "dot.radiowaves.left.and.right", BIRGEColors.brandPrimary)
            }
        }
    }

    private func overviewCard(_ title: String, _ text: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .liquidGlass(.pill, tint: color.opacity(0.09))
            Text(title)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(text)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: color.opacity(0.05), isInteractive: true)
    }

    private var databaseTab: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                sectionTitle("Live Postgres", symbol: "server.rack")
                Spacer()
                if store.isMutating {
                    ProgressView()
                        .tint(BIRGEColors.brandPrimary)
                }
            }

            if let tables = store.demoState?.tables, !tables.isEmpty {
                ForEach(tables) { table in
                    tableSnapshot(table)
                }
            } else {
                emptyCard("Нет данных таблиц. Нажмите Seed demo data в меню.")
            }
        }
    }

    private func tableSnapshot(_ table: DemoTableSnapshot) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(table.name)
                    .font(.system(.headline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                Spacer()
                Text("\(table.count)")
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.brandPrimary)
                    .monospacedDigit()
            }

            Text(table.explanation)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)

            Label(table.source, systemImage: "arrow.down.doc")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textTertiary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            if table.rows.isEmpty {
                Text("Последних записей пока нет")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textTertiary)
            } else {
                ForEach(table.rows) { row in
                    rowView(row)
                }
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.045), isInteractive: true)
    }

    private func rowView(_ row: DemoTableRow) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(row.primary)
                .font(.system(.caption, design: .monospaced, weight: .semibold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(row.secondary)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: BIRGELayout.xxs)], spacing: BIRGELayout.xxxs) {
                ForEach(Array(row.fields.enumerated()), id: \.offset) { _, field in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(field.key)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BIRGEColors.textTertiary)
                            .lineLimit(1)
                        Text(field.value)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(BIRGEColors.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(BIRGELayout.xs)
        .background(BIRGEColors.surfaceElevated.opacity(0.72), in: RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
    }

    private var liveTab: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            sectionTitle("Live-сценарий защиты", symbol: "checklist")
            liveStep("1", "Passenger создаёт ride", "POST /api/v1/rides сохраняет строку в rides со status=requested.", "rides")
            liveStep("2", "Driver видит offer", "GET /api/v1/rides/driver/offers отдаёт только свежие requested rides.", "rides")
            liveStep("3", "Accept или decline", "accept ставит driver_accepted, decline пишет driver_ride_decisions.", "driver_ride_decisions")
            liveStep("4", "Passenger получает событие", "WebSocket отправляет ride.status_changed и переводит экран поездки.", "WebSocket")
            liveStep("5", "GPS идёт live", "BIRGEDrive syncPendingLocations пишет driver_location_records каждые 5 секунд.", "driver_location_records")
            liveStep("6", "Оплата/подписка", "Kaspi checkout и тарифы показываются в payment_events и passenger_subscriptions.", "payment_events")
        }
    }

    private func liveStep(_ index: String, _ title: String, _ text: String, _ table: String) -> some View {
        HStack(alignment: .top, spacing: BIRGELayout.xs) {
            Text(index)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(BIRGEColors.textOnBrand)
                .frame(width: 34, height: 34)
                .background(BIRGEColors.brandPrimary, in: Circle())

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(title)
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
                Text(text)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Label(table, systemImage: "tablecells")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.brandPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.success.opacity(0.05), isInteractive: true)
    }

    private var aiTab: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            sectionTitle("AI corridor matching", symbol: "sparkles")

            if let ai = store.demoState?.ai {
                VStack(alignment: .leading, spacing: BIRGELayout.xs) {
                    BIRGEAIPill("AI matching engine: deterministic scoring for route grouping")
                    Text(ai.explanation)
                        .font(BIRGEFonts.subtext)
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    fieldGrid(title: "Input", fields: ai.input)
                    fieldGrid(title: "Scoring", fields: ai.scoring)
                    ForEach(ai.candidates) { candidate in
                        aiCandidate(candidate)
                    }
                }
            } else {
                emptyCard("AI snapshot появится после загрузки demo state.")
            }
        }
    }

    private func fieldGrid(title: String, fields: [DemoField]) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxs) {
            Text(title)
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.textTertiary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: BIRGELayout.xxs)], spacing: BIRGELayout.xxs) {
                ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(field.key)
                            .font(BIRGEFonts.captionBold)
                            .foregroundStyle(BIRGEColors.brandPrimary)
                        Text(field.value)
                            .font(BIRGEFonts.caption)
                            .foregroundStyle(BIRGEColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(BIRGELayout.xs)
                    .background(BIRGEColors.surfaceElevated.opacity(0.72), in: RoundedRectangle(cornerRadius: BIRGELayout.radiusS))
                }
            }
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.04))
    }

    private func aiCandidate(_ candidate: DemoAICandidate) -> some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                BIRGEMatchBadge(candidate.matchPercent)
                Spacer()
                Text("\(candidate.priceTenge)₸")
                    .font(BIRGEFonts.sectionTitle)
                    .foregroundStyle(BIRGEColors.textPrimary)
            }
            Text(candidate.route)
                .font(BIRGEFonts.sectionTitle)
                .foregroundStyle(BIRGEColors.textPrimary)
            Text(candidate.reason)
                .font(BIRGEFonts.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
            Label("\(candidate.seatsLeft) seats left", systemImage: "person.2.fill")
                .font(BIRGEFonts.captionBold)
                .foregroundStyle(BIRGEColors.success)
        }
        .padding(BIRGELayout.s)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.06), isInteractive: true)
    }

    private var loadingCard: some View {
        HStack(spacing: BIRGELayout.xs) {
            ProgressView()
                .tint(BIRGEColors.brandPrimary)
            Text("Загружаем live demo state")
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .liquidGlass(.card, tint: BIRGEColors.brandPrimary.opacity(0.05))
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(BIRGEFonts.subtext)
            .foregroundStyle(BIRGEColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIRGELayout.s)
            .liquidGlass(.card)
    }

    private func sectionTitle(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(BIRGEFonts.sectionTitle)
            .foregroundStyle(BIRGEColors.textPrimary)
    }
}

#Preview {
    NavigationStack {
        ProjectDemoView(
            store: Store(initialState: ProjectDemoFeature.State(demoState: .sample())) {
                ProjectDemoFeature()
            }
        )
    }
}
