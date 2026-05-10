FROM rust:1.95-slim-trixie AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release --package river-sidecar

FROM debian:trixie-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/river-sidecar /usr/local/bin/river-sidecar
EXPOSE 4317
CMD ["river-sidecar"]
