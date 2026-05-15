"""
E-Commerce Data Loader
Loads raw data from various sources into Snowflake bronze layer
"""

import os
import logging
from datetime import datetime
from typing import Optional

import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SnowflakeLoader:
    """Handles data loading to Snowflake"""
    
    def __init__(self):
        self.connection = None
        self._connect()
    
    def _connect(self):
        """Establish connection to Snowflake"""
        try:
            self.connection = snowflake.connector.connect(
                account=os.getenv('SNOWFLAKE_ACCOUNT'),
                user=os.getenv('SNOWFLAKE_USER'),
                password=os.getenv('SNOWFLAKE_PASSWORD'),
                warehouse=os.getenv('SNOWFLAKE_WAREHOUSE', 'COMPUTE_WH'),
                database=os.getenv('SNOWFLAKE_DATABASE', 'ECOMMERCE'),
                schema=os.getenv('SNOWFLAKE_SCHEMA', 'RAW'),
                role=os.getenv('SNOWFLAKE_ROLE', 'TRANSFORM')
            )
            logger.info("Successfully connected to Snowflake")
        except Exception as e:
            logger.error(f"Failed to connect to Snowflake: {e}")
            raise
    
    def load_dataframe(
        self,
        df: pd.DataFrame,
        table_name: str,
        mode: str = 'append'
    ) -> int:
        """
        Load a pandas DataFrame to Snowflake
        
        Args:
            df: DataFrame to load
            table_name: Target table name
            mode: 'append' or 'overwrite'
        
        Returns:
            Number of rows loaded
        """
        if df.empty:
            logger.warning(f"Empty DataFrame, skipping load to {table_name}")
            return 0
        
        # Add metadata columns
        df['_loaded_at'] = datetime.utcnow()
        df['_source_file'] = 'api_extract'
        
        # Normalize column names for Snowflake
        df.columns = [col.upper().replace(' ', '_') for col in df.columns]
        
        try:
            if mode == 'overwrite':
                cursor = self.connection.cursor()
                cursor.execute(f"TRUNCATE TABLE IF EXISTS {table_name}")
                cursor.close()
            
            success, nchunks, nrows, _ = write_pandas(
                self.connection,
                df,
                table_name,
                auto_create_table=True,
                overwrite=(mode == 'overwrite')
            )
            
            if success:
                logger.info(f"Loaded {nrows} rows to {table_name}")
                return nrows
            else:
                logger.error(f"Failed to load data to {table_name}")
                return 0
                
        except Exception as e:
            logger.error(f"Error loading to {table_name}: {e}")
            raise
    
    def execute_query(self, query: str) -> Optional[pd.DataFrame]:
        """Execute a query and return results as DataFrame"""
        try:
            cursor = self.connection.cursor()
            cursor.execute(query)
            
            if cursor.description:
                columns = [col[0] for col in cursor.description]
                data = cursor.fetchall()
                return pd.DataFrame(data, columns=columns)
            
            return None
            
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            raise
        finally:
            cursor.close()
    
    def close(self):
        """Close the Snowflake connection"""
        if self.connection:
            self.connection.close()
            logger.info("Snowflake connection closed")


def load_csv_files(loader: SnowflakeLoader, data_dir: str):
    """Load all CSV files from data directory"""
    
    tables = {
        'orders.csv':      'ORDERS',
        'order_items.csv': 'ORDER_ITEMS',
        'customers.csv':   'CUSTOMERS',
        'products.csv':    'PRODUCTS',
        'payments.csv':    'PAYMENTS',
        'inventory.csv':   'INVENTORY',
    }
    
    for filename, table_name in tables.items():
        filepath = os.path.join(data_dir, filename)
        
        if os.path.exists(filepath):
            logger.info(f"Loading {filename} to {table_name}")
            df = pd.read_csv(filepath)
            loader.load_dataframe(df, table_name)
        else:
            logger.warning(f"File not found: {filepath}")


def main():
    """Main entry point"""
    loader = SnowflakeLoader()
    
    try:
        # Load sample data (point at data/sample to use the synthetic fixtures,
        # or data/ for the smaller demo CSVs).
        data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'sample')
        if not os.path.isdir(data_dir):
            data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
        load_csv_files(loader, data_dir)
        
        logger.info("Data loading completed successfully")
        
    except Exception as e:
        logger.error(f"Data loading failed: {e}")
        raise
    finally:
        loader.close()


if __name__ == '__main__':
    main()
