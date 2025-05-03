# ================================
# Build image
# ================================
FROM swift:6.0-noble AS build

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev

WORKDIR /build

COPY ./Package.* ./
RUN swift package resolve \
    $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

COPY . .

# 🧱 Build the executable
RUN swift build -c release \
    --product KeyGeneratorCC \
    --static-swift-stdlib \
    -Xlinker -ljemalloc

WORKDIR /staging

# ✅ Copy built binary
RUN cp "$(swift build -c release --show-bin-path)/KeyGeneratorCC" ./KeyGeneratorCC

# 🔁 Optional: backtrace tool
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./ || true

# Optional: Resource bundles
RUN find -L "$(swift build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

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

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app
COPY --from=build --chown=vapor:vapor /staging /app

ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./KeyGeneratorCC"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
