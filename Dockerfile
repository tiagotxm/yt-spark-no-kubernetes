# Base image with Spark
FROM tiagotxm/spark:3.5.3-java12-hadoop3

# Define variables
ENV SPARK_HOME=/opt/spark
ENV PATH="$SPARK_HOME/bin:$PATH"
ENV ICEBERG_VERSION=1.7.0

# Add Iceberg JARs
RUN mkdir -p $SPARK_HOME/jars \
    && curl -L -o $SPARK_HOME/jars/iceberg-spark-runtime.jar \
       https://repo1.maven.org/maven2/org/apache/iceberg//iceberg-spark-3.5_2.12/$ICEBERG_VERSION/iceberg-spark-3.5_2.12-$ICEBERG_VERSION.jar

# Set entrypoint
ENTRYPOINT [ "/opt/spark/entrypoint.sh" ]
