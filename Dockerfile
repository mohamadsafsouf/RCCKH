# Use Swift 6.0-compatible image
FROM swiftlang/swift:nightly-main-jammy AS builder
WORKDIR /app
COPY . .
RUN swift build -c release

# Runtime container
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libssl-dev zlib1g-dev && apt-get clean
COPY --from=builder /app/.build/release/KeyGeneratorCC /usr/local/bin/Run
CMD ["Run"]
