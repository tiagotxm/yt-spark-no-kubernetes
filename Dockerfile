
ARG JRE_VERSION=11-jre-slim-buster

FROM openjdk:${JRE_VERSION} AS base

ARG SPARK_VERSION_DEFAULT=3.5.1
ARG HADOOP_VERSION_DEFAULT=3
ARG HADOOP_AWS_VERSION_DEFAULT=3.2.0
ARG AWS_SDK_BUNDLE_VERSION_DEFAULT=1.11.375

# Define ENV variables
ENV SPARK_VERSION=${SPARK_VERSION_DEFAULT}
ENV HADOOP_VERSION=${HADOOP_VERSION_DEFAULT}
ENV HADOOP_AWS_VERSION=${HADOOP_AWS_VERSION_DEFAULT}
ENV AWS_SDK_BUNDLE_VERSION=${AWS_SDK_BUNDLE_VERSION_DEFAULT}

RUN apt-get update \
    && apt-get install -y curl bash tini libc6 libpam-modules krb5-user libnss3 procps \
    && rm -rf /var/lib/apt/lists/*

FROM base AS spark-base

# Download and extract Spark
RUN curl -L https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -o spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

COPY entrypoint.sh /opt/spark

RUN chmod a+x /opt/spark/entrypoint.sh

FROM spark-base AS sparkbuilder

# Set SPARK_HOME
ENV SPARK_HOME=/opt/spark

# Extend PATH environment variable
ENV PATH=${PATH}:${SPARK_HOME}/bin

# Create the application directory
RUN mkdir -p /app

FROM sparkbuilder AS spark-with-s3

# Download S3 and GCS jars
RUN curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar -o ${SPARK_HOME}/jars/hadoop-aws-${HADOOP_AWS_VERSION}.jar \
    && curl -L https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar -o ${SPARK_HOME}/jars/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar \
    && rm -rf /var/lib/apt/lists/*

FROM spark-with-s3 AS spark-with-python

ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && pip3 install --upgrade pip setuptools \
    # Removed the .cache to save space
    && rm -r /root/.cache \
    && rm -rf /var/cache/apt/* \ 
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ADD requirements.txt .

# Add application files
# ADD . .

# Install application specific python dependencies
# RUN pip3 install -r requirements.txt

USER root

ENTRYPOINT [ "/opt/spark/entrypoint.sh" ]
