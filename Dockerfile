FROM swiftlang/swift:nightly-main-jammy AS builder
WORKDIR /app
COPY . .
RUN swift build -c release
RUN find .build -name KeyGeneratorCC  # 👈 shows the correct path in logs

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libssl-dev zlib1g-dev && apt-get clean
COPY --from=builder /app/.build/x86_64-unknown-linux-gnu/release/KeyGeneratorCC /usr/local/bin/Run
CMD ["Run"]
