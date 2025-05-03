FROM swiftlang/swift:nightly-main-jammy AS builder

WORKDIR /app
COPY . .

# Build the app
RUN swift build -c release

# Find the built binary
RUN find .build -type f -executable -name KeyGeneratorCC -exec cp {} /usr/local/bin/Run \;

FROM ubuntu:22.04

# Install needed libs
RUN apt-get update && apt-get install -y libssl-dev zlib1g-dev && apt-get clean

# Copy built binary from builder
COPY --from=builder /usr/local/bin/Run /usr/local/bin/Run

CMD ["Run"]
