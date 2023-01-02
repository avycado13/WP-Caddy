echo "Hello World";
echo "Let's get started!"
while true
  if ! [ -x "$(command -v caddy)" ]; then
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update
    sudo apt upgrade
    sudo apt install caddy
    break
  fi
fi
#install wp + deps
cd /var/www
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
chown -R www-data:www-data /var/www/wordpress
find wordpress/ -type d -exec chmod 755 {} \;
find wordpress/ -type f -exec chmod 644 {} \;
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
echo "Now I am going to see that wp-cli works"
php wp-cli.phar --info
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
apt install php php-mysql
apt purge apache2*
sudo apt install php-mysqlnd php-gd php-json php-mbstring php-xml php-imagick php-intl php-dom php-curl php-zip
#install mariadb-server
while true
  if ! [ -x "$(command -v caddy)" ]; then
    sudo apt install mariadb-server
    mysql_secure_installation
  fi
fi
#set up db credit to Harish Kumar
if [ -f /root/.my.cnf ]; then
	echo "Enter database name!"
	read dbname
    
	echo "Creating new MySQL database..."
	mysql -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	echo "Database successfully created!"
	
	echo "Enter database user!"
	read username
    
	echo "Enter the PASSWORD for database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
    
	echo "Creating new user..."
	mysql -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"

	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
	
# If /root/.my.cnf doesn't exist then it'll ask for root password	
else
	echo "Please enter root user MySQL password!"
	echo "Note: password will be hidden when typing"
	read -s rootpasswd
    
	echo "Enter database name!"
	read dbname
    
	echo "Creating new MySQL database..."
	mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	echo "Database successfully created!"
    
	echo "Enter database user!"
	read username
    
	echo "Enter the PASSWORD for database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
    
	echo "Creating new user..."
	mysql -uroot -p${rootpasswd} -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"
	
	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
fi
read -p "Wordpress Username: " username
while true; do
  read -s -p "Wordpress Password: " password
  echo
  read -s -p "Wordpress Password (again): " password2
  echo
  [ "$password" = "$password2" ] && break
  echo "Please try again"
done

read -p "Wordpress Email: " email
read -p "Wordpress Website Title: " title
read "Enter domain for Your wordpress installation > " domain
wp core install --url=$REPL_URL --title=$title --admin_user=$username --admin_password=$password --admin_email=$email

echo "$domain {
    root * /var/www/wordpress
    php_fastcgi unix//run/php/php8.2-fpm.sock
    file_server
    encode gzip
    @disallowed {
        path /xmlrpc.php
        path *.sql
        path /wp-content/uploads/*.php
    }
    rewrite @disallowed '/index.php'
}" > /etc/caddy/Caddyfile
echo "Restarting caddy"
sudo systemctl start caddy
echo "All done  your wordpress installation should be active at $domain"
