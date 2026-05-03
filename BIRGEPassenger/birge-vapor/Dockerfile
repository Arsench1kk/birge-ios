FROM swift:6.0 AS builder

WORKDIR /app
COPY . .
RUN swift build -c release

FROM swift:6.0-slim

WORKDIR /app
COPY --from=builder /app/.build/release/App .

EXPOSE 8080
CMD ["./App", "serve", "--hostname", "0.0.0.0", "--port", "8080"]
