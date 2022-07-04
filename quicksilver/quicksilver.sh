#!/bin/bash
echo "DM_Paul"
echo "Install Quicksilver"
echo "to get interactive mode input '$quicksilver' "
$quicksilver=./quicksilver.sh

sleep 2

# set vars
if [ ! $NODENAME ]; then 
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
QUICKSILVER_PORT=26
if [ ! $WALLET ]; then
	echo "export WALLET="$NODENAME"-Wallet" >> $HOME/.bash_profile
fi
echo "export QUICKSILVER_CHAIN_ID=killerqueen-1" >> $HOME/.bash_profile
echo "export QUICKSILVER_PORT=${QUICKSILVER_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "Your node name: \e[1m\e[32m$NODENAME\e[0m"
echo -e "Your wallet name: \e[1m\e[32m$WALLET\e[0m"
echo -e "Your chain name: \e[1m\e[32m$QUICKSILVER_CHAIN_ID\e[0m"
echo -e "Your port: \e[1m\e[32m$QUICKSILVER_PORT\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl build-essential git wget jq make gcc tmux -y

# install go
ver="1.18.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
rm quicksilver -rf
git clone https://github.com/ingenuity-build/quicksilver.git --branch v0.4.0
cd quicksilver
make build
sudo chmod +x ./build/quicksilverd && sudo mv ./build/quicksilverd /usr/local/bin/quicksilverd

# config
quicksilverd config chain-id $QUICKSILVER_CHAIN_ID
quicksilverd config keyring-backend test
quicksilverd config node tcp://localhost:${QUICKSILVER_PORT}657

# init
quicksilverd init $NODENAME --chain-id $QUICKSILVER_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.quicksilverd/config/genesis.json "https://raw.githubusercontent.com/ingenuity-build/testnets/main/killerqueen/genesis.json"

# set peers and seeds
SEEDS="dd3460ec11f78b4a7c4336f22a356fe00805ab64@seed.killerqueen-1.quicksilver.zone:26656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.quicksilverd/config/config.toml

# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${QUICKSILVER_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${QUICKSILVER_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${QUICKSILVER_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${QUICKSILVER_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${QUICKSILVER_PORT}660\"%" $HOME/.quicksilverd/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${QUICKSILVER_PORT}317\"%; s%^address = \":8080\"%address = \":${QUICKSILVER_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${QUICKSILVER_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${QUICKSILVER_PORT}091\"%" $HOME/.quicksilverd/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.quicksilverd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.quicksilverd/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.quicksilverd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.quicksilverd/config/app.toml

# set minimum gas price
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0uqck\"/" $HOME/.quicksilverd/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.quicksilverd/config/config.toml

# reset
quicksilverd tendermint unsafe-reset-all --home $HOME/.quicksilverd

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/quicksilverd.service > /dev/null <<EOF
[Unit]
Description=quicksilver
After=network-online.target

[Service]
User=$USER
ExecStart=$(which quicksilverd) --home $HOME/.quicksilverd start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable quicksilverd
sudo systemctl restart quicksilverd

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u quicksilverd -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[32mcurl -s localhost:${QUICKSILVER_PORT}657/status | jq .result.sync_info\e[0m"


# load variables into system
source $HOME/.bash_profile

# firewall
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow ${QUICKSILVER_PORT}656,${QUICKSILVER_PORT}660/tcp
sudo ufw enable
sudo ufw reload

# create or restore wallet
PS3='Do you want to create or restore wallet? (input your choise number and press Enter): '
options=( "Create" "Restore" )
select opt in "${options[@]}"
do
  case $opt in
    "Create")
      quicksilverd keys add $WALLET
      break
    ;;
    "Restore")
      quicksilverd keys add $WALLET --recover
    ;;
  esac
done

QUICKSILVER_WALLET_ADDRESS=$(quicksilverd keys show $WALLET -a)
QUICKSILVER_VALOPER_ADDRESS=$(quicksilverd keys show $WALLET --bech val -a)
echo 'export QUICKSILVER_WALLET_ADDRESS='${QUICKSILVER_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export QUICKSILVER_VALOPER_ADDRESS='${QUICKSILVER_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile



###################################### Useful Commands ######################################

# check sync
# quicksilverd status 2>&1 | jq .SyncInfo

# get wallet list
# quicksilverd keys list

# calculate synchronization time
# wget -O synctime.py https://raw.githubusercontent.com/kj89/testnet_manuals/main/quicksilver/tools/synctime.py && python3 ./synctime.py

# get validators list
# quicksilverd q staking validators -oj --limit=3000 | jq '.validators[] | select(.status=="BOND_STATUS_BONDED")' | jq -r '(.tokens|tonumber/pow(10; 6)|floor|tostring) + " \t " + .description.moniker' | sort -gr | nl