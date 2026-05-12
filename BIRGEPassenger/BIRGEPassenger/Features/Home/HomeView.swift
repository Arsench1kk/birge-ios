import BIRGECore
import ComposableArchitecture
import SwiftUI

@ViewAction(for: HomeFeature.self)
struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeRouteMap(segment: store.nextPlannedRideSegment, routes: store.recurringRoutes)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topGlassHeader
                Spacer(minLength: 0)
            }
            .padding(.top, BIRGELayout.xs)
            .padding(.horizontal, BIRGELayout.s)

            HomeOperationalSheet(store: store)
        }
        .background(BIRGEColors.routeCanvasBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            HomeTabBar(
                routesAction: { send(.manageRoutesTapped) },
                historyAction: { send(.rideHistoryTapped) },
                profileAction: { send(.profileButtonTapped) }
            )
        }
        .task {
            send(.onAppear)
        }
        .navigationBarHidden(true)
    }

    private var topGlassHeader: some View {
        HStack(spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(planMeta)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(store.todayPlan?.dateLabel ?? "Today")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
            }

            Spacer()

            HeaderIconButton(systemImage: "arrow.clockwise", label: "Refresh today plan") {
                send(.refreshTodayPlan)
            }
            .accessibilityIdentifier("home_refresh_today")

            HeaderIconButton(systemImage: "person.crop.circle.fill", label: "Profile") {
                send(.profileButtonTapped)
            }
            .accessibilityIdentifier("home_profile")
        }
        .padding(.horizontal, BIRGELayout.s)
        .padding(.vertical, BIRGELayout.xs)
        .background(BIRGEColors.passengerSurfaceElevated.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
        .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(BIRGEColors.borderSubtle, lineWidth: 1))
        .shadow(color: BIRGEColors.textPrimary.opacity(0.08), radius: 20, y: 8)
    }

    private var planMeta: String {
        guard let activePlan = store.activePlan else { return "Monthly commute" }
        return "\(activePlan.planType.rawValue) · \(activePlan.status)"
    }
}

private struct HomeOperationalSheet: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BIRGELayout.s) {
                Capsule()
                    .fill(BIRGEColors.textPrimary.opacity(0.16))
                    .frame(width: 38, height: 4)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                if store.isLoadingDashboard {
                    ProgressView()
                        .tint(BIRGEColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("home_dashboard_loading")
                }

                if let dashboardError = store.dashboardError {
                    HomeErrorBanner(message: dashboardError)
                        .accessibilityIdentifier("home_dashboard_error")
                }

                TodayCommuteCard(todayPlan: store.todayPlan) {
                    store.send(.view(.todayRideTapped))
                }
                .accessibilityIdentifier("home_today_commute")

                if let activePlan = store.activePlan {
                    ActivePlanStrip(plan: activePlan) {
                        store.send(.view(.subscriptionTapped))
                    }
                    .accessibilityIdentifier("home_active_plan")
                }

                RouteManagementSection(routes: store.recurringRoutes) { id in
                    store.send(.view(.routeTapped(id)))
                } manageAction: {
                    store.send(.view(.manageRoutesTapped))
                }
                .accessibilityIdentifier("home_route_management")

                InsightsSection(insights: store.insights) {
                    store.send(.view(.aiExplanationTapped))
                }

                if let fallbackTaxi = store.fallbackTaxi {
                    FallbackTaxiLink(option: fallbackTaxi) {
                        store.send(.view(.fallbackTaxiTapped))
                    }
                    .accessibilityIdentifier("home_fallback_taxi")
                }
            }
            .padding(.horizontal, BIRGELayout.m)
            .padding(.top, BIRGELayout.xs)
            .padding(.bottom, 118)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 470)
        .background(BIRGEColors.passengerBackground.opacity(0.94))
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 28,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 28
        ))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28
            )
            .stroke(BIRGEColors.passengerSurfaceElevated.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: BIRGEColors.textPrimary.opacity(0.13), radius: 28, y: -12)
    }
}

private struct TodayCommuteCard: View {
    let todayPlan: MockTodayCommutePlan?
    let openAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text("Next corridor")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .textCase(.uppercase)

                Text(title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let segment = todayPlan?.nextSegment {
                PlannedRouteStrip(segment: segment)

                Button(action: openAction) {
                    HStack {
                        Text("Open corridor")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(BIRGEColors.textOnBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .padding(.horizontal, BIRGELayout.s)
                    .background(BIRGEColors.brandPrimary)
                    .clipShape(Capsule())
                }
                .buttonStyle(BIRGEPressableButtonStyle())
                .accessibilityIdentifier("home_open_today_ride")
            } else {
                StatusFactStrip(status: todayPlan?.status ?? .noCommuteToday)
            }
        }
    }

    private var title: String {
        guard let todayPlan else { return "Plan loading" }
        if let segment = todayPlan.nextSegment {
            return "\(segment.pickupNode.title) → \(segment.dropoffNode.title)"
        }
        return statusTitle(todayPlan.status)
    }

    private var subtitle: String {
        guard let todayPlan else { return "BIRGE is preparing the dashboard." }
        if let segment = todayPlan.nextSegment {
            return "Arrive by \(segment.departureWindowStart)."
        }
        return statusSubtitle(todayPlan.status)
    }
}

private struct PlannedRouteStrip: View {
    let segment: MockPlannedRideSegment

    var body: some View {
        HStack(alignment: .center, spacing: BIRGELayout.xs) {
            Text(segment.departureWindowStart)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(BIRGEColors.brandPrimary)
                .padding(.horizontal, BIRGELayout.xxs)
                .padding(.vertical, 5)
                .background(BIRGEColors.brandPrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusXS))

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(segment.pickupNode.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(1)
                Text(segment.dropoffNode.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: BIRGELayout.xs)

            Text(segment.rideDayStatus.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BIRGEColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.vertical, BIRGELayout.xs)
        .overlay(alignment: .top) {
            Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
        }
    }
}

private struct ActivePlanStrip: View {
    let plan: MockMonthlyCommutePlan
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(BIRGEColors.success)

                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(plan.status)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(plan.planType.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BIRGEColors.textSecondary)
                }

                Spacer(minLength: BIRGELayout.xs)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BIRGEColors.textTertiary)
            }
            .padding(BIRGELayout.s)
            .background(BIRGEColors.success.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
            .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(BIRGEColors.success.opacity(0.24), lineWidth: 1))
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }
}

private struct RouteManagementSection: View {
    let routes: [MockRecurringRoute]
    let routeAction: (MockRecurringRoute.ID) -> Void
    let manageAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xs) {
            HStack {
                Text("My Routes")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                Spacer()
                Button(action: manageAction) {
                    Text("Manage")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(BIRGEColors.brandPrimary)
                }
                .buttonStyle(BIRGEPressableButtonStyle())
                .accessibilityIdentifier("home_manage_routes")
            }

            VStack(spacing: 0) {
                ForEach(Array(routes.prefix(3).enumerated()), id: \.element.id) { index, route in
                    Button {
                        routeAction(route.id)
                    } label: {
                        RouteRow(route: route, isLast: index == min(routes.count, 3) - 1)
                    }
                    .buttonStyle(BIRGEPressableButtonStyle())
                    .accessibilityIdentifier("home_route_\(route.id.uuidString)")
                }
            }
            .background(RowListBackground())
        }
    }
}

private struct RouteRow: View {
    let route: MockRecurringRoute
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: BIRGELayout.xs) {
            Text(route.schedule.departureWindowStart)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(BIRGEColors.textPrimary)
                .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                Text(route.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BIRGEColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: BIRGELayout.xxxs) {
                    Circle()
                        .fill(route.status == .active ? BIRGEColors.success : BIRGEColors.textTertiary)
                        .frame(width: 7, height: 7)
                    Text("\(route.originName) → \(route.destinationName) · \(route.status.rawValue)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: BIRGELayout.xs)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BIRGEColors.textTertiary)
        }
        .frame(minHeight: 58)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
            }
        }
    }
}

private struct InsightsSection: View {
    let insights: [MockPassengerInsight]
    let action: () -> Void

    var body: some View {
        if let insight = insights.first {
            Button(action: action) {
                HStack(alignment: .top, spacing: BIRGELayout.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(BIRGEColors.brandSecondary)
                        .frame(width: 34, height: 34)
                        .background(BIRGEColors.brandPrimary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusS))

                    VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                        Text(insight.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(BIRGEColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(insight.body)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BIRGEColors.textSecondary)
                            .lineLimit(3)
                    }

                    Spacer(minLength: BIRGELayout.xs)
                }
                .padding(BIRGELayout.s)
                .background(BIRGEColors.brandPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
                .overlay(RoundedRectangle(cornerRadius: BIRGELayout.radiusM).stroke(BIRGEColors.brandPrimary.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(BIRGEPressableButtonStyle())
            .accessibilityIdentifier("home_insight")
        }
    }
}

private struct FallbackTaxiLink: View {
    let option: MockFallbackTaxiOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BIRGELayout.xs) {
                Image(systemName: "car")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BIRGEColors.textSecondary)
                VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
                    Text(option.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(BIRGEColors.textPrimary)
                    Text(option.subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BIRGEColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: BIRGELayout.xs)
                Text("\(option.estimatedPickupMinutes) min")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BIRGEColors.textSecondary)
            }
            .padding(.vertical, BIRGELayout.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(BIRGEPressableButtonStyle())
    }
}

private struct StatusFactStrip: View {
    let status: MockTodayCommuteStatus

    var body: some View {
        HStack(spacing: BIRGELayout.xs) {
            StatusFact(title: "Status", value: status.rawValue)
            StatusFact(title: "Routes", value: "Saved")
            StatusFact(title: "Next", value: "Later")
        }
        .padding(.vertical, BIRGELayout.xs)
        .overlay(alignment: .top) {
            Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
        }
    }
}

private struct StatusFact: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: BIRGELayout.xxxs) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BIRGEColors.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomeRouteMap: View {
    let segment: MockPlannedRideSegment?
    let routes: [MockRecurringRoute]

    var body: some View {
        ZStack {
            BIRGEColors.routeCanvasBackground
            CanvasGrid()
            BackgroundRoads()

            RouteCurve()
                .stroke(BIRGEColors.brandPrimary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .shadow(color: BIRGEColors.brandPrimary.opacity(0.24), radius: 10, y: 4)
                .padding(.horizontal, 48)
                .padding(.top, 120)
                .padding(.bottom, 240)

            MapPin(title: segment?.pickupNode.title ?? routes.first?.originName ?? "Pickup", kind: .pickup)
                .position(x: 108, y: 330)

            MapPin(title: segment?.dropoffNode.title ?? routes.first?.destinationName ?? "Dropoff", kind: .dropoff)
                .position(x: 298, y: 210)

            DriverDot()
                .position(x: 206, y: 292)
        }
    }
}

private struct CanvasGrid: View {
    var body: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                Rectangle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.045))
                    .frame(height: 1)
                    .offset(y: CGFloat(index * 32) - 280)
                Rectangle()
                    .fill(BIRGEColors.brandPrimary.opacity(0.045))
                    .frame(width: 1)
                    .offset(x: CGFloat(index * 32) - 280)
            }
        }
    }
}

private struct BackgroundRoads: View {
    var body: some View {
        ZStack {
            RouteCurve()
                .stroke(BIRGEColors.textTertiary.opacity(0.42), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-4))
                .padding(.horizontal, 10)
                .padding(.top, 92)
                .padding(.bottom, 260)
            RouteCurve()
                .stroke(BIRGEColors.textTertiary.opacity(0.25), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(18))
                .padding(.horizontal, 30)
                .padding(.top, 180)
                .padding(.bottom, 120)
        }
    }
}

private struct RouteCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 30, y: rect.maxY - 90))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 18, y: rect.minY + 52),
            control1: CGPoint(x: rect.midX - 30, y: rect.midY + 80),
            control2: CGPoint(x: rect.midX + 58, y: rect.midY - 80)
        )
        return path
    }
}

private struct MapPin: View {
    enum Kind {
        case pickup
        case dropoff
    }

    let title: String
    let kind: Kind

    var body: some View {
        VStack(spacing: BIRGELayout.xxxs) {
            Circle()
                .fill(kind == .pickup ? BIRGEColors.brandPrimary : BIRGEColors.danger)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(BIRGEColors.passengerSurfaceElevated, lineWidth: 3))
                .shadow(color: BIRGEColors.textPrimary.opacity(0.18), radius: 8, y: 4)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(BIRGEColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, BIRGELayout.xs)
                .padding(.vertical, BIRGELayout.xxxs)
                .background(BIRGEColors.passengerSurfaceElevated.opacity(0.88))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(BIRGEColors.borderSubtle, lineWidth: 1))
        }
        .frame(width: 116)
    }
}

private struct DriverDot: View {
    var body: some View {
        Text("B")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(BIRGEColors.textOnBrand)
            .frame(width: 30, height: 30)
            .background(BIRGEColors.textPrimary)
            .clipShape(Circle())
            .overlay(Circle().stroke(BIRGEColors.passengerSurfaceElevated, lineWidth: 3))
            .shadow(color: BIRGEColors.textPrimary.opacity(0.24), radius: 10, y: 4)
    }
}

private struct HeaderIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(BIRGEColors.brandPrimary)
                .frame(width: 36, height: 36)
                .background(BIRGEColors.passengerSurfaceElevated)
                .clipShape(Circle())
                .overlay(Circle().stroke(BIRGEColors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .accessibilityLabel(label)
    }
}

private struct HomeTabBar: View {
    let routesAction: () -> Void
    let historyAction: () -> Void
    let profileAction: () -> Void

    var body: some View {
        HStack {
            tabItem(symbol: "house", label: "Home", isActive: true) {}
            tabItem(symbol: "arrow.up.right", label: "Routes", isActive: false, action: routesAction)
            tabItem(symbol: "list.bullet", label: "History", isActive: false, action: historyAction)
            tabItem(symbol: "person", label: "Profile", isActive: false, action: profileAction)
        }
        .padding(.horizontal, BIRGELayout.s)
        .padding(.top, BIRGELayout.xs)
        .padding(.bottom, BIRGELayout.s)
        .background(BIRGEColors.passengerBackground.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
        }
    }

    private func tabItem(
        symbol: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: BIRGELayout.xxxs) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isActive ? BIRGEColors.brandPrimary : BIRGEColors.textTertiary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BIRGEPressableButtonStyle())
        .accessibilityIdentifier("home_tab_\(label.lowercased())")
    }
}

private struct HomeErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(BIRGEColors.danger)
            .padding(BIRGELayout.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BIRGEColors.danger.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: BIRGELayout.radiusM))
    }
}

private struct RowListBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(BIRGEColors.passengerBackground)
            .overlay(alignment: .top) {
                Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(BIRGEColors.borderSubtle).frame(height: 1)
            }
    }
}

private func statusTitle(_ status: MockTodayCommuteStatus) -> String {
    switch status {
    case .planned:
        return "Today route is planned"
    case .noCommuteToday:
        return "No commute today"
    case .routePaused:
        return "Route is paused"
    case .lowMatch:
        return "Matching is harder"
    case .waitlist:
        return "Waiting for a match"
    }
}

private func statusSubtitle(_ status: MockTodayCommuteStatus) -> String {
    switch status {
    case .planned:
        return "Your commute route is ready."
    case .noCommuteToday:
        return "Saved routes remain available in My Routes."
    case .routePaused:
        return "Resume the route from My Routes when needed."
    case .lowMatch:
        return "Try widening the time window or changing a node."
    case .waitlist:
        return "BIRGE will surface the route when matching improves."
    }
}

#Preview("Active Dashboard") {
    HomeView(
        store: Store(initialState: previewState()) {
            HomeFeature()
        }
    )
}

#Preview("No Commute Today") {
    var state = previewState()
    state.todayPlan = BIRGEProductFixtures.Passenger.noCommuteTodayPlan
    return HomeView(
        store: Store(initialState: state) {
            HomeFeature()
        }
    )
}

#Preview("Route Statuses") {
    var state = previewState()
    var paused = BIRGEProductFixtures.Passenger.recurringRoutes[0]
    paused.status = .paused
    var low = BIRGEProductFixtures.Passenger.recurringRoutes[1]
    low.status = .lowDensity
    var wait = BIRGEProductFixtures.Passenger.recurringRoutes[2]
    wait.status = .waitlist
    state.recurringRoutes = [paused, low, wait]
    state.todayPlan = MockTodayCommutePlan(
        id: UUID(uuidString: "82000000-0000-0000-0000-000000000099")!,
        status: .lowMatch,
        dateLabel: "Today",
        nextSegment: nil
    )
    return HomeView(
        store: Store(initialState: state) {
            HomeFeature()
        }
    )
}

private func previewState() -> HomeFeature.State {
    let dashboard = BIRGEProductFixtures.Passenger.homeDashboard
    var state = HomeFeature.State()
    state.activePlan = dashboard.activePlan
    state.recurringRoutes = dashboard.recurringRoutes
    state.todayPlan = dashboard.todayPlan
    state.insights = dashboard.insights
    state.fallbackTaxi = dashboard.fallbackTaxi
    return state
}
