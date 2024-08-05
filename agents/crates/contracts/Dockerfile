FROM rust:1.79

WORKDIR /usr/src/indexer

COPY . .

RUN cargo install --path crates/indexer

CMD ["indexer"]
