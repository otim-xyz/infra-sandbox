use alloy::{
    primitives::Address,
    providers::{Provider, ProviderBuilder},
    rpc::client::ClientBuilder,
    transports::http::reqwest::Url,
};
use chrono::Utc;
use contracts::Fibonacci;
use datastore::{Datastore, FibonacciState};
use eyre::Result;
use std::{env, time::Duration};
use tokio::time::sleep;
use tracing::{debug, error};
#[cfg(target_os = "linux")]
use tracing_subscriber::prelude::*;

#[tokio::main]
async fn main() -> Result<()> {
    #[cfg(target_os = "linux")]
    let syslog_identifier =
        env::var("OTIM_SYSLOG_IDENTIFIER").expect("missing OTIM_SYSLOG_IDENTIFIER");

    let documentdb_url = env::var("OTIM_DOCUMENTDB_URL").expect("missing OTIM_DOCUMENTDB_URL");

    let rpc_url = env::var("OTIM_RPC_URL").expect("missing OTIM_RPC_URL");

    let fibonacci_address =
        hex::decode(env::var("OTIM_FIBONACCI_ADDRESS").expect("missing OTIM_FIBONACCI_ADDRESS"))
            .expect("OTIM_FIBONACCI_ADDRESS bad hex");

    let poll_interval = env::var("OTIM_POLL_INTERVAL")
        .expect("missing OTIM_POLL_INTERVAL")
        .parse::<u64>()
        .expect("OTIM_POLL_INTERVAL bad integer");

    #[cfg(target_os = "linux")]
    let journald = tracing_journald::layer()
        .expect("journald subscriber not found")
        .with_syslog_identifier(syslog_identifier);

    #[cfg(target_os = "linux")]
    tracing_subscriber::registry().with(journald).init();
    #[cfg(target_os = "macos")]
    tracing_subscriber::fmt::init();

    let datastore = Datastore::init(&documentdb_url).await?;

    let rpc_url = Url::parse(&rpc_url)?;
    let rpc_client = ClientBuilder::default().http(rpc_url);
    let provider = ProviderBuilder::new().on_client(rpc_client);

    let fibonacci = Fibonacci::new(Address::from_slice(&fibonacci_address), provider.clone());

    let mut last_block = None;
    loop {
        sleep(Duration::from_secs(poll_interval)).await;

        let current_block = match provider.get_block_number().await {
            Ok(block) => block,
            Err(e) => {
                error!("failed to get block number: {:?}", e);
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
                error!("failed to get current values: {:?}", e);
                continue;
            }
        };

        match datastore
            .add_state(FibonacciState {
                id: None,
                timestamp: Utc::now(),
                address: format!("{}", fibonacci.address()),
                block_number: current_block,
                f0: current_value._0,
                f1: current_value._1,
            })
            .await
        {
            Ok(_) => debug!("stored new state for block {}", current_block),
            Err(e) => {
                error!("failed to store state: {:?}", e);
            }
        }

        last_block = Some(current_block);
    }
}
