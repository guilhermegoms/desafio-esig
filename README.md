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

## Considerações Finais

- Jenkins e Jolokia foram implantados com sucesso em um contêiner Docker usando Tomcat como servidor de aplicação.
- Métricas expostas via Jolokia estão acessíveis na porta 8080 para futura integração com ferramentas como Prometheus.
- O projeto já possui estrutura para migração para Kubernetes com `k3d`, iniciada na Etapa 2.

---

**Autor:** Guilherme Gomes  
**Etapa:** 1/3  
**Projeto Técnico - Analista de Infraestrutura 2025 - ESIG Group**

