from pyspark.sql import SparkSession
from pyspark.sql.types import DoubleType, FloatType, LongType, StructType, StructField, StringType
import os

def create_spark_session():
    """Create and configure the Spark session."""
    warehouse_path = os.getenv("WAREHOUSE_PATH", "s3a://yt-lakehouse/warehouse")
    
    spark = (
        SparkSession.builder
        .appName("IcebergSparkSession")
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkSessionCatalog")
        .config("spark.sql.catalog.spark_catalog.type", "hive")
        .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.local.type", "hadoop")
        .config("spark.sql.catalog.local.warehouse", warehouse_path)
        .config("spark.sql.defaultCatalog", "local")
        .getOrCreate()
    )
    return spark

def main():
    # Initialize Spark session
    spark = create_spark_session()
    
    # Define schema
    schema = StructType([
        StructField("vendor_id", LongType(), True),
        StructField("trip_id", LongType(), True),
        StructField("trip_distance", FloatType(), True),
        StructField("fare_amount", DoubleType(), True),
        StructField("store_and_fwd_flag", StringType(), True)
    ])
    
    # Create an empty DataFrame with the schema
    df = spark.createDataFrame([], schema)
    df.write.format("iceberg").mode("overwrite").save("demo.nyc.taxis")
    
    # Define sample data
    data = [
        (1, 1000371, 1.8, 15.32, "N"),
        (2, 1000372, 2.5, 22.15, "N"),
        (2, 1000373, 0.9, 9.01, "N"),
        (1, 1000374, 8.4, 42.13, "Y")
    ]
    
    # Append data to the Iceberg table
    schema = spark.table("demo.nyc.taxis").schema
    df = spark.createDataFrame(data, schema)
    df.writeTo("demo.nyc.taxis").append()
    
    # Show the data
    spark.table("demo.nyc.taxis").show()

if __name__ == "__main__":
    main()
