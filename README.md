# BIRGE iOS

Native iOS application for BIRGE — a ride-hailing platform for Almaty, Kazakhstan.

## Tech Stack

| Component | Technology |
|---|---|
| UI Framework | SwiftUI |
| State Management | [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture) |
| Local Database | [GRDB](https://github.com/groue/GRDB.swift) with WAL mode |
| Real-time | WebSocket (`URLSessionWebSocketTask`) |
| Authentication | OTP + JWT (Keychain storage) |
| Location | `CLLocationManager` + `BGProcessingTask` |

## Architecture

The app uses TCA for all state management. Every feature is a `Reducer` with predictable
`State → Action → Effect` flow. Dependencies (network, database, location) are injected
via `DependencyValues` — fully mockable for unit tests and SwiftUI Previews.


BIRGEApp/ 
├── BIRGEPassenger/     # Passenger app target 
│   └── Features/ 
│       ├── Auth/       # OTP authentication 
│       ├── Home/       # Main screen 
│       └── Ride/       # Active ride with real-time tracking 
├── BIRGEDriver/        # Driver app target 
└── BIRGECore/          # Shared Swift Package 
    └── Sources/ 
        ├── Clients/    # TCA Dependencies (WebSocket, Location, Auth) 
        └── Database/   # GRDB models and repositories

## Architecture Documentation

Full system design, ADRs, and development decisions:
[birge-architecture](https://github.com/Arsench1kk/birge-architecture)

## Status

🏗️ Phase 1 — Active development

- [x] GRDB setup with WAL mode + GPS cache
- [x] OTP Authentication (TCA Reducer + Keychain)
- [ ] WebSocketClient TCA Dependency
- [ ] RideFeature state machine (7 states)
- [ ] Real-time driver location on MapKit

## Requirements

- iOS 17.0+
- Xcode 16+
- Swift 6
