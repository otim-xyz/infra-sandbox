use alloy::{
    primitives::address,
    providers::{Provider, ProviderBuilder},
    rpc::client::ClientBuilder,
    sol,
    transports::http::reqwest::Url,
};
use chrono::Utc;
use contracts::Fibonacci;
use datastore::{Datastore, FibonacciState};
use eyre::Result;
use futures_util::StreamExt;
use std::{future::IntoFuture, time::Duration};

#[tokio::main]
async fn main() -> Result<()> {
    let datastore = Datastore::init().await?;

    let rpc_url = Url::parse("http://localhost:8545")?;
    let rpc_client = ClientBuilder::default()
        .http(rpc_url)
        .with_poll_interval(Duration::from_secs(3));
    let provider = ProviderBuilder::new().on_client(rpc_client);

    // let block_watch = provider.watch_blocks().await?;
    // let mut block_stream = block_watch.into_stream();

    // let handle0 = tokio::spawn(async move {
    //     while let Some(block) = block_stream.next().await {
    //         println!("Block: {:?}", block);
    //     }
    // });

    let fibonacci = Fibonacci::new(
        address!("5fbdb2315678afecb367f032d93f642f64180aa3"),
        provider.clone(),
    );

    // let number_f0_set_filter = fibonacci.NumberF0Set_filter().watch().await?;
    // let number_f1_set_filter = fibonacci.NumberF1Set_filter().watch().await?;

    // let mut number_f0_set_stream = number_f0_set_filter.into_stream();
    // let mut number_f1_set_stream = number_f1_set_filter.into_stream();

    // let handle0 = tokio::spawn(async move {
    //     while let Some(Ok((event, _log))) = number_f0_set_stream.next().await {
    //         println!("NumberF0Set: {:?}", event);
    //         println!("log: {:?}", _log);
    //     }
    // });

    // let handle1 = tokio::spawn(async move {
    //     while let Some(Ok((event, _log))) = number_f1_set_stream.next().await {
    //         println!("NumberF1Set: {:?}", event);
    //         println!("log: {:?}", _log);
    //     }
    // });

    let mut last_block = None;

    let handle2 = tokio::spawn({
        let fibonacci = fibonacci.clone();
        async move {
            loop {
                tokio::time::sleep(Duration::from_secs(2)).await;
                let current_block = provider.get_block_number().await.unwrap();
                if last_block == Some(current_block) {
                    continue;
                }
                let current_value = fibonacci
                    .getCurrentValues()
                    .block(current_block.into())
                    .call()
                    .await
                    .unwrap();
                let result = datastore
                    .add_state(FibonacciState {
                        id: None,
                        timestamp: Utc::now(),
                        address: format!("{}", fibonacci.address()),
                        block_number: current_block,
                        f0: current_value._0,
                        f1: current_value._1,
                    })
                    .await;
                last_block = Some(current_block);
                println!("{:?}", result);
            }
        }
    });

    let current_values = fibonacci.getCurrentValues().call().await?;
    let next_val = current_values._0 + current_values._1;
    let _ = fibonacci
        .setF0F1(current_values._1, next_val)
        .send()
        .await?;

    // handle0.await?;
    // handle1.await?;
    handle2.await?;
    Ok(())
}

/*
tokio = { version = "1.39.2", features = ["full"] }
tracing = "0.1"
tracing-subscriber = "0.3.0"
tracing-journald = "0.3.0"

use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;
use tracing::info;
use tracing_subscriber::prelude::*;

#[tokio::main]
async fn main() {
    let journald = tracing_journald::layer()
        .expect("journald subscriber")
        .with_syslog_identifier("otim-offchain".to_owned());

    tracing_subscriber::registry().with(journald).init();

    let count = Arc::new(Mutex::new(0u32));

    let handle = tokio::spawn(async move {
        loop {
            increment(count.clone()).await;
        }
    });

    handle.await.unwrap();
}

#[tracing::instrument(skip_all)]
async fn increment(count: Arc<Mutex<u32>>) {
    let mut count = count.lock().await;
    info!(count = %*count, "incremented count {}", *count);
    *count += 1;
    tokio::time::sleep(Duration::from_secs(2)).await;
}

# install vector

# from(bucket: "tracing")
#   |> range(start: -10m)
#   |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
#   |> drop(columns: ["_measurement", "metric_type", "source_type", "syslog_identifier"])
#   |> sort(columns: ["_time"], desc: true)
*/
