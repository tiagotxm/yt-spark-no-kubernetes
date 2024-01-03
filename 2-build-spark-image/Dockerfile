FROM tiagotxm/spark:v3.5

ADD https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.0.0/delta-spark_2.12-3.0.0.jar /opt/spark/jars
ADD https://repo1.maven.org/maven2/io/delta/delta-storage/3.0.0/delta-storage-3.0.0.jar /opt/spark/jars

USER root

RUN chown -R 185:185 /opt/spark/jars

USER 185