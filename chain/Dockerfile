FROM ghcr.io/foundry-rs/foundry:nightly

WORKDIR /app

ENV MNEMONIC="test test test test test test test test test test test tell"
ENV HOST="0.0.0.0"
ENV PORT="8545"
ENV HARDFORK="prague"
ENV BLOCK_TIME="5"

ENTRYPOINT anvil \
  --block-time "$BLOCK_TIME" \
  --hardfork "$HARDFORK" \
  --host "$HOST" \
  --port "$PORT" \
  --mnemonic "$MNEMONIC"
