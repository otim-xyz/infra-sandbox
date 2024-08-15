FROM rust:1.79

WORKDIR /usr/src/indexer

COPY . .

RUN cargo install --path crates/indexer

ENTRYPOINT RUST_LOG=indexer=trace indexer
