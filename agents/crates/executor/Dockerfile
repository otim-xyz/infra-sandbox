FROM rust:1.79

WORKDIR /usr/src/executor

COPY . .

RUN cargo install --path crates/executor

CMD ["executor"]
