# 🚀 Kubeflow Spark Operator - Tutorial Completo  

Este repositório contém um tutorial atualizado sobre o **Kubeflow Spark Operator**, abordando desde conceitos fundamentais até um *hands-on* completo.  

## 🎯 Motivação  

O **Spark Operator** foi recentemente migrado para a comunidade do **Kubeflow**, e algumas mudanças ocorreram no projeto. Este tutorial tem como objetivo trazer conteúdos atualizados sobre essa nova fase do operador, permitindo que você aproveite ao máximo essa integração com o Kubernetes.  

## 📌 O que será abordado?  

Este tutorial será dividido nos seguintes tópicos:  

1. **Revisar a arquitetura do Spark**  
2. **Introdução ao Kubeflow Spark Operator**  
3. **Hands-on de um ambiente local**  
4. **Criar uma imagem do Spark customizada com Iceberg**  
5. **Deploy de um EKS com autoscaling na AWS (Terraform + Karpenter)**  
6. **Instalação e utilização do ArgoCD para deploy do Spark Operator no EKS**  
7. **Executar um job PySpark com Iceberg integrado ao S3**  
8. **Boas práticas de redução de custo**  
    - Instâncias *spot* e *on-demand*  
    - *Node-affinity* e *pod-affinity*  

---

## 📌 Arquitetura do Apache Spark  

Vamos recapitular brevemente a arquitetura do Apache Spark em alto nível.  

![Arquitetura do Apache Spark](<caminho_para_a_imagem>)  

No Spark, temos três componentes principais:  

- **Driver**: Gerencia a execução do aplicativo Spark, comunicando com o *Cluster Manager*, requisitando CPU e Memória, distribui, monitora e agenda tarefas nos *Executors*.
- **Executors**: São processos que executam tarefas do aplicativo Spark. Eles são responsáveis por executar o código do usuário, armazenar dados em memória ou disco e retornar resultados ao *Driver*. São alocados nos *Workers*.
- **Cluster Manager**: Coordena a alocação de recursos, como CPU e memória em um cluster. Atualmente, o Spark suporta *Standalone*, *Mesos*, *YARN* e *Kubernetes*.

---

## 🚀 Vantagens do Spark no Kubernetes  

O **Kubernetes** é um orquestrador de containers amplamente utilizado, e sua adoção no ecossistema de Big Data vem crescendo devido às suas vantagens:  

1. **Escalabilidade e gerenciamento automatizado**  
   - O Kubernetes trabalha de maneira declarativa, garantindo que os recursos necessários sejam provisionados automaticamente.  

2. **Ambiente unificado**  
   - Permite que times de software e dados compartilhem a mesma infraestrutura.  

3. **Customização avançada**  
   - Suporte para diferentes tipos de máquinas, *node pools*, *affinity rules*, entre outras configurações.  

4. **Agnóstico a provedores de nuvem**  
   - Funciona tanto em ambientes gerenciados (*EKS*, *GKE*, *AKS*) quanto em clusters *on-premise*.  

5. **Integração com ferramentas do ecossistema Kubernetes**  
   - Observabilidade, monitoramento, *service mesh*, CI/CD, entre outras.  

---

## 📌 Introdução ao Kubeflow Spark Operator  

Agora que revisamos a arquitetura do Spark, vamos entender como funciona o **Kubeflow Spark Operator**.  

📌 **Importante**: Do ponto de vista do código Spark (PySpark, Spark SQL, Streaming, etc.), nada muda. A diferença está na forma como declaramos e submetemos os *jobs* no Kubernetes.  

O Kubernetes trabalha com arquivos YAML declarativos, e o **Spark Operator** segue essa mesma abordagem. Para rodar um job Spark, precisamos de um manifesto YAML que descreve a execução.  

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: spark-pi
  namespace: default
spec:
  type: Python
  mode: cluster
  image: "tiagotxm/spark:3.5.3-demo-yt"
  imagePullPolicy: Always
  mainApplicationFile: "local:///opt/spark/examples/src/main/python/pi.py"
  sparkVersion: "3.5.3"
  restartPolicy:
    type: Never
  driver:
    cores: 1
    coreLimit: "1200m"
    memory: "512m"
    labels:
      version: 3.5.3
    serviceAccount: spark-operator-spark
  executor:
    cores: 1
    instances: 1
    memory: "512m"
    labels:
      version: 3.5.3

```

## 🛠 Hands-on: Ambiente Local

### 🔹 Passo 1: Instalar o Kind
- https://kind.sigs.k8s.io/


### 🔹 Passo 2: Criar um Cluster Kubernetes
```
kind create cluster --config infra/local/kind.yaml
```

### 🔹 Passo 3: Instalar o Spark Operator
```
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

# Install the operator into the spark-operator namespace and wait for deployments to be ready
helm install spark-operator spark-operator/spark-operator \
    --namespace spark-operator --create-namespace --wait
```

### 🔹 Passo 4: Criar um job Spark
```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: spark-pi
  namespace: default
spec:
  type: Python
  mode: cluster
  image: "tiagotxm/spark:3.5.3-demo-yt"
  imagePullPolicy: Always
  mainApplicationFile: "local:///opt/spark/examples/src/main/python/pi.py"
  sparkVersion: "3.5.3"
  restartPolicy:
    type: Never
  volumes:
    - name: "test-volume"
      hostPath:
        path: "/tmp"
        type: Directory
  driver:
    cores: 1
    coreLimit: "1200m"
    memory: "512m"
    labels:
      version: 3.5.3
    serviceAccount: spark-operator-spark
    volumeMounts:
      - name: "test-volume"
        mountPath: "/tmp"
  executor:
    cores: 1
    instances: 1
    memory: "512m"
    labels:
      version: 3.5.3
    volumeMounts:
      - name: "test-volume"
        mountPath: "/tmp"

```

* Aplique o YAML no cluster:
```
kubectl apply -f spark-pi.yaml
```
* Para verificar o status do job:
```
kubectl get sparkapplications
```

* Para ver os logs
```
kubectl logs -f <nome-do-pod>
```

* Para deletar um job
```
kubectl delete sparkapplication <spark-app-name>
```

## 🛠 Criando uma Imagem do Spark Customizada

### 🔹 Criando um Dockerfile

- Para criar uma imagem base do Spark, utilize este
[Dockerfile](Dockerfile.base)

- Para instalar dependências do Iceberg, utilize este [Dockerfile.iceberg](Dockerfile)



### 🔹 Build e Push da imagem para o Docker Hub
O build será baseado na arquitetura do seu processador.
No meu caso, estou utilizando um processador ARM64, então a imagem será construída para essa arquitetura.
```
docker build -t <seu-usuario>/spark-iceberg:latest .
docker push <seu-usuario>/spark-iceberg:latest
```

### Tip: 
Realize o build da imagem do Spark para multiarquitetura, assim você poderá utilizá-la em diferentes processadores.
```
docker buildx build --platform linux/amd64,linux/arm64 -t <nome_da_imagem> --push .
```

---

## 📌 Kubeflow Spark Operator em Produção

Nesta seção, vamos abordar a execução de um job PySpark com Iceberg integrado ao S3 em um ambiente de produção.
Para isso iremos utilizar o EKS (Elastic Kubernetes Service) da AWS configurado com autoscaling(Karpenter) e o ArgoCD para deploy do Spark Operator.

## Requisitos
- AWS CLI instalado e configurado
- K9s

### 🔹 Deploy do EKS com Karpenter
````
$ terraform init
$ terraform apply -auto-approve
````

### 🔹 Autenticação local com cluster EKS
```
$ aws eks update-kubeconfig --name eks-data --region us-east-1                                  
```

### 🔹 Iniciando a sessão do k9s
```
$ k9s
```


## ArgoCD
Cria namespace para o Argo
````
$ kubectl create namespace argocd
````

Instala o ArgoCD
````
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

````
Recupera a senha do usuário admin para logar na UI
````
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
````

Criação da chave SSH para autenticação com o Argo
````
$ ssh-keygen -t rsa -b 4096 -C "<github_email>"
````


### Links úteis e Referências
- K9s - https://k9scli.io
- Karpenter - https://karpenter.sh/docs/
- IRSA - https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html


