import Foundation

public enum BIRGEProductFixtures {
    public enum IDs {
        public static let passengerComplete = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        public static let passengerIncomplete = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        public static let routeAlatauEsentai = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        public static let routeEsentaiAlatau = UUID(uuidString: "20000000-0000-0000-0000-000000000002")!
        public static let pickupAlatau = UUID(uuidString: "30000000-0000-0000-0000-000000000001")!
        public static let dropoffEsentai = UUID(uuidString: "30000000-0000-0000-0000-000000000002")!
        public static let driverApproved = UUID(uuidString: "40000000-0000-0000-0000-000000000001")!
        public static let driverPending = UUID(uuidString: "40000000-0000-0000-0000-000000000002")!
        public static let driverFailed = UUID(uuidString: "40000000-0000-0000-0000-000000000003")!
        public static let driverCorridorMorning = UUID(uuidString: "50000000-0000-0000-0000-000000000001")!
    }

    public enum Phones {
        public static let unknownPassenger = "+77770000000"
        public static let incompletePassenger = "+77770000010"
        public static let completePassengerNoRoute = "+77770000011"
        public static let passengerWithRouteNoPlan = "+77770000012"
        public static let activePassenger = "+77770000013"
        public static let unknownDriver = "+77770000020"
        public static let pendingDriver = "+77770000021"
        public static let failedDriver = "+77770000022"
        public static let approvedDriverNoCorridor = "+77770000023"
        public static let activeDriver = "+77770000024"
    }

    public enum Passenger {
        public static let profiles: [MockPassengerProfile] = [
            MockPassengerProfile(
                id: IDs.passengerComplete,
                phoneNumber: Phones.activePassenger,
                displayName: "Данияр",
                isProfileComplete: true,
                hasAcceptedTrustConsent: true
            ),
            MockPassengerProfile(
                id: IDs.passengerIncomplete,
                phoneNumber: Phones.incompletePassenger,
                displayName: "",
                isProfileComplete: false,
                hasAcceptedTrustConsent: false
            )
        ]

        public static let pickupNodes: [MockCommuteNode] = [
            MockCommuteNode(
                id: IDs.pickupAlatau,
                title: "Алатау City, северный вход",
                subtitle: "До 4 минут пешком",
                coordinate: LatLng(latitude: 43.2632, longitude: 76.8217),
                walkingMinutes: 4
            )
        ]

        public static let dropoffNodes: [MockCommuteNode] = [
            MockCommuteNode(
                id: IDs.dropoffEsentai,
                title: "Esentai / Al-Farabi",
                subtitle: "Высадка у бизнес-кластера",
                coordinate: LatLng(latitude: 43.2189, longitude: 76.9275),
                walkingMinutes: 3
            )
        ]

        public static let addressSearchResults: [MockAddressSearchResult] = [
            MockAddressSearchResult(
                id: UUID(uuidString: "31000000-0000-0000-0000-000000000001")!,
                title: "Alatau City",
                subtitle: "Residential cluster",
                fullAddress: "Alatau City, Almaty",
                coordinate: LatLng(latitude: 43.2632, longitude: 76.8217)
            ),
            MockAddressSearchResult(
                id: UUID(uuidString: "31000000-0000-0000-0000-000000000002")!,
                title: "Esentai / Al-Farabi",
                subtitle: "Business corridor",
                fullAddress: "Esentai / Al-Farabi, Almaty",
                coordinate: LatLng(latitude: 43.2189, longitude: 76.9275)
            )
        ]

        public static let morningSchedule = MockRouteSchedule(
            weekdays: ["mon", "tue", "wed", "thu", "fri"],
            departureWindowStart: "07:15",
            departureWindowEnd: "08:30"
        )

        public static let draftRoute = MockRouteDraft(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000010")!,
            displayName: "Alatau City -> Esentai / Al-Farabi",
            originAddress: "Alatau City",
            destinationAddress: "Esentai / Al-Farabi",
            suggestedPickupNodes: pickupNodes,
            suggestedDropoffNodes: dropoffNodes,
            selectedPickupNodeID: IDs.pickupAlatau,
            selectedDropoffNodeID: IDs.dropoffEsentai,
            schedule: morningSchedule
        )

        public static let recurringRoutes: [MockRecurringRoute] = [
            MockRecurringRoute(
                id: IDs.routeAlatauEsentai,
                name: "Дом -> работа",
                originName: "Alatau City",
                destinationName: "Esentai / Al-Farabi",
                pickupNode: pickupNodes[0],
                dropoffNode: dropoffNodes[0],
                schedule: morningSchedule,
                status: .active,
                reliabilityPercent: 92
            ),
            MockRecurringRoute(
                id: IDs.routeEsentaiAlatau,
                name: "Работа -> дом",
                originName: "Esentai / Al-Farabi",
                destinationName: "Alatau City",
                pickupNode: dropoffNodes[0],
                dropoffNode: pickupNodes[0],
                schedule: MockRouteSchedule(
                    weekdays: ["mon", "tue", "wed", "thu"],
                    departureWindowStart: "18:10",
                    departureWindowEnd: "19:00"
                ),
                status: .matching,
                reliabilityPercent: 81
            )
        ]

        public static let plannedRideSegment = MockPlannedRideSegment(
            id: UUID(uuidString: "81000000-0000-0000-0000-000000000001")!,
            routeID: IDs.routeAlatauEsentai,
            pickupNode: pickupNodes[0],
            dropoffNode: dropoffNodes[0],
            departureWindowStart: morningSchedule.departureWindowStart,
            departureWindowEnd: morningSchedule.departureWindowEnd,
            rideDayStatus: .scheduled
        )

        public static let todayCommutePlan = MockTodayCommutePlan(
            id: UUID(uuidString: "82000000-0000-0000-0000-000000000001")!,
            status: .planned,
            dateLabel: "Today",
            nextSegment: plannedRideSegment
        )

        public static let noCommuteTodayPlan = MockTodayCommutePlan(
            id: UUID(uuidString: "82000000-0000-0000-0000-000000000002")!,
            status: .noCommuteToday,
            dateLabel: "Today",
            nextSegment: nil
        )

        public static let insights: [MockPassengerInsight] = [
            MockPassengerInsight(
                id: UUID(uuidString: "83000000-0000-0000-0000-000000000001")!,
                title: "Morning corridor confidence",
                body: "Your active route has stable pickup demand this week."
            )
        ]

        public static let fallbackTaxi = MockFallbackTaxiOption(
            id: UUID(uuidString: "84000000-0000-0000-0000-000000000001")!,
            title: "Fallback taxi",
            subtitle: "Secondary option when commute corridor is unavailable",
            estimatedPickupMinutes: 6
        )

        public static let homeDashboard = MockPassengerHomeDashboard(
            activePlan: activeCommutePlan,
            recurringRoutes: recurringRoutes,
            todayPlan: todayCommutePlan,
            insights: insights,
            fallbackTaxi: fallbackTaxi
        )

        public static let routeStatusDetails: [MockRouteStatus: MockRouteStatusDetail] = [
            .active: MockRouteStatusDetail(
                title: "Route active",
                body: "This recurring commute route is included in the active monthly plan.",
                actionTitle: "Manage route"
            ),
            .paused: MockRouteStatusDetail(
                title: "Route paused",
                body: "This route is paused and will not appear in today's commute plan.",
                actionTitle: "Resume route"
            ),
            .lowDensity: MockRouteStatusDetail(
                title: "Low match",
                body: "Demand is lower than usual for this corridor window.",
                actionTitle: "Adjust schedule"
            ),
            .waitlist: MockRouteStatusDetail(
                title: "Waitlist",
                body: "The route is waiting for enough recurring commuters.",
                actionTitle: "View waitlist",
                waitlistPosition: 3
            ),
            .matching: MockRouteStatusDetail(
                title: "Matching",
                body: "BIRGE is matching this route with nearby recurring commuters.",
                actionTitle: "Review route"
            ),
            .draft: MockRouteStatusDetail(
                title: "Draft",
                body: "This route draft is not active yet.",
                actionTitle: "Continue setup"
            )
        ]

        public static let plans: [MockPassengerPlan] = [
            MockPassengerPlan(
                type: .soloCorridor,
                title: "Solo Corridor",
                monthlyPriceTenge: 39900,
                routeAllowanceDescription: "One declared route and time window",
                isRecommended: false,
                includesPerRidePricing: false,
                features: ["One recurring route", "Fixed pickup and dropoff nodes", "No per-ride friction"]
            ),
            MockPassengerPlan(
                type: .multiCorridor,
                title: "Multi Corridor",
                monthlyPriceTenge: 59900,
                routeAllowanceDescription: "All pre-declared commute routes",
                isRecommended: true,
                includesPerRidePricing: false,
                features: ["Multiple recurring routes", "Recommended for predictable commuters", "No per-ride pricing"]
            ),
            MockPassengerPlan(
                type: .flexPack,
                title: "Flex Pack",
                monthlyPriceTenge: 29900,
                routeAllowanceDescription: "Ride balance for less predictable weeks",
                isRecommended: false,
                includesPerRidePricing: true,
                features: ["Monthly ride balance", "Works across declared routes", "Balance-based deductions"]
            )
        ]

        public static let activeCommutePlan = MockMonthlyCommutePlan(
            id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
            planType: .multiCorridor,
            status: "active",
            coveredRouteIDs: [IDs.routeAlatauEsentai, IDs.routeEsentaiAlatau],
            billingPeriodStart: Date(timeIntervalSince1970: 1_777_593_600),
            billingPeriodEnd: Date(timeIntervalSince1970: 1_780_185_600)
        )

        public static let paymentMethods: [MockPaymentMethod] = [
            MockPaymentMethod(
                id: UUID(uuidString: "70000000-0000-0000-0000-000000000001")!,
                type: .applePay,
                title: "Apple Pay",
                subtitle: "Mock wallet handoff"
            ),
            MockPaymentMethod(
                id: UUID(uuidString: "70000000-0000-0000-0000-000000000002")!,
                type: .kaspi,
                title: "Kaspi",
                subtitle: "Mock checkout only"
            ),
            MockPaymentMethod(
                id: UUID(uuidString: "70000000-0000-0000-0000-000000000003")!,
                type: .savedCard,
                title: "Saved card",
                subtitle: "•••• 4242"
            ),
            MockPaymentMethod(
                id: UUID(uuidString: "70000000-0000-0000-0000-000000000004")!,
                type: .card,
                title: "New card",
                subtitle: "Mock card entry"
            )
        ]

        public static let checkoutSession = MockCheckoutSession(
            id: UUID(uuidString: "71000000-0000-0000-0000-000000000001")!,
            planType: .multiCorridor,
            paymentMethodID: paymentMethods[0].id,
            routeDraftID: draftRoute.id,
            amountTenge: 59900,
            status: "mock_checkout_created"
        )

        public static let billingReceipts: [MockBillingReceipt] = [
            MockBillingReceipt(
                id: UUID(uuidString: "72000000-0000-0000-0000-000000000001")!,
                checkoutID: checkoutSession.id,
                planType: .multiCorridor,
                amountTenge: 59900,
                issuedAt: Date(timeIntervalSince1970: 1_777_593_600),
                status: "mock_paid"
            )
        ]

        public static let rideDayTimelines: [MockRideDayTimeline] = [
            MockRideDayTimeline(
                id: UUID(uuidString: "80000000-0000-0000-0000-000000000001")!,
                routeID: IDs.routeAlatauEsentai,
                status: .driverEnRoute,
                boardingCode: "4821"
            ),
            MockRideDayTimeline(
                id: UUID(uuidString: "80000000-0000-0000-0000-000000000002")!,
                routeID: IDs.routeAlatauEsentai,
                status: .fallbackTaxi,
                boardingCode: nil
            )
        ]

        public static let plannedRideDriver = MockPlannedRideDriver(
            id: UUID(uuidString: "85000000-0000-0000-0000-000000000001")!,
            displayName: "Серик А.",
            rating: 4.9,
            phoneLabel: "Mock call"
        )

        public static let plannedRideVehicle = MockPlannedRideVehicle(
            id: UUID(uuidString: "85000000-0000-0000-0000-000000000002")!,
            make: "Hyundai",
            model: "Accent",
            plateNumber: "777 ABA 02",
            color: "White"
        )

        public static let boardingCode = MockBoardingCode(
            value: "4821",
            refreshesInSeconds: 60
        )

        public static let plannedRideTimeline: [MockRideTimelineItem] = [
            MockRideTimelineItem(
                id: UUID(uuidString: "85000000-0000-0000-0000-000000000010")!,
                title: "Driver assigned",
                detail: "Driver and vehicle are reserved for this planned commute.",
                status: .driverAssigned
            ),
            MockRideTimelineItem(
                id: UUID(uuidString: "85000000-0000-0000-0000-000000000011")!,
                title: "Driver en route",
                detail: "Pickup ETA is tracked against the recurring route window.",
                status: .driverEnRoute
            ),
            MockRideTimelineItem(
                id: UUID(uuidString: "85000000-0000-0000-0000-000000000012")!,
                title: "Boarding",
                detail: "Passenger confirms boarding with the route code.",
                status: .boarding
            )
        ]

        public static let completedCommuteSummary = MockCompletedCommuteSummary(
            title: "Commute completed",
            arrivalText: "Arrived inside the planned window",
            routeSummary: "Alatau City -> Esentai / Al-Farabi"
        )

        public static let rideDayEdgeCases: [PlannedRideStatus: MockRideDayEdgeCase] = [
            .delayed: MockRideDayEdgeCase(
                status: .delayed,
                title: "Driver delayed",
                body: "The planned pickup is running later than the route window.",
                actionTitle: "Contact support"
            ),
            .replacementAssigned: MockRideDayEdgeCase(
                status: .replacementAssigned,
                title: "Replacement assigned",
                body: "A replacement driver has been assigned to keep the commute active.",
                actionTitle: "View driver"
            ),
            .pickupChanged: MockRideDayEdgeCase(
                status: .pickupChanged,
                title: "Pickup node changed",
                body: "The pickup node changed for today's planned commute.",
                actionTitle: "Review pickup"
            ),
            .passengerMissedPickup: MockRideDayEdgeCase(
                status: .passengerMissedPickup,
                title: "Pickup missed",
                body: "The driver could not confirm boarding inside the pickup window.",
                actionTitle: "Report issue"
            ),
            .cancelled: MockRideDayEdgeCase(
                status: .cancelled,
                title: "Commute cancelled",
                body: "Today's planned commute is no longer active.",
                actionTitle: "Get help"
            )
        ]

        public static let plannedCommuteRide = MockPlannedCommuteRide(
            id: plannedRideSegment.id,
            routeID: IDs.routeAlatauEsentai,
            routeName: recurringRoutes[0].name,
            pickupNode: pickupNodes[0],
            dropoffNode: dropoffNodes[0],
            departureWindow: "\(morningSchedule.departureWindowStart)-\(morningSchedule.departureWindowEnd)",
            status: .driverEnRoute,
            driver: plannedRideDriver,
            vehicle: plannedRideVehicle,
            boardingCode: boardingCode,
            etaText: "4 min to pickup",
            timeline: plannedRideTimeline
        )

        public static let supportTickets: [MockSupportTicket] = [
            MockSupportTicket(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000001")!,
                title: "Driver running late",
                routeID: IDs.routeAlatauEsentai,
                plannedRideID: plannedCommuteRide.id,
                driverID: plannedRideDriver.id,
                updatedAtLabel: "Today",
                status: .open
            ),
            MockSupportTicket(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000002")!,
                title: "Subscription route question",
                routeID: IDs.routeEsentaiAlatau,
                plannedRideID: nil,
                driverID: nil,
                updatedAtLabel: "Yesterday",
                status: .waitingForPassenger
            )
        ]

        public static let supportMessages: [MockSupportMessage] = [
            MockSupportMessage(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000011")!,
                ticketID: supportTickets[0].id,
                senderTitle: "BIRGE support",
                body: "We are checking the planned pickup window with the driver.",
                sentAtLabel: "Today"
            ),
            MockSupportMessage(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000012")!,
                ticketID: supportTickets[0].id,
                senderTitle: "Passenger",
                body: "Please keep the route active for this morning.",
                sentAtLabel: "Today"
            )
        ]

        public static let issueCategories: [MockIssueCategory] = [
            MockIssueCategory(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000021")!,
                title: "Driver timing",
                contextHint: "Ride-day timing or arrival issue"
            ),
            MockIssueCategory(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000022")!,
                title: "Pickup node",
                contextHint: "Pickup point or walking access issue"
            ),
            MockIssueCategory(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000023")!,
                title: "Route comfort",
                contextHint: "Vehicle, route, or commute experience"
            )
        ]

        public static let supportContext = MockSupportContext(
            plannedRideID: plannedCommuteRide.id,
            routeID: IDs.routeAlatauEsentai,
            driverID: plannedRideDriver.id,
            subscriptionPlanID: .multiCorridor,
            title: "Today planned commute"
        )

        public static let liveSupportSession = MockLiveSupportSession(
            id: UUID(uuidString: "90000000-0000-0000-0000-000000000031")!,
            context: supportContext,
            title: "Live support",
            status: "mock_active"
        )

        public static let safetyContacts: [MockSafetyContact] = [
            MockSafetyContact(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000041")!,
                name: "Aigerim",
                phoneNumber: "+77770000101",
                relationship: "Family"
            )
        ]

        public static let shareStatusSession = MockShareStatusSession(
            id: UUID(uuidString: "90000000-0000-0000-0000-000000000051")!,
            context: supportContext,
            title: "Share route status",
            statusText: "Driver en route to pickup node",
            expiresAtLabel: "Today"
        )

        public static let authRecords: [MockPassengerAuthRecord] = [
            MockPassengerAuthRecord(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000001")!,
                phoneNumber: Phones.incompletePassenger,
                setupStep: .routeDestination,
                hasCompletedProfile: false,
                hasRecurringRoute: false,
                hasActiveSubscription: false
            ),
            MockPassengerAuthRecord(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000002")!,
                phoneNumber: Phones.completePassengerNoRoute,
                setupStep: nil,
                hasCompletedProfile: true,
                hasRecurringRoute: false,
                hasActiveSubscription: false
            ),
            MockPassengerAuthRecord(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000003")!,
                phoneNumber: Phones.passengerWithRouteNoPlan,
                setupStep: nil,
                hasCompletedProfile: true,
                hasRecurringRoute: true,
                hasActiveSubscription: false
            ),
            MockPassengerAuthRecord(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000004")!,
                phoneNumber: Phones.activePassenger,
                setupStep: nil,
                hasCompletedProfile: true,
                hasRecurringRoute: true,
                hasActiveSubscription: true
            )
        ]
    }

    public enum Driver {
        public static let plans: [MockDriverPlan] = [
            MockDriverPlan(
                type: .peakStarter,
                title: "Peak Starter",
                monthlyPriceTenge: 9900,
                subtitle: "For testing planned morning and evening corridors",
                paymentStartsAfterFirstCorridor: true,
                includesZeroCommission: true,
                features: ["0% commission", "Peak-hour corridor access", "Payment starts after first active corridor"]
            ),
            MockDriverPlan(
                type: .starter,
                title: "Starter",
                monthlyPriceTenge: 19000,
                subtitle: "For first stable corridors",
                paymentStartsAfterFirstCorridor: true,
                includesZeroCommission: true,
                features: ["0% commission", "Standard support", "Planned corridor schedule"]
            ),
            MockDriverPlan(
                type: .professional,
                title: "Professional",
                monthlyPriceTenge: 28000,
                subtitle: "For regular peak-hour work",
                paymentStartsAfterFirstCorridor: true,
                includesZeroCommission: true,
                features: ["0% commission", "Priority corridor matching", "Schedule insights"]
            ),
            MockDriverPlan(
                type: .premium,
                title: "Premium",
                monthlyPriceTenge: 38000,
                subtitle: "For maximum corridor priority and support",
                paymentStartsAfterFirstCorridor: true,
                includesZeroCommission: true,
                features: ["0% commission", "Priority support", "Expanded corridor access"]
            )
        ]

        public static let approvedProfile = MockDriverProfile(
            id: IDs.driverApproved,
            phoneNumber: Phones.activeDriver,
            firstName: "Серик",
            lastName: "А.",
            serviceArea: "Alatau City morning start",
            verificationStatus: .approved
        )

        public static let vehicle = MockVehicleProfile(
            id: UUID(uuidString: "b0000000-0000-0000-0000-000000000001")!,
            make: "Hyundai",
            model: "Accent",
            year: 2014,
            plateNumber: "777 ABA 02",
            seats: 4
        )

        public static let documents: [MockDriverDocument] = [
            MockDriverDocument(
                id: UUID(uuidString: "c0000000-0000-0000-0000-000000000001")!,
                title: "Driver license front",
                status: .approved
            ),
            MockDriverDocument(
                id: UUID(uuidString: "c0000000-0000-0000-0000-000000000002")!,
                title: "Vehicle registration",
                status: .approved
            ),
            MockDriverDocument(
                id: UUID(uuidString: "c0000000-0000-0000-0000-000000000003")!,
                title: "Identity card",
                status: .uploaded
            )
        ]

        public static let corridors: [MockDriverCorridor] = [
            MockDriverCorridor(
                id: IDs.driverCorridorMorning,
                name: "Alatau City -> Esentai",
                pickupNode: "Алатау City, северный вход",
                dropoffNode: "Esentai / Al-Farabi",
                departureWindow: "07:15-08:30",
                passengerCount: 3,
                estimatedEarningsTenge: 7200,
                status: .scheduled
            )
        ]

        public static let earnings = MockDriverEarningsSummary(
            todayTenge: 7200,
            weekTenge: 43600,
            payoutStatus: "mock_pending"
        )

        public static let activeSubscription = MockDriverSubscription(
            planType: .peakStarter,
            status: .active,
            firstCorridorActivatedAt: Date(timeIntervalSince1970: 1_777_593_600)
        )

        public static let authRecords: [MockDriverAuthRecord] = [
            MockDriverAuthRecord(
                id: UUID(uuidString: "d0000000-0000-0000-0000-000000000001")!,
                phoneNumber: Phones.pendingDriver,
                onboardingStep: nil,
                verificationStatus: .pending,
                hasActiveCorridor: false
            ),
            MockDriverAuthRecord(
                id: UUID(uuidString: "d0000000-0000-0000-0000-000000000002")!,
                phoneNumber: Phones.failedDriver,
                onboardingStep: nil,
                verificationStatus: .failed,
                hasActiveCorridor: false
            ),
            MockDriverAuthRecord(
                id: UUID(uuidString: "d0000000-0000-0000-0000-000000000003")!,
                phoneNumber: Phones.approvedDriverNoCorridor,
                onboardingStep: nil,
                verificationStatus: .approved,
                hasActiveCorridor: false
            ),
            MockDriverAuthRecord(
                id: UUID(uuidString: "d0000000-0000-0000-0000-000000000004")!,
                phoneNumber: Phones.activeDriver,
                onboardingStep: nil,
                verificationStatus: .approved,
                hasActiveCorridor: true
            )
        ]
    }
}
