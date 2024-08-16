use alloy::{
    network::EthereumWallet,
    primitives::Address,
    providers::{Provider, ProviderBuilder},
    rpc::client::ClientBuilder,
    signers::local::PrivateKeySigner,
    transports::http::reqwest::Url,
};
use chrono::Utc;
use contracts::Fibonacci;
use datastore::{Datastore, FibonacciState};
use eyre::Result;
use std::{env, time::Duration};
use tokio::time::sleep;
use tracing::{debug, error};
use tracing_subscriber::{fmt::Layer, prelude::*, EnvFilter};

#[tokio::main]
async fn main() -> Result<()> {
    let loki_url = Url::parse(&env::var("OTIM_LOKI_URL").expect("missing OTIM_LOKI_URL"))
        .expect("unable to parse OTIM_LOKI_URL");

    let (loki_layer, loki_task) = tracing_loki::builder()
        .label("host", "executor")
        .expect("tracing_loki unallowed label")
        .build_url(loki_url)
        .expect("unable to build tracing_loki");

    tracing_subscriber::registry()
        .with(EnvFilter::from_default_env())
        .with(loki_layer)
        .with(Layer::new())
        .init();

    _ = tokio::spawn(loki_task);

    let documentdb_url = env::var("OTIM_DOCUMENTDB_URL").expect("missing OTIM_DOCUMENTDB_URL");

    let rpc_url = env::var("OTIM_RPC_URL").expect("missing OTIM_RPC_URL");

    let fibonacci_address =
        hex::decode(env::var("OTIM_FIBONACCI_ADDRESS").expect("missing OTIM_FIBONACCI_ADDRESS"))
            .expect("OTIM_FIBONACCI_ADDRESS bad hex");

    let poll_interval = env::var("OTIM_POLL_INTERVAL")
        .expect("missing OTIM_POLL_INTERVAL")
        .parse::<u64>()
        .expect("OTIM_POLL_INTERVAL bad integer");

    let signer: PrivateKeySigner = env::var("OTIM_EXECUTOR_SIGNER_KEY")
        .expect("missing OTIM_EXECUTOR_SIGNER_KEY")
        .parse()
        .expect("unable to parse OTIM_EXECUTOR_SIGNER_KEY");

    let datastore = Datastore::init(&documentdb_url).await?;

    let rpc_url = Url::parse(&rpc_url)?;
    let rpc_client = ClientBuilder::default().http(rpc_url);
    let provider = ProviderBuilder::new()
        .with_recommended_fillers()
        .wallet(EthereumWallet::from(signer))
        .on_client(rpc_client);

    let fibonacci = Fibonacci::new(Address::from_slice(&fibonacci_address), provider.clone());

    let mut last_block = None;

    debug!("executor started at {}", Utc::now());

    loop {
        sleep(Duration::from_secs(poll_interval)).await;

        let current_block = match provider.get_block_number().await {
            Ok(block) => block,
            Err(e) => {
                error!("failed to get block number: {}", e);
                continue;
            }
        };

        if last_block == Some(current_block) {
            continue;
        }

        let current_value = match fibonacci
            .getCurrentValues()
            .block(current_block.into())
            .call()
            .await
        {
            Ok(values) => values,
            Err(e) => {
                error!("failed to get current values: {}", e);
                continue;
            }
        };

        let f0 = current_value._0;
        let f1 = current_value._1;

        let next_value = f0 + f1;

        match fibonacci.setF0F1(f1, next_value).send().await {
            Ok(_) => debug!("updated fibonacci contract {}", next_value),
            Err(e) => {
                error!("failed to update fibonacci contract: {}", e);
                continue;
            }
        }

        // TODO: how do we deal with a failure here *after* the tx has succeeded?
        match datastore
            .add_state(FibonacciState {
                id: None,
                timestamp: Utc::now(),
                address: format!("{}", fibonacci.address()),
                block_number: current_block,
                f0: f1,
                f1: next_value,
            })
            .await
        {
            Ok(_) => debug!("stored new state for block {}", current_block),
            Err(e) => {
                error!("failed to store state: {}", e);
            }
        }

        last_block = Some(current_block);
    }
}
