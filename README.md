# BIRGE iOS

[![iOS](https://github.com/Arsench1kk/birge-ios/actions/workflows/ios.yml/badge.svg)](https://github.com/Arsench1kk/birge-ios/actions/workflows/ios.yml)
![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)

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

BIRGE uses a shared-core architecture: Passenger and Driver are separate iOS targets, while common clients, models, persistence, and design-system primitives live in `BIRGECore`.

```text
BIRGEApp
├── README.md
└── BIRGEPassenger
    ├── BIRGEPassenger.xcodeproj
    ├── BIRGEPassenger          Passenger iOS target
    │   ├── App
    │   ├── Features
    │   └── UI
    ├── BIRGEDriver             Driver iOS target
    │   ├── App
    │   ├── Features
    │   └── UI
    ├── BIRGECore               Shared Swift package
    │   └── Sources/BIRGECore
    │       ├── Clients
    │       ├── Database
    │       └── DesignSystem
    └── birge-vapor             Vapor backend
```

| Layer | Responsibility |
|---|---|
| `BIRGEPassenger` | Passenger app shell, OTP auth, home, ride request, active ride, profile |
| `BIRGEDriver` | Driver app shell, online state, offer cards, active trip, earnings |
| `BIRGECore` | Shared dependencies, models, GRDB storage, WebSocket/location clients, design tokens |
| `birge-vapor` | Backend API, authentication, ride lifecycle, real-time events |

The iOS app uses TCA for all state management. Every feature is a `Reducer` with predictable `State -> Action -> Effect` flow. Dependencies such as network, database, WebSocket, and location are injected via `DependencyValues`, making unit tests and SwiftUI previews deterministic.

## Getting Started

### Prerequisites

- Xcode 16
- Swift 6
- Docker
- iPhone 17 Pro simulator, or another iOS 17+ simulator

### Backend Setup

Start PostgreSQL and Redis with Docker, then run the Vapor backend:

```sh
cd BIRGEPassenger/birge-vapor
docker compose up -d postgres redis
swift run
```

If the compose service names differ locally, start the equivalent PostgreSQL and Redis services before running Vapor.

### iOS Setup

Open the Xcode project and run the Passenger or Driver target on an iOS simulator:

```sh
open BIRGEPassenger/BIRGEPassenger.xcodeproj
```

From Xcode:

1. Select `BIRGEPassenger` or `BIRGEDriver`.
2. Select an iPhone 17 Pro simulator.
3. Build and run.

Command-line Passenger verification:

```sh
cd BIRGEPassenger
xcodebuild test \
  -project BIRGEPassenger.xcodeproj \
  -scheme BIRGEPassenger \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Architecture Documentation

Full system design, ADRs, and development decisions:
[birge-architecture](https://github.com/Arsench1kk/birge-architecture)

## Roadmap

| Phase | Status | Focus |
|---|---|---|
| Phase 1 | Done | TCA app foundation, OTP auth, GRDB cache, design system, Passenger/Driver UI shells |
| Phase 2 | Next | WebSocket auth, ride subscriptions, live ride matching, connection recovery |
| Phase 3 | Planned | ML-assisted dispatch, ETA prediction, pricing intelligence, fraud/risk signals |

## Status

Phase 1 — active development baseline is in place.

- [x] GRDB setup with WAL mode + GPS cache
- [x] OTP Authentication (TCA Reducer + Keychain)
- [x] Centralized UI design system
- [x] RideFeature state machine
- [x] MapKit ride visualization
- [ ] Live WebSocket ride matching
- [ ] Real backend profile and ride creation flows
- [ ] Driver background GPS tracking

## Requirements

- iOS 17.0+
- Xcode 16+
- Swift 6
