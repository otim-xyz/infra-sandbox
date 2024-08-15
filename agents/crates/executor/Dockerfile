FROM rust:1.79

WORKDIR /usr/src/executor

COPY . .

RUN cargo install --path crates/executor

ENTRYPOINT RUST_LOG=executor=trace executor 2>&1 >/dev/null
