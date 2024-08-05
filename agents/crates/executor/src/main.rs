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

    let fibonacci = Fibonacci::new(
        address!("5fbdb2315678afecb367f032d93f642f64180aa3"),
        provider.clone(),
    );

    let handle = tokio::spawn({
        let fibonacci = fibonacci.clone();
        async move {
            loop {
                tokio::time::sleep(Duration::from_secs(2)).await;
                let current_values = fibonacci.getCurrentValues().call().await.unwrap();
                let next_value = current_values._0 + current_values._1;
                if let Ok(Some(state)) = datastore.get_most_recent_state().await {
                    if state.f1 < next_value {
                        let call = fibonacci.setF0F1(current_values._1, next_value);
                        let result = call.send().await;
                        println!("{:?}", result);
                    }
                }
            }
        }
    });

    handle.await?;
    Ok(())
}
