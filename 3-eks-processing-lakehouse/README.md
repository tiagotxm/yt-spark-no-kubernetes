# Criar a infraestrutura

1. ```terraform init```
2. ```terraform plan```
3. ```terraform apply```
4. ```
   aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
   ```

# Instalar Spark Operator
1. ``` kubectl create namespace spark-jobs ```
 
2. ``` helm install spark-operator -f values.yaml spark-operator/spark-operator --namespace spark-operator --create-namespace```
