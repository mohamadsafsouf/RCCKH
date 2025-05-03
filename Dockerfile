FROM swiftlang/swift:nightly-main-jammy AS builder
WORKDIR /app
COPY . .
RUN swift build -c release
RUN ls -la .build/arm64-apple-macosx/release  # optional debug

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libssl-dev zlib1g-dev && apt-get clean
COPY --from=builder /app/.build/arm64-apple-macosx/release/KeyGeneratorCC /usr/local/bin/Run
CMD ["Run"]
