use alloy::{
    network::EthereumWallet, primitives::Address, providers::ProviderBuilder,
    rpc::client::ClientBuilder, signers::local::PrivateKeySigner, transports::http::reqwest::Url,
};
use chrono::Utc;
use contracts::Fibonacci;
use datastore::{Datastore, FibonacciState};
use eyre::Result;
use std::{env, time::Duration};
use tokio::time::sleep;
use tracing::{debug, error};
use tracing_subscriber::{fmt::Layer, prelude::*, EnvFilter};

const OTIM_SYSLOG_IDENTIFIER: &str = "otim-offchain";

#[tokio::main]
async fn main() -> Result<()> {
    #[cfg(target_os = "linux")]
    let journald = tracing_journald::layer()
        .expect("journald subscriber not found")
        .with_syslog_identifier(OTIM_SYSLOG_IDENTIFIER);

    #[cfg(target_os = "linux")]
    tracing_subscriber::registry()
        .with(EnvFilter::from_default_env())
        .with(journald)
        .with(Layer::new())
        .init();

    #[cfg(target_os = "macos")]
    tracing_subscriber::registry()
        .with(EnvFilter::from_default_env())
        .with(Layer::new())
        .init();

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

    debug!("executor started at {}", Utc::now());

    let datastore = Datastore::init(&documentdb_url).await?;

    let rpc_url = Url::parse(&rpc_url)?;
    let rpc_client = ClientBuilder::default().http(rpc_url);
    let provider = ProviderBuilder::new()
        .wallet(EthereumWallet::from(signer))
        .on_client(rpc_client);

    let fibonacci = Fibonacci::new(Address::from_slice(&fibonacci_address), provider.clone());

    loop {
        sleep(Duration::from_secs(poll_interval)).await;

        let most_recent_state = match datastore.get_most_recent_state().await {
            Ok(Some(state)) => state,
            Ok(None) => {
                debug!("no recent state found");
                continue;
            }
            Err(e) => {
                error!("failed to get recent state: {}", e);
                continue;
            }
        };

        let FibonacciState { f0, f1, .. } = most_recent_state;

        let next_value = f0 + f1;

        match fibonacci.setF0F1(f1, next_value).send().await {
            Ok(_) => debug!("updated fibonacci contract {}", next_value),
            Err(e) => {
                error!("failed to update fibonacci contract: {}", e);
            }
        }
    }
}
