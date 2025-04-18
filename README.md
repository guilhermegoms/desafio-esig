# Etapa 1 - Projeto de Infraestrutura: Jenkins em Docker com Tomcat e Jolokia

## Objetivo

Implantar o Jenkins utilizando um contêiner Docker com Tomcat como servidor de aplicação, expondo as métricas da aplicação via Jolokia para futura integração com ferramentas de monitoramento.

---

## Tecnologias Utilizadas

- Docker
- Docker Compose
- Tomcat 9.0
- Jenkins (formato WAR)
- Jolokia (formato WAR)
- k3d (para a próxima etapa)
- kubectl

---

## Estrutura do Projeto

```bash
├── Dockerfile
├── docker-compose.yaml
├── jenkins.war
├── jolokia.war
├── setup_infra.sh        
```

---

## Passo a Passo da Etapa 1

### 1. Preparação do Ambiente

Execute o script de infraestrutura:
```bash
chmod +x setup_infra.sh
./setup_infra.sh
```

Esse script realiza:
- Instalação do Docker
- Instalação do Docker Compose
- Instalação do `kubectl`
- Instalação do `k3d`
- Criação do cluster `jenkins-cluster` com redirecionamento de porta 8888 para 80 (LoadBalancer)
- Ativação do contexto Kubernetes via `kubectl`

### 2. Clonar ou preparar o diretório do projeto


- `jenkins.war`: baixado do site oficial do Jenkins
- `jolokia.war`: baixado do site oficial do Jolokia

### 3. Dockerfile

Arquivo responsável por criar a imagem baseada no Tomcat com os arquivos WAR copiados para o diretório de deploy:

```dockerfile
FROM tomcat:9.0
COPY jenkins.war /usr/local/tomcat/webapps/
COPY jolokia.war /usr/local/tomcat/webapps/

COPY tomcat-users.xml /usr/local/tomcat/conf/ # Usado para atribuir as credenciais para o jolokia.
```

### 4. docker-compose.yaml

Arquivo responsável por subir o contêiner com reinício automático e exposição da porta 8080:

```yaml
services:
  jenkins:
    build: .
    container_name: jenkins-tomcat
    ports:
      - "8080:8080"
    restart: unless-stopped
```

### 5. Build e execução

Para construir a imagem e subir o contêiner, execute:

```bash
docker-compose up --build -d
```
Subi no DOckerHub a imagem montada com a etapa 1.

https://hub.docker.com/repository/docker/guilhermegoms/jenkins-jolokia


### 6. Verificação

Acesse o Jenkins via navegador:
```
http://localhost:8080/jenkins
```

Acesse o Jolokia (métricas expostas):
```
http://localhost:8080/jolokia
```

### 7. Container

Para visualizar os logs do Jenkins:
```bash
docker logs -f jenkins-tomcat
```

---

## Considerações da 1 etapa.

- Jenkins e Jolokia foram implantados com sucesso em um contêiner Docker usando Tomcat como servidor de aplicação.
- Métricas expostas via Jolokia estão acessíveis na porta 8080 para futura integração com ferramentas como Prometheus.
- O projeto já possui estrutura para migração para Kubernetes com `k3d`, iniciada na Etapa 2.

---


**Etapa:** 1/3  


# Etapa 2 - Projeto de Infraestrutura: Jenkins no Kubernetes com k3d

## Objetivo

Implantar a aplicação do Jenkins (com Jolokia) no Kubernetes utilizando o k3d como ambiente de cluster local. A imagem previamente construída e publicada no Docker Hub durante a Etapa 1 será utilizada para esse deploy.

---

## Tecnologias Utilizadas

- Kubernetes
- k3d
- kubectl
- Docker Hub
- Jenkins
- Jolokia

---

## Imagem Utilizada

A imagem Docker foi criada na **Etapa 1**, com base no Tomcat, contendo os arquivos `jenkins.war` e `jolokia.war` copiados para a pasta de deploy do Tomcat.

📦 Docker Hub: [https://hub.docker.com/r/guilhermegoms/jenkins-jolokia](https://hub.docker.com/r/guilhermegoms/jenkins-jolokia)

---

## Passo a Passo da Etapa 2

### 1. Subida do Cluster Kubernetes com k3d

```bash
k3d cluster create jenkins-cluster --api-port 6550 -p "8888:80@loadbalancer"
k3d kubeconfig merge jenkins-cluster --switch
```

Verifique se o cluster está ativo:
```bash
kubectl get nodes
```

### 2. Manifestos Kubernetes Criados

Foram criados dois arquivos YAML na pasta `k8s/`:

#### a) `jenkins-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
        - name: jenkins
          image: guilhermegoms/jenkins-jolokia:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
```

#### b) `jenkins-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jenkins
spec:
  selector:
    app: jenkins
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: LoadBalancer
```

### 3. Aplicando os Manifestos

```bash
kubectl apply -f k8s/jenkins-deployment.yaml
kubectl apply -f k8s/jenkins-service.yaml
```

### 4. Acesso à aplicação

Como o cluster foi criado com `k3d` expondo a porta 8888 para o load balancer, a aplicação pode ser acessada via:
```
http://localhost:8888/jenkins
```

E as métricas do Jolokia:
```
http://localhost:8888/jolokia
```

---

## Considerações Finais

- O Jenkins foi migrado com sucesso do ambiente Docker para o Kubernetes.
- O cluster `k3d` é leve, eficiente e ideal para desenvolvimento local.
- Os manifestos foram organizados na pasta `k8s/`.
- A imagem utilizada foi construída na Etapa 1 e publicada no Docker Hub.

---


**Etapa:** 2/3  

# Etapa 3 - Projeto de Infraestrutura: Monitoramento com Prometheus e Node Exporter

## Objetivo

Configurar o Prometheus no cluster Kubernetes para coletar métricas da aplicação Jenkins via Jolokia, além de coletar métricas dos nós do cluster com o Node Exporter.

---

## Tecnologias Utilizadas

- Kubernetes
- Prometheus
- Node Exporter
- Jolokia
- Grafana (opcional para visualização futura)

---

## Organização do Projeto

Esta etapa está documentada no repositório público do GitHub:

🔗 [https://github.com/guilhermegoms/desafio-esig](https://github.com/guilhermegoms/desafio-esig)

Os manifestos Kubernetes estão incluídos no repositório, organizados dentro da pasta `k8s/` e utilizando o namespace `infraesig`.

---

## Estrutura de Diretório (pasta `k8s/`)

```bash
k8s/
├── jenkins-deployment.yaml       # Deployment do Jenkins
├── jenkins-service.yaml          # Service do Jenkins
├── prometheus-config.yaml        # ConfigMap com scrape configs
├── prometheus-deployment.yaml   # Deployment do Prometheus
├── prometheus-service.yaml      # Service para Prometheus
├── node-exporter.yaml           # DaemonSet do Node Exporter
```

---

## Passo a Passo da Etapa 3

### 1. Criação do Namespace

Antes de aplicar os recursos, foi criado o namespace `infraesig`:

```bash
kubectl create namespace infraesig
```

Todos os manifestos foram configurados para utilizar esse namespace.

### 2. Configuração do Prometheus e Node Exporter

Os manifestos foram ajustados para incluir o namespace `infraesig` e garantir a coleta de métricas do Jenkins (via Jolokia) e dos nós do cluster com o Node Exporter. Os arquivos incluem:
- ConfigMap (`prometheus.yml`)
- Deployment
- Service
- DaemonSet

### 3. Aplicação dos Manifestos

```bash
kubectl apply -f k8s/ -n infraesig
```

Verifique se os pods estão em execução:
```bash
kubectl get pods -n infraesig
```

### 4. Acesso às aplicações

Como o cluster foi criado com mapeamento de portas do `k3d`, os acessos locais ficaram assim:

- Jenkins: [http://<Ip_do_node>:30001/jenkins](http://localhost:30000/jenkins)
- Jolokia: [http://<Ip_do_node>:30001/jolokia](http://localhost:30000/jolokia)
- Prometheus: [http://<Ip_do_node>:30005](http://localhost:30001)
- Grafana: [http://<Ip_do_node>:30001](http://localhost:30001)

Use a interface do Prometheus para visualizar os targets de scrape e consultar métricas como:

- `node_cpu_seconds_total`

Tomei a liberdade de importar um dashboard direto do site do Grafana, par aNode exporter.

---

## Considerações Finais

- O Prometheus foi implantado com sucesso no cluster Kubernetes.
- As métricasdos nós via Node Exporter estão sendo coletadas.
- Toda a configuração foi isolada dentro do namespace `infraesig`.
- A estrutura pode ser expandida com Grafana para visualização de métricas.
- O código-fonte completo e os arquivos `.yaml` estão disponíveis no repositório do projeto.
🔗 [https://github.com/guilhermegoms/desafio-esig](https://github.com/guilhermegoms/desafio-esig)
---

**Autor:** Guilherme Gomes  
**Etapa:** 3/3  
**Projeto Técnico - Analista de Infraestrutura 2025 - ESIG Group**





