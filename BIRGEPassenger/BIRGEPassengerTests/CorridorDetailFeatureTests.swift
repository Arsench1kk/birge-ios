import BIRGECore
import ComposableArchitecture
import XCTest
@testable import BIRGEPassenger

@MainActor
final class CorridorDetailFeatureTests: XCTestCase {
    func testJoinStoresBookingAndRefreshesCorridor() async {
        let corridorID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let bookingID = "22222222-2222-2222-2222-222222222222"
        let updatedDTO = CorridorDTO(
            id: corridorID,
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

        let store = TestStore(
            initialState: CorridorDetailFeature.State(corridor: CorridorOption(dto: updatedDTO))
        ) {
            CorridorDetailFeature()
        } withDependencies: {
            $0.apiClient = APIClient(
                bookCorridor: { _ in
                    CorridorBookingResponse(
                        corridor: updatedDTO,
                        message: "Corridor booked",
                        bookingID: bookingID
                    )
                }
            )
        }

        await store.send(.joinTapped) {
            $0.isJoining = true
            $0.errorMessage = nil
        }
        await store.receive(.joinFinished(
            CorridorBookingResponse(
                corridor: updatedDTO,
                message: "Corridor booked",
                bookingID: bookingID
            )
        )) {
            $0.isJoining = false
            $0.isJoined = true
            $0.bookingID = bookingID
            $0.statusMessage = "Место забронировано"
            $0.corridor = CorridorOption(dto: updatedDTO)
        }
        await store.receive(.delegate(.joined))
    }
}
