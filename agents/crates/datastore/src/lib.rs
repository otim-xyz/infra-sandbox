use alloy::primitives::U256;
use bson::{doc, oid::ObjectId};
use chrono::{DateTime, Utc};
use mongodb::{
    options::{ClientOptions, IndexOptions},
    Client, Collection, IndexModel,
};
use serde::{Deserialize, Serialize};
use thiserror::Error;

const DATABASE_NAME: &str = "indexed-data";
const DATABASE_TABLE: &str = "fibonacci-state";

#[derive(Debug, Serialize, Deserialize)]
pub struct FibonacciState {
    #[serde(rename = "_id", skip_serializing_if = "Option::is_none")]
    pub id: Option<ObjectId>,
    #[serde(with = "bson::serde_helpers::chrono_datetime_as_bson_datetime")]
    pub timestamp: DateTime<Utc>,
    pub address: String,
    pub block_number: u64,
    pub f0: U256,
    pub f1: U256,
}

#[derive(Error, Debug)]
pub enum DatastoreError {
    #[error("mongo error: {0}")]
    Mongo(#[from] mongodb::error::Error),
}

pub struct Datastore {
    client: Client,
}

impl Datastore {
    #[tracing::instrument(skip_all)]
    pub async fn init(uri: &str) -> Result<Self, DatastoreError> {
        let options = ClientOptions::parse(uri).await?;
        let client = Client::with_options(options)?;
        let db = client.database(DATABASE_NAME);
        let collection: Collection<FibonacciState> = db.collection(DATABASE_TABLE);
        let index_model = IndexModel::builder()
            .keys(doc! { "address": 1, "block_number": 1 })
            .options(IndexOptions::builder().unique(true).build())
            .build();
        collection.create_index(index_model).await?;
        Ok(Self { client })
    }

    #[tracing::instrument(skip_all)]
    pub async fn add_state(&self, state: FibonacciState) -> Result<(), DatastoreError> {
        let db = self.client.database(DATABASE_NAME);
        let collection = db.collection(DATABASE_TABLE);
        collection.insert_one(state).await?;
        Ok(())
    }

    #[tracing::instrument(skip_all)]
    pub async fn get_most_recent_state(&self) -> Result<Option<FibonacciState>, DatastoreError> {
        let db = self.client.database(DATABASE_NAME);
        let collection = db.collection(DATABASE_TABLE);
        let state = collection
            .find_one(doc! {})
            .sort(doc! { "block_number": -1 })
            .await?;
        Ok(state)
    }
}
