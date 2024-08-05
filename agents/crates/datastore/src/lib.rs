use mongodb::{options::ClientOptions, Client};
use thiserror::Error;



#[derive(Error, Debug)]
pub enum DatastoreError {
    #[error("mongo error: {0}")]
    Mongo(#[from] mongodb::error::Error),
}

pub struct Datastore {
    client: Client,
}

impl Datastore {
    pub async fn init() -> Result<Datastore, DatastoreError> {
        let uri = "mongodb://localhost:27017";
        let options = ClientOptions::parse(uri).await?;
        let client = Client::with_options(options)?;
        Ok(Datastore { client })
    }
}
