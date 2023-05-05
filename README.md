# LEMP Server Setup

This guide walks through the steps required to setup and configure a LEMP stack server on Ubuntu 22.04.

- Create a VPS with Ubuntu 22.04 with SSH
- Register a domain name and point it at the VPS

**Contents**

- <a href="#initial-setup">Initial Setup</a>
  - <a href="#create-new-sudo-user">Create New Sudo User</a>
  - <a href="#update-package-manager">Update Package Manager</a>
- <a href="#nginxphp">Nginx/PHP</a>
  - <a href="#install-ssl-certificate">Install SSL Certificate</a>
- <a href="#mysql">MySQL</a>
- <a href="#deploying-from-github">Deploying from GitHub</a>
  - <a href="#installing-an-ssh-key-pair">Installing an SSH key pair</a>
  - <a href="#installing-configuring-git">Installing/configuring Git</a>

## Initial Setup

SSH into your server as the root user:

```shell
ssh root@<server-ip-address>
```

### Create New Sudo User

It is usually discouraged to use the root user regularly, so create a new user
and grant sudo privileges:

```shell
adduser username 
usermod -aG sudo username
```

Copy your SSH key to the new user directory (so you can SSH to the server as
your new user):

```shell
rsync --archive --chown=username:username ~/.ssh /home/username
```

Then allow OpenSSH and enable the firewall:

```shell
ufw enable
ufw allow OpenSSH
exit
```

### Update Package Manager

SSH to the server as your new user:

```shell
ssh username@<server-ip-address>
```

Update existing packages:

```shell
sudo apt update
```

## Nginx/PHP

Install Nginx and PHP:

```shell
sudo apt install nginx php8.1-fpm php-cli unzip
```

Update the firewall to allow Nginx connections on HTTP/HTTPS:

```shell
sudo ufw allow 'Nginx Full'
```

Create the config file for your domain:

```shell
sudo nano /etc/nginx/sites-available/domain.com
```

Paste in the following configuration:

```nginx
server {
    server_name domain.com www.domain.com;
    root /var/www/domain.com/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_split_path_info ^(.+`.php)(/.+)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~/\.ht {
        deny all;
    }
}
```

Add a symbolic link to your config file in sites enabled:

```shell
sudo ln -s /etc/nginx/sites-available/domain.com /etc/nginx/sites-enabled/
```

Unlink the default server block:

```shell
sudo unlink /etc/nginx/sites-enabled/default
```

Then reload Nginx to apply your changes:

```shell
sudo systemctl reload nginx
```

Set ownership of the `/var/www` directory:

```shell
sudo chown -R $USER:$USER /var/www
```

Make a public index file for testing your settings:

```shell
sudo mkdir -p /var/www/domain.com/public
sudo nano /var/www/domain.com/public/index.php
```

Check you can access your domain in your browser.

### Install SSL Certificate

You can use **Certbot** to install free, auto-renewing SSL certificates from **LetsEncrypt**.

First install `snap` and ensure it is up-to-date:

```shell
sudo snap install core
sudo snap refresh core
```

Install certbot and enable global usage of the `certbot` command:

```shell
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Install your SSL certificates:

```shell
sudo certbot --nginx -d mydomain.com -d www.mydomain.com
```

Then check you can hit your domain via HTTPS in your browser.

## MySQL

Install MySQL:

```shell
sudo apt install mysql-server
```

Connect to your MySQL instance:

```shell
sudo mysql
```

Then update the root user:

```mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by 'my-secret-password';
```

Create a new user for yourself/your application to use (so you aren't using root):

```mysql
CREATE USER 'user'@'host' IDENTIFIED WITH mysql_native_password by 'my-secret-password';
```

Grant relevant privileges to the new user and flush privileges:

```mysql
GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'user'@'host' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

Then exit the mysql terminal.

Next, update the bind address to allow remote access:

```shell
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

Set the bind address to `0.0.0.0` or comment out the line. Then run the `mysql_secure_installation` script:

```shell
sudo mysql_secure_installation
```

Then restart MySQL for changes to take effect:

```shell
sudo systemctl restart mysql
```

Allow remote access from your local IP address:

```shell
sudo ufw allow from remote_ip_address to any port 3306;
```

## Deploying from GitHub

### Installing an SSH key pair

To clone from private repositories, you'll need to add your servers SSH key to GitHub, so create one:

```shell
ssh-keygen
```

Copy and paste the output of the following command into a new SSH key on GitHub:

```shell
cat /home/username/.ssh/id_rsa.pub
```

### Installing/configuring Git

Git may already come installed on your server. You can check by running the `git` command.

If Git isn't installed, install it:

```shell
sudo apt install git
```

Set your Git credentials:

```shell
git config --global user.name "username"
git config --global user.email "email"
```

> To add:
> - Install composer
> - Install nodejs/npm (and update to latest stable)
> - Cloning from repo
