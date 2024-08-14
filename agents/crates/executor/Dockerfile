FROM rust:1.79

WORKDIR /usr/src/executor

COPY . .

RUN cargo install --path crates/executor

ENV RUST_LOG=executor=trace

CMD ["executor"]
