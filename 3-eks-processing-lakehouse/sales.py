from pyspark.sql import SparkSession
from pyspark.sql.functions import sum
from pyspark.sql.types import StructType, StructField, IntegerType, StringType

if __name__ == '__main__':
    spark = SparkSession.builder.appName("sales-lakehouse").getOrCreate()

    sales_data_path = "s3a://yt-lakehouse/data/sales.json"
    product_data_path = "s3a://yt-lakehouse/data/products.json"
    output_delta_path = "s3a://yt-lakehouse/raw/sales_and_revenue"

    sales_schema = StructType([
        StructField("store", StringType(), True),
        StructField("product_id", IntegerType(), True),
        StructField("date", StringType(), True),
        StructField("sales", IntegerType(), True)
    ])

    products_schema = StructType([
        StructField("product_id", IntegerType(), True),
        StructField("name", StringType(), True),
        StructField("price", IntegerType(), True)
    ])

    sales_data = spark.read.json(sales_data_path, schema=sales_schema)
    product_data = spark.read.json(product_data_path, schema=products_schema)

    sales_data.show()
    product_data.show()

    total_sales_revenue = (
        sales_data
        .join(product_data, "product_id")
        .withColumn("revenue", sales_data["sales"] * product_data["price"])
        .groupBy("store", "product_id", "name")
        .agg(sum("sales").alias("total_sales"), sum("revenue").alias("total_revenue"))
    )

    total_sales_revenue.write.format("delta").mode("overwrite").save(output_delta_path)

    read_back = spark.read.format("delta").load(output_delta_path)

    read_back.show()

    spark.stop()
