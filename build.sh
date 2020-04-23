# Set timezone
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# Set up swapfile
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
swapon -a /swapfile

/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1

# Install dependencies
apt update
apt -y upgrade
apt -y install \
  unzip \
  apache2 \
  mysql-server \
	php7.2 \
  php-dev \
  php-gd \
  php-soap \
  php-mbstring \
  php-curl \
  php-zip \
  php-mysql \

# Configure MySQL for Drupal connection
mysql	--execute="CREATE DATABASE drupal;"
mysql --execute="CREATE USER 'drupal'@'%' IDENTIFIED BY 'drupal';"
mysql --execute="GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'%';"
mysql	--execute="FLUSH PRIVILEGES;"
service mysql restart

# Configure Apache for serving Drupal 
echo "AddHandler php5-script .php" >> /etc/apache2/apache2.conf
echo "AddType text/html .php" >> /etc/apache2/apache2.conf
sed -i -e 's/AllowOverride\ None/AllowOverride\ All/g' /etc/apache2/apache2.conf
sed -i -e 's/\/var\/www\/html/\/var\/www\/html\/drupal\/web/g' /etc/apache2/sites-available/000-default.conf
rm /etc/php/7.2/apache2/php.ini
cp /vagrant/apache.php.ini /etc/php/7.2/apache2/php.ini
service apache2 restart

# Install latest & greatest version of Composer
cd /root; curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
composer global require zaporylie/composer-drupal-optimizations

# Set up Drupal codebase
cd /var/www/html
rm index.html
composer create-project drupal-composer/drupal-project:8.x-dev drupal --stability dev --no-interaction 
echo "PATH=/var/www/html/drupal/vendor/bin/:$PATH" >> /root/.profile
source /root/.profile

# Install Drupal
cd /var/www/html/drupal
drupal site:install standard \
        --langcode="en" \
        --db-type="mysql" \
        --db-host="localhost" \
        --db-name="drupal" \
        --db-user="drupal" \
        --db-pass="drupal" \
        --db-port="3306" \
        --site-mail="site@site.com" \
        --account-name="admin" \
        --account-pass="admin" \
        --account-mail="admin@site.com" \
        --no-interaction
