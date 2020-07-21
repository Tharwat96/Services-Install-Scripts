#!/bin/bash

# this script install gitea on ubuntu 18.04 Server instance.
# source: https://www.vultr.com/docs/how-to-install-gitea-on-ubuntu-18-04

sudo apt update
sudo apt -y install nginx

sudo systemctl enable nginx.service

sudo apt -y install git

sudo apt -y install mariadb-server mariadb-client

# automate mysql_secure_installation

# Make sure that NOBODY can access the server without a password
# set root password to root (change to env)
sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('root') WHERE User = 'root'"
# Kill the anonymous users
sudo mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
sudo mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
sudo mysql -e "DROP DATABASE test"
# Make our changes take effect
sudo mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param

sudo mysql -e "CREATE DATABASE gitea"

# create new user giteauser with password 'gitea'
sudo mysql -e "CREATE USER 'giteauser'@'localhost' IDENTIFIED BY 'gitea'"

sudo mysql -e "GRANT ALL ON gitea.* TO 'giteauser'@'localhost' IDENTIFIED BY 'gitea' WITH GRANT OPTION"

# allow changes to be taken
sudo mysql -e "FLUSH PRIVILEGES"

sudo echo "innodb_file_format = Barracuda
innodb_file_per_table = on
innodb_default_row_format = dynamic
innodb_large_prefix = 1
innodb_file_format_max = Barracuda" > /etc/mysql/my.cnf

sudo systemctl restart mariadb.service

sudo adduser \
   --system \
   --shell /bin/bash \
   --gecos 'Git Version Control' \
   --group \
   --disabled-password \
   --home /home/git \
   git
   
sudo mkdir -p /var/lib/gitea/{custom,data,indexers,public,log}
sudo chown git:git /var/lib/gitea/{data,indexers,log}
sudo chmod 750 /var/lib/gitea/{data,indexers,log}
sudo mkdir /etc/gitea
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea

sudo wget -O gitea https://dl.gitea.io/gitea/1.5.0/gitea-1.5.0-linux-amd64 
sudo chmod +x gitea

sudo cp gitea /usr/local/bin/gitea

sudo cp gitea.service /etc/systemd/system/gitea.service

sudo systemctl daemon-reload
sudo systemctl enable gitea
sudo systemctl start gitea

sudo systemctl status gitea

# configure nginx as reverse proxy

sudo rm /etc/nginx/sites-enabled/default

# copy gitea nginx conf

sudo cp gitea_nginx_conf /etc/nginx/sites-available/git

sudo ln -s /etc/nginx/sites-available/git /etc/nginx/sites-enabled

sudo systemctl reload nginx.service

# installation finished, final wizard required through web browser

echo "open http://your_domain.com/install in your browser to finish gitea wizard"