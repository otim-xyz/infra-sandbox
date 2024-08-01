FROM ghcr.io/foundry-rs/foundry:nightly

WORKDIR /app

COPY . .

RUN forge build
RUN forge test

ENV PRIVATE_KEY="0x8f05cfc48e9b5a1f36dc8fc535e40009e5ae9598753e02513bfd08e60882bd28"
ENV RPC_URL="http://anvil:8545"

ENTRYPOINT forge script script/Counter.s.sol \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL" \
  --broadcast
