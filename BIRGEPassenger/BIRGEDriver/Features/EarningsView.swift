//
//  EarningsView.swift
//  BIRGEDriver
//

import ComposableArchitecture
import Charts
import SwiftUI

struct EarningsView: View {
    let store: StoreOf<EarningsFeature>

    private struct WeeklyPoint: Identifiable {
        let id = UUID()
        let day: String
        let amount: Int
    }

    private var weeklyData: [WeeklyPoint] {
        [
            WeeklyPoint(day: "Пн", amount: max(0, store.weekTenge / 7 - 1200)),
            WeeklyPoint(day: "Вт", amount: max(0, store.weekTenge / 7 + 800)),
            WeeklyPoint(day: "Ср", amount: max(0, store.weekTenge / 7 - 400)),
            WeeklyPoint(day: "Чт", amount: max(0, store.weekTenge / 7 + 1600)),
            WeeklyPoint(day: "Пт", amount: max(0, store.weekTenge / 7 + 2200)),
            WeeklyPoint(day: "Сб", amount: max(0, store.weekTenge / 7 - 700)),
            WeeklyPoint(day: "Вс", amount: max(0, store.weekTenge / 7 - 2300)),
        ]
    }

    var body: some View {
        List {
            Section {
                todayHeroCard
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, BIRGELayout.xxs)
            }

            Section("Неделя") {
                weeklyChart
            }

            Section("Поездки сегодня") {
                if store.mockRides.isEmpty {
                    ContentUnavailableView(
                        "Поездок пока нет",
                        systemImage: "car.fill",
                        description: Text("Здесь появятся ваши поездки за сегодня.")
                    )
                } else {
                    ForEach(store.mockRides) { ride in
                        rideRow(ride)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BIRGEColors.surfaceGrouped)
        .navigationTitle("Заработок")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .onAppear { store.send(.onAppear) }
    }

    private var todayHeroCard: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                Label("Сегодня", systemImage: "sun.max.fill")
                    .font(BIRGEFonts.captionBold)
                    .foregroundStyle(BIRGEColors.warning)
                Spacer()
                Text("\(store.todayRides) поездок")
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }

            Text("\(store.todayTenge)₸")
                .font(BIRGEFonts.heroNumber)
                .foregroundStyle(BIRGEColors.textPrimary)

            Text("За неделю: \(store.weekTenge)₸")
                .font(BIRGEFonts.subtext)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BIRGELayout.m)
        .birgeCard()
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var weeklyChart: some View {
        Chart {
            ForEach(weeklyData) { point in
                BarMark(
                    x: .value("День", point.day),
                    y: .value("₸", point.amount)
                )
                .foregroundStyle(BIRGEColors.brandPrimary)
            }
        }
        .frame(height: 180)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .padding(.vertical, BIRGELayout.xs)
    }

    private func rideRow(_ ride: RideRecord) -> some View {
        HStack(spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(ride.route)
                    .font(BIRGEFonts.bodyMedium)
                    .lineLimit(2)
                Text(ride.time)
                    .font(BIRGEFonts.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(ride.fare)₸")
                .font(BIRGEFonts.bodyMedium)
                .foregroundStyle(BIRGEColors.success)
        }
        .padding(.vertical, BIRGELayout.xxxs)
    }
}

#Preview {
    NavigationStack {
        EarningsView(
            store: Store(
                initialState: EarningsFeature.State(
                    todayTenge: 12500,
                    todayRides: 8,
                    weekTenge: 67000
                )
            ) {
                EarningsFeature()
            }
        )
    }
}
