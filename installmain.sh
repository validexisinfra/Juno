#!/bin/bash

set -e

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

print() {
  echo -e "${GREEN}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

read -p "Enter your node MONIKER: " MONIKER
read -p "Enter your custom port prefix (e.g. 16): " CUSTOM_PORT

print "Installing Juno Node with moniker: $MONIKER"
print "Using custom port prefix: $CUSTOM_PORT"

print "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y curl git build-essential lz4 wget

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf juno
git clone https://github.com/CosmosContracts/juno juno
cd juno
git checkout v28.0.2
make install

junod config set client chain-id juno-1
junod config set client keyring-backend file
junod config set client node tcp://localhost:${CUSTOM_PORT}657
junod init $MONIKER --chain-id=juno-1

wget -L -O $HOME/.juno/config/genesis.json https://server-1.stavr.tech/Mainnet/Juno/genesis.json
wget -O $HOME/.juno/config/addrbook.json "https://server-1.stavr.tech/Mainnet/Juno/addrbook.json"

sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.juno/config/config.toml
external_address=$(wget -qO- eth0.me) 
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.juno/config/config.toml
peers=""
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.juno/config/config.toml
seeds=""​
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025ujuno\"/;" $HOME/.juno/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.juno/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.juno/config/config.toml

pruning="custom"
pruning_keep_recent="1000"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.juno/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.juno/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.juno/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.juno/config/app.toml

sed -i.bak -e "s%:26658%:${CUSTOM_PORT}658%g;
s%:26657%:${CUSTOM_PORT}657%g;
s%:26656%:${CUSTOM_PORT}656%g;
s%:6060%:${CUSTOM_PORT}060%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CUSTOM_PORT}56\"%;
s%:26660%:${CUSTOM_PORT}660%g" $HOME/.juno/config/config.toml

sed -i.bak -e "s%:1317%:${CUSTOM_PORT}317%g;
s%:8080%:${CUSTOM_PORT}080%g;
s%:9090%:${CUSTOM_PORT}090%g;
s%:9091%:${CUSTOM_PORT}091%g;
s%:8545%:${CUSTOM_PORT}545%g;
s%:8546%:${CUSTOM_PORT}546%g" $HOME/.juno/config/app.toml

sudo tee /etc/systemd/system/junod.service > /dev/null <<EOF
[Unit]
Description=juno
After=network-online.target
​
[Service]
User=$USER
ExecStart=$(which junod) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
​
[Install]
WantedBy=multi-user.target
EOF

print "Downloading snapshot..."
LATEST_SNAPSHOT=$(curl -s https://server-1.stavr.tech/Mainnet/Juno/ | grep -oE 'juno-snap-[0-9]+\.tar\.lz4' | while read SNAPSHOT; do HEIGHT=$(curl -s "https://server-1.stavr.tech/Mainnet/Juno/${SNAPSHOT%.tar.lz4}-info.txt" | awk '/Block height:/ {print $3}'); echo "$SNAPSHOT $HEIGHT"; done | sort -k2 -nr | head -n 1 | awk '{print $1}')
curl -o - -L https://server-1.stavr.tech/Mainnet/Juno/$LATEST_SNAPSHOT | lz4 -c -d - | tar -x -C $HOME/.juno

sudo systemctl daemon-reload
sudo systemctl enable junod
sudo systemctl restart junod

print "✅ Setup complete. Use 'journalctl -u junod -f -o cat' to view logs"
