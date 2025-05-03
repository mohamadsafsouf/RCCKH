# ================================
# Build image
# ================================
FROM swift:6.0-noble AS build

# Install jemalloc (optional but good for performance)
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev

WORKDIR /build

# Cache dependencies
COPY ./Package.* ./
RUN swift package resolve $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# Copy entire project and build the executable
COPY . .
RUN swift build -c release \
    --product KeyGeneratorCC \
    --static-swift-stdlib \
    -Xlinker -ljemalloc

# Stage binaries and resources
WORKDIR /staging
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/KeyGeneratorCC" ./Run
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./ || true
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Runtime image
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

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor
WORKDIR /app

COPY --from=build --chown=vapor:vapor /staging /app

ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

USER vapor:vapor
EXPOSE 8080

ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
