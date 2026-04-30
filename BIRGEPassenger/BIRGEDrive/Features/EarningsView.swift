//
//  EarningsView.swift
//  BIRGEDrive
//

import ComposableArchitecture
import SwiftUI

struct EarningsView: View {
    let store: StoreOf<EarningsFeature>

    var body: some View {
        List {
            // Stats cards section
            Section {
                statsGrid
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
            }

            // Today's rides
            Section("Поездки сегодня") {
                ForEach(store.mockRides) { ride in
                    rideRow(ride)
                }
            }
        }
        .navigationTitle("Заработок")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .onAppear { store.send(.onAppear) }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Сегодня",
                value: "\(store.todayTenge)₸",
                subtitle: "\(store.todayRides) поездок",
                icon: "sun.max.fill",
                color: .orange
            )
            statCard(
                title: "За неделю",
                value: "\(store.weekTenge)₸",
                subtitle: "Текущая неделя",
                icon: "calendar",
                color: .blue
            )
        }
        .padding(.horizontal, 4)
    }

    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2.weight(.bold))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func rideRow(_ ride: RideRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ride.route)
                    .font(.system(size: 14, weight: .medium))
                Text(ride.time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(ride.fare)₸")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(.systemGreen))
        }
        .padding(.vertical, 4)
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
