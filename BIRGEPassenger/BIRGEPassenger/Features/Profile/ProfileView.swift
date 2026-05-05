//
//  ProfileView.swift
//  BIRGEPassenger
//

import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    let store: StoreOf<ProfileFeature>
    
    private enum Texts {
        static let loading = "Загружаем профиль"
        static let retry = "Повторить"
        static let profileUnavailable = "Не удалось загрузить профиль"
    }
    
    var body: some View {
        List {
            Section("Account") {
                headerSection
            }

            Section("Stats") {
                statsSection
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, BIRGELayout.xxs)
            }

            Section("Settings") {
                BIRGEListRow(title: "Уведомления", systemImage: "bell.fill", tint: .orange)
                BIRGEListRow(title: "Язык", systemImage: "globe", tint: .blue)
            }

            Section("Support") {
                BIRGEListRow(title: "Помощь", systemImage: "questionmark.circle.fill", tint: .gray)
            }

            Section("Legal") {
                BIRGEListRow(
                    title: "Правовые документы",
                    systemImage: "doc.text.fill",
                    tint: BIRGEColors.textSecondary
                )
            }

            if let errorMessage = store.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Texts.profileUnavailable)
                            .font(BIRGEFonts.sectionTitle)
                        Text(errorMessage)
                            .font(BIRGEFonts.subtext)
                            .foregroundStyle(BIRGEColors.textSecondary)
                        Button(Texts.retry) {
                            store.send(.onAppear)
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, BIRGELayout.xxs)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(BIRGEColors.surfaceGrouped)
        .redacted(reason: store.isLoading ? .placeholder : [])
        .safeAreaInset(edge: .bottom) {
            BIRGEDestructiveButton(title: "Выйти") {
                store.send(.logoutTapped)
            }
            .padding(.horizontal, BIRGELayout.s)
            .padding(.bottom, BIRGELayout.s)
            .background(BIRGEColors.surfaceGrouped)
        }
        .disabled(store.isLoading)
        .overlay {
            if store.isLoading {
                loadingOverlay
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

    private var loadingOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: BIRGELayout.xs) {
                ProgressView()
                Text(Texts.loading)
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(BIRGELayout.m)
            .birgeCard()
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: BIRGELayout.xs) {
            ZStack {
                Circle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Text(avatarText)
                    .font(BIRGEFonts.heroNumber)
                    .foregroundStyle(BIRGEColors.brandPrimary)
            }
            .padding(.top, BIRGELayout.s)
            
            VStack(spacing: BIRGELayout.xxxs) {
                Text(displayName)
                    .font(BIRGEFonts.title)
                
                Text(displayPhone)
                    .font(BIRGEFonts.subtext)
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(.bottom, BIRGELayout.s)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }

    private var displayName: String {
        if store.name.isEmpty {
            return store.phone.isEmpty ? "Профиль" : store.phone
        }
        return store.name
    }

    private var displayPhone: String {
        if store.phone.isEmpty, store.isLoading {
            return "+7 000 000 00 00"
        }
        return store.phone
    }

    private var avatarText: String {
        String(displayName.prefix(1))
    }
    
    private var statsSection: some View {
        HStack(spacing: BIRGELayout.s) {
            statCard(
                icon: "star.fill",
                color: .yellow,
                value: String(format: "%.1f", store.rating),
                label: "Рейтинг"
            )
            
            statCard(
                icon: "car.fill",
                color: BIRGEColors.brandPrimary,
                value: "\(store.totalRides)",
                label: "Поездок"
            )
        }
        .padding(.horizontal, BIRGELayout.s)
    }
    
    private func statCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: BIRGELayout.xxs) {
            HStack(spacing: BIRGELayout.xxs) {
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
        .padding(.vertical, BIRGELayout.s)
        .birgeCard()
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
}

#Preview {
    NavigationStack {
        ProfileView(
            store: Store(initialState: ProfileFeature.State()) {
                ProfileFeature()
            }
        )
    }
}
