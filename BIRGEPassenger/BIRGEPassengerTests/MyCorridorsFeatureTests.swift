import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class MyCorridorsFeatureTests: XCTestCase {
    func testLoadsBookingsAndSelectsCorridor() async {
        let item = CorridorBookingItemDTO(
            bookingID: "booking-1",
            status: "confirmed",
            corridor: Self.corridor
        )

        let store = TestStore(initialState: MyCorridorsFeature.State()) {
            MyCorridorsFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                fetchCorridorBookings: {
                    CorridorBookingsListResponse(bookings: [item])
                }
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.bookingsLoaded(CorridorBookingsListResponse(bookings: [item]))) {
            $0.isLoading = false
            $0.bookings = [item]
        }
        await store.send(.bookingTapped(item))
        await store.receive(.delegate(.corridorSelected(CorridorOption(dto: Self.corridor))))
    }

    private static let corridor = CorridorDTO(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Алатау → Есентай",
        originName: "Алатау",
        destinationName: "Есентай",
        originLat: 43.2369,
        originLng: 76.8897,
        destinationLat: 43.2187,
        destinationLng: 76.9286,
        departure: "07:30 утром",
        timeOfDay: "morning",
        seatsLeft: 0,
        seatsTotal: 4,
        price: 890,
        matchPercent: 98,
        passengerInitials: ["А", "М", "Д", "Вы"]
    )
}
