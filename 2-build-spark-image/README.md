## Pré-requisitos
- Criar uma conta no [Docker Hub](https://hub.docker.com/)
- Docker engine
- Java (pode ser a versão 11)


## Criando imagem do Spark com S3A Commiters

- Acessar https://spark.apache.org/downloads.html
- Selecionar a release para download 
- No campo `Choose a package type` marque `Source Code`
- Descompacte o arquivo
    `tar -xvf spark <file-dir>`
- cd `<file-dir>`
- Rode o comando para criar uma distribuição da imagem do Spark com o S3A Commiters

  - Obs: Caso queira mudar a versão do scala(e.x 2.13), rode primeiro:
    - `./dev/change-scala-version.sh 2.13`

  ```
  ./dev/make-distribution.sh --name spark-py --pip --tgz -B -Pkubernetes -Pscala-2.12 -Phadoop-3.2 -Phadoop-cloud -Phive -Phive-thriftserver -DskipTests
  ```

- Será criado o diretório `dist` automaticamente após executado com sucesso

- Rode o comando abaixo para criar a imagem do Spark com Python
  - ``` cd dist && ./bin/docker-image-tool.sh -t <tag-name> -p ./kubernetes/dockerfiles/spark/bindings/python/Dockerfile build```


- Realizar login no Docker Hub
  
  ```docker login```

- Publicar imagem no Docker Hub

  ```docker push <image>```


### Troubleshooting

- Criar um container para execução de comandos
```docker run -it --rm <image-id> /bin/bash```

