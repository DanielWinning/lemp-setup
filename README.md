# Guide to configuring a LEMP stack server

This repository is designed to help understand the required steps when setting up
a new LEMP stack VPS. I'm using a Digital Ocean droplet, but you should be able to
follow this as long as you have an Ubuntu 22.04 based server.

- Create a new VPS with Ubuntu 22.04.
- Configure your server to use SSH.
- Register domain name and point at your VPS.

## Initial Server Setup

Login as the root user by opening a local terminal and running:

```shell
ssh root@<server-ip-address>
```

It is usually discouraged to use the root user regularly, so create a new user
and grant sudo privileges:

```shell
adduser username 
usermod -aG sudo username
```

Next, enable the firewall and allow OpenSSH:

```shell
ufw enable
ufw allow OpenSSH
```

> To list available apps use the command:
> ```shell
> ufw app list
> ```
>
> To check firewall status, use the command:
> ```shell
> ufw status
> ```

Copy your SSH key to the new user directory (so you can SSH to the server as
your new user):

```shell
rsync --archive --chown=username:username ~/.ssh /home/username
exit
```

## Install Required Apps/Software

SSH to the server as your new user:

```shell
ssh username@<server-ip-address>
```

Update existing packages and install required packages - this installs the EMP part
of your stack:

```shell
sudo apt update
sudo apt install nginx mysql-server php8.1-fpm php-cli unzip nodejs npm -y
```

Update firewall settings to allow Nginx (HTTP & HTTPS):

```shell
sudo ufw allow 'Nginx Full'
```

## Server: Nginx

Create a directory for your new app and change ownership to current logged-in
user:

```shell
sudo mkdir /var/www/domain.com
sudo chown -R $USER:$USER /var/www/domain.com
```

Next, add some basic Nginx config:

```shell
sudo nano /etc/nginx/sites-available/domain.com
```

Paste the following and save:

```nginx configuration
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
        fastcgi_split_path_info ^(.+`.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~/\.ht {
        deny all;
    }
}
```

Confirm the config is valid:

```
sudo nginx -t
```

Create a symbolic link to your `sites-enabled` directory:

```shell
sudo ln -s /etc/nginx/sites-available/domain.com /etc/nginx/sites-enabled/
```

Reload Nginx to apply changes:

```shell
sudo systemctl reload nginx
```

Create an index file to test:

```shell
sudo nano /var/www/domain.com/public/index.php
```

Test by hitting your domain name in your browser.

## Database: MySQL

Connect to your mysql instance:

```shell
sudo mysql
```

Then run the commands found in `/sql/users.sql` to update your root user and create
new database users. Replace `0.0.0.0` with your local IP if you wish to add a remote user:

```shell
mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by 'my-secret-password';
mysql> CREATE USER 'user'@'localhost' IDENTIFIED WITH mysql_native_password by 'my-secret-password';
mysql> CREATE USER 'user'@'0.0.0.0' IDENTIFIED WITH mysql_native_password by 'my-secret-password';
mysql> GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'user'@'localhost' WITH GRANT OPTION;
mysql> GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'user'@'0.0.0.0' WITH GRANT OPTION;
mysql> FLUSH PRIVILEGES;
mysql> exit
```

Next update the bind address to allow remote access:

```shell
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

Set bind address to `0.0.0.0`. Then run the `mysql_secure_installation` script:

```shell
sudo mysql_secure_installation
```

Then restart MySQL for changes to take effect:

```shell
sudo systemctl restart mysql
```

You can test your Database connection in your IDE or whatever local tool you usually use
to connect to your databases.

## Next Steps

### Install SSL Certificate

To enable free, auto-renewing SSL certificates, you can use **Certbot**. Certbot requires
`snap` to be installed before it can be used. Your server may already come with this out
of the box.

```
sudo snap install core
sudo snap refresh core
```

Install certbot and enable global usage of the `certbot` command:

```
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Install your SSL certificates:

```
sudo certbot --nginx -d mydomain.com -d www.mydomain.com
```

If you get failures validating IPv6 addresses, you can check your DNS settings
to see if you have AAAA records defined. You can delete these records or ensure
that your server also has an IPv6 address. On Digital Ocean you can do this under
the network tab of your droplet.

Once your SSL certificates are installed check you can hit your domain using HTTPS.

### Setup Git

Git may already be installed on your server. To check:

```shell
git --version
```

If the `git` command is not recognised, install it:

```shell
sudo apt install git -y
```

Then you can set your username/email address:

```shell
git config --global user.name "username"
git config --global user.email "email@example.com"
```

### Install Composer

Download Composer:

```shell
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
```

Verify installer:

```shell
HASH=`curl -sS https://composer.github.io/installer.sig`
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
```

Install Composer:

```shell
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
```

Confirm Composer is installed correctly:

```shell
composer
```