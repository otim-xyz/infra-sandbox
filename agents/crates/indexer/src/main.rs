use std::time::Duration;

use alloy::{
    primitives::address,
    providers::ProviderBuilder,
    rpc::{client::ClientBuilder, types::serde_helpers::num},
    sol,
    transports::http::reqwest::Url,
};
use eyre::Result;
use futures_util::StreamExt;

sol! {
    #[sol(rpc)]
    interface Fibonacci {
        #[derive(Debug)]
        event NumberF0Set(uint256 f0, uint256 newF0);
        #[derive(Debug)]
        event NumberF1Set(uint256 f1, uint256 newF1);

        #[derive(Debug)]
        error F0NotEqualToF1(uint256 f0, uint256 newF0, uint256 f1);
        #[derive(Debug)]
        error F1NotFibonacci(uint256 f0, uint256 f1, uint256 newF1);

        #[derive(Debug)]
        uint256 public f0 = 0;
        #[derive(Debug)]
        uint256 public f1 = 1;

        function setF0F1(uint256 newF0, uint256 newF1) public;
        function getCurrentValue() public view returns (uint256);
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let rpc_url = Url::parse("http://localhost:8545")?;
    let rpc_client = ClientBuilder::default()
        .http(rpc_url)
        .with_poll_interval(Duration::from_secs(3));
    let provider = ProviderBuilder::new().on_client(rpc_client);

    let fibonacci = Fibonacci::new(
        address!("5fbdb2315678afecb367f032d93f642f64180aa3"),
        provider,
    );

    let number_f0_set_filter = fibonacci.NumberF0Set_filter().watch().await?;
    let number_f1_set_filter = fibonacci.NumberF1Set_filter().watch().await?;

    let mut number_f0_set_stream = number_f0_set_filter.into_stream();
    let mut number_f1_set_stream = number_f1_set_filter.into_stream();

    let handle0 = tokio::spawn(async move {
        while let Some(Ok((event, _log))) = number_f0_set_stream.next().await {
            println!("NumberF0Set: {:?}", event);
            println!("log: {:?}", _log);
        }
    });

    let handle1 = tokio::spawn(async move {
        while let Some(Ok((event, _log))) = number_f1_set_stream.next().await {
            println!("NumberF1Set: {:?}", event);
            println!("log: {:?}", _log);
        }
    });

    let f0_response = fibonacci.f0().call().await?;
    let f1_response = fibonacci.f1().call().await?;

    let next_val = f0_response.f0 + f1_response.f1;
    let _ = fibonacci.setF0F1(f1_response.f1, next_val).send().await?;

    handle0.await?;
    handle1.await?;
    Ok(())
}
