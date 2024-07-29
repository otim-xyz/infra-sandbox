FROM ghcr.io/foundry-rs/foundry

WORKDIR /app

COPY . .

RUN forge build
RUN forge test

ENTRYPOINT ["forge", "create"]
