### Pré-requisitos
- Instalar o [docker](https://docs.docker.com/)
- Instalar o [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- Instalar o [Kubectl](https://kubernetes.io/docs/tasks/tools/)

Opcional: https://github.com/ahmetb/kubectx



### Criando cluster:

```kind create cluster --config cluster.yaml```

### Adicionando helm repo do spark

```helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator```

### Criar namespace exclusivo para execução dos jobs
```kubectl create namespace spark-jobs```

### Instalando spark operator
```helm install spark-operator -f values.yaml spark-operator/spark-operator --namespace spark-operator --create-namespace```

### Executando o job de teste
```kubectl apply -f hello-world.yaml```
