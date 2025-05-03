# ================================
# Build image
# ================================
FROM swift:6.0-noble AS build

# Install OS updates
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev

# Set up a build area
WORKDIR /build

# Copy dependency resolution files and resolve dependencies
COPY ./Package.* ./
RUN swift package resolve \
    $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# Copy rest of project
COPY . .

# Build your app in release mode (no --product)
RUN swift build -c release \
    --static-swift-stdlib \
    -Xlinker -ljemalloc

# Switch to staging area
WORKDIR /staging

# Copy the resulting executable (we detect the bin path)
RUN cp "$(swift build --package-path /build -c release --show-bin-path)"/Run ./

# Copy static swift backtracer binary
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

# Copy resource bundles if any
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

# Optional: Public or Resources folders
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Run image
# ================================
FROM ubuntu:noble

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
        libjemalloc2 \
        ca-certificates \
        tzdata \
    && rm -r /var/lib/apt/lists/*

# Create non-root user
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app
COPY --from=build --chown=vapor:vapor /staging /app

ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
