# Swift build image
FROM swift:5.9-jammy AS builder
WORKDIR /app
COPY . .
RUN swift build -c release

# Runtime image
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libssl-dev zlib1g-dev && apt-get clean
COPY --from=builder /app/.build/release/Run /usr/local/bin/Run
CMD ["Run"]
