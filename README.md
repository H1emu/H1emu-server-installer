Tested on Ubuntu 24 LTS

# Install
```
git clone https://github.com/H1emu/h1emu-server-installer.git
cd h1emu-server-installer
chmod +x install.sh start.sh update-installer.sh update-server-to-unstable.sh update-server.sh
./install.sh
```

# Starting the server
`./start.sh` inside the h1emu-server-installer directory.

# Connecting to your MongoDB database

Use [MongoDB Compass](https://www.mongodb.com/products/tools/compass)

Your connection string will be gived to you only once at the end of the installation so don't miss it.


# For private/personnal servers
The loginserver need to identify the gameserver IP as a valid one so you have to modify the /servers collection in mongodb.
Edit the server with serverId 2 and put your server IP instead of localhost.
