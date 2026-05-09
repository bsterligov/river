FROM rust:1.95-slim-trixie AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
COPY infra/migrations ./infra/migrations
RUN cargo build --release --package ingestion

FROM debian:trixie-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/ingestion /usr/local/bin/ingestion
CMD ["ingestion"]
