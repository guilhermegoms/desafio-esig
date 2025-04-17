#!/bin/bash

set -e

echo "🔧 Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y

echo "🐳 Instalando Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

echo "📦 Instalando Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "☸️ Instalando kubectl..."
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
  https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubectl

echo "📦 Instalando Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "🧰 Instalando dependências adicionais..."
sudo apt install -y conntrack socat

echo "🚀 Inicializando Minikube..."
minikube start --driver=docker

echo "✅ Instalação finalizada!"
echo "⚠️ IMPORTANTE: reinicie sua sessão (logout/login) para que a permissão do Docker funcione."

echo "💡 Agora você pode usar:"
echo "- docker-compose up -d"
echo "- kubectl apply -f k8s/"
