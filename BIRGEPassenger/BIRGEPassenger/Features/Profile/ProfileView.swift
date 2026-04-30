//
//  ProfileView.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    let store: StoreOf<ProfileFeature>
    
    var body: some View {
        List {
            headerSection
            
            statsSection
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            
            Section("Настройки") {
                settingsRow(icon: "bell.fill", color: .orange, title: "Уведомления")
                settingsRow(icon: "globe", color: .blue, title: "Язык")
                settingsRow(icon: "questionmark.circle.fill", color: .gray, title: "Помощь")
            }
            
            Section {
                Button(role: .destructive) {
                    store.send(.logoutTapped)
                } label: {
                    HStack {
                        Spacer()
                        Text("Выйти")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(BIRGEColors.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Text(store.name.prefix(1))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(BIRGEColors.blue)
            }
            .padding(.top, 16)
            
            VStack(spacing: 4) {
                Text(store.name)
                    .font(.title2.weight(.bold))
                
                Text(store.phone)
                    .font(.subheadline)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(
                icon: "star.fill",
                color: .yellow,
                value: String(format: "%.1f", store.rating),
                label: "Рейтинг"
            )
            
            statCard(
                icon: "car.fill",
                color: BIRGEColors.blue,
                value: "\(store.totalRides)",
                label: "Поездок"
            )
        }
        .padding(.horizontal)
    }
    
    private func statCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.headline)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(BIRGEColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func settingsRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(size: 16))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.gray.opacity(0.5))
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(
            store: Store(initialState: ProfileFeature.State(name: "Арсен", phone: "+7 777 123 4567", rating: 4.8, totalRides: 23)) {
                ProfileFeature()
            }
        )
    }
}
