#!/bin/bash

echo "🔧 Iniciando preparação do ambiente..."

# Atualiza pacotes
sudo apt update && sudo apt upgrade -y

# Instala dependências básicas
sudo apt install -y curl apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# Instala Docker
if ! command -v docker &> /dev/null; then
  echo "📦 Instalando Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
fi

# Instala Docker Compose
if ! command -v docker-compose &> /dev/null; then
  echo "📦 Instalando Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Instala kubectl
if ! command -v kubectl &> /dev/null; then
  echo "📦 Instalando kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

# Instala k3d
if ! command -v k3d &> /dev/null; then
  echo "📦 Instalando k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Cria cluster k3d
echo "🚀 Criando cluster k3d..."
k3d cluster create jenkins-cluster --api-port 6550 -p "8888:80@loadbalancer"

# Ativa o contexto no kubectl
k3d kubeconfig merge jenkins-cluster --switch

# Confirma nodes
kubectl get nodes

echo "✅ Ambiente pronto! Jenkins será acessível via: http://localhost:8888"
