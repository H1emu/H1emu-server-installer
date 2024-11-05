#!/bin/bash

if (($EUID == 1)); then

  echo "Please use root user or sudo ./install.sh under your non-root account"
  exit
else
  echo "Welcome to the installation script for h1emu-server"
  echo "Continue at your own risk or use ctl-c to cancel the installation"
  echo ""
  echo -n "Do you want to setup your server as a community server ? (Y/n) :"
  read COMMUNITY_SERVER
  echo COMMUNITY_SERVER
  echo ""
  if [[ $COMMUNITY_SERVER == "y" ]]; then
    echo "You can request your WORLD_ID on the discord. If you do not know what WORLD_ID is cancel the installation with ctl-c"
    echo -n "please enter your WORLD_ID : "
    read WORLD_ID
  else
    WORLD_ID = 2
  fi
  echo "Running H1emu Server installer"
  echo "Installing system dependencies"
  apt update
  apt install -y git net-tools

  echo "Installing nodejs"
  apt install -y ca-certificates curl gnupg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

  apt update
  sudo apt install nodejs -y

  echo "Installing mongodb"
  sudo apt-get install gnupg curl
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc |
    sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
      --dearmor
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
  sudo apt-get update
  sudo apt-get install -y mongodb-org
  systemctl start mongod
  systemctl enable mongod
  # Path to MongoDB configuration file
  MONGO_CONF="/etc/mongod.conf"

  # Check if authentication is already enabled
  if grep -q "authorization: enabled" "$MONGO_CONF"; then
    echo "Authentication is already enabled in MongoDB configuration."
  else
    # Add authorization configuration to the MongoDB config file
    echo "Enabling authentication in MongoDB configuration..."

    # Use 'sudo' if necessary to edit configuration file
    sudo sed -i '/#security:/a\security:\n  authorization: enabled' "$MONGO_CONF"

    echo "Authentication enabled."
  fi
  # Allow connections from 0.0.0.0
  sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

  # Define new user credentials and database
  USERNAME="admin"
  PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z' | head -c 16)
  DB_NAME="h1server" # The database where the new user will be created

  # Create a MongoDB user with readWrite permissions on a specific database
  mongosh <<EOF
use admin

use $DB_NAME
db.createUser({
  user: "$USERNAME",
  pwd: "$PASSWORD",
  roles: [{ role: "readWrite", db: "$DB_NAME" }]
})
EOF

  echo "Installing pm2 via npm"
  npm i -g pm2

  echo "Installing latest h1z1-server"
  git clone https://github.com/H1emu/h1z1-server-QuickStart.git
  cd h1z1-server-QuickStart
  npm install

  echo "Updating .bashrc"
  # Add environment variables to ~/.bashrc if not already present
  if [ "$COMMUNITY_SERVER" != "y" ] && ! grep -q 'export PRIVATE_SERVER="true"' ~/.bashrc; then
    echo 'export PRIVATE_SERVER="true"' >>~/.bashrc
  fi

  if ! grep -q "export WORLD_ID='${WORLD_ID}'" ~/.bashrc; then
    echo "export WORLD_ID='${WORLD_ID}'" >>~/.bashrc
  fi

  if [ "$COMMUNITY_SERVER" != "y"] && ! grep -q 'export LOGINSERVER_IP="127.0.0.1"' ~/.bashrc; then
    echo 'export LOGINSERVER_IP="127.0.0.1"' >>~/.bashrc
  fi

  if ! grep -q 'export MONGO_URL="mongodb://localhost:27017/"' ~/.bashrc; then
    echo 'export MONGO_URL="mongodb://localhost:27017/"' >>~/.bashrc
  fi

  # Reload ~/.bashrc to apply the changes in the current session
  source ~/.bashrc

  echo "Environment variables have been added to ~/.bashrc and loaded into the current session."

  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "****************██╗░░██╗░░███╗░░███████╗███╗░░░███╗██╗░░░██╗**********************************"
  echo "****************██║░░██║░████║░░██╔════╝████╗░████║██║░░░██║**********************************"
  echo "****************███████║██╔██║░░█████╗░░██╔████╔██║██║░░░██║**********************************"
  echo "****************██╔══██║╚═╝██║░░██╔══╝░░██║╚██╔╝██║██║░░░██║**********************************"
  echo "****************██║░░██║███████╗███████╗██║░╚═╝░██║╚██████╔╝**********************************"
  echo "****************╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░░░░╚═╝░╚═════╝░**********************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "****************Access your MongoDB with http://SERVERIP:4321/ *******************************"
  echo "**********************************************************************************************"
  echo "****************To Connect to server with Game client SERVERIP:1115***************************"
  echo "**********************************************************************************************"
  echo "****************Use (pm2 kill) to stop server*************************************************"
  echo "**********************************************************************************************"
  echo "****************Use (pm2 log) to monitor******************************************************"
  echo "**********************************************************************************************"
  echo "****************Use (./start.sh) to start server**********************************************"
  echo "**********************************************************************************************"
  echo "****************Your H1emu Server is now installed *******************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
  echo "**********************************************************************************************"
fi
HOST_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "Please copy your mongodb access string it won't be gived to you ever again so save it. When saved press ENTER"
echo -n "mongodb://$USERNAME:$PASSWORD@$HOST_IP:27017/$DB_NAME"
read NOTHING
echo "Your system will now reboot"
sleep 10
reboot
