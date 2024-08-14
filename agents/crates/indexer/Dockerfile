FROM rust:1.79

WORKDIR /usr/src/indexer

COPY . .

RUN cargo install --path crates/indexer

ENV RUST_LOG=indexer=trace

CMD ["indexer"]
