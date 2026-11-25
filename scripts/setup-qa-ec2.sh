#!/usr/bin/env bash
# One-time setup for EC2-B (Ubuntu 22.04/24.04): the QA Jenkins.
# Installs: swap, JDK 17, git, curl, Jenkins. (The demo tests only need bash + curl.)
# Run as the ubuntu user:   bash setup-qa-ec2.sh
set -euo pipefail

echo "== 1. Swap (2 GB) =="
if ! swapon --show | grep -q swapfile; then
  sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

echo "== 2. Packages + JDK 17 =="
sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-17-jre git curl wget gnupg ca-certificates

echo "== 3. Jenkins =="
if [ ! -d /var/lib/jenkins ]; then
  sudo wget -q -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y jenkins
fi
sudo systemctl enable --now jenkins

echo "== Versions =="
java -version 2>&1 | head -1
git --version
curl --version | head -1
sudo systemctl is-active jenkins

echo
echo "Initial Jenkins admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo
echo "Now open http://<this-server-public-ip>:8080 (security group must allow 8080 from your IP)."
