#!/bin/bash

# Variables and Initialization
ERROR_FLAG=0

# Functions
handle_error() {
    if [ $ERROR_FLAG -ne 0 ]; then
        echo "An error occurred. Reversing the setup..."
        rollback_setup
        exit 1
    fi
}

remove_directory() {
    if [ -d "$1" ]; then
        rm -rf "$1"
    fi
}

remove_database() {
    mysql -u $db_user -p$db_pass -e "DROP DATABASE IF EXISTS $1;"
}

remove_virtualhost() {
    if [ -f "/etc/httpd/conf.d/$1.conf" ]; then
        rm "/etc/httpd/conf.d/$1.conf"
    fi
}

rollback_setup() {
    # Reverse directory creation
    remove_directory "$NewDomainPath"

    # Reverse database creation
    remove_database "$websitedbname"

    # Remove virtual host config
    remove_virtualhost "$NewDomainName"
    
    # Other rollback operations can be added here if needed
}

# Check if the domain name is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <NewDomainName>"
    exit 1
fi

NewDomainName=$1
#uncomment db_user and hardcode the db user name as value
#db_user="dbusername" 
NewDomainPath="/var/www/$NewDomainName"
html_path="$NewDomainPath/html"
log_path="$NewDomainPath/log"
credentials_file="credentials.txt"


# Check if a directory with the same domain name already exists
if [ -d "$NewDomainPath" ]; then
    echo "A directory with this domain name already exists. Please choose a different name."
    exit 1
fi

# Check if Credentials file does present in the current directory.
if [ ! -f "$credentials_file" ]; then
    echo "Credentials file does not exist in the current directory."
    exit 1
fi

# Check if mysql is installed, if not install it
if ! command -v mysql &> /dev/null
then
    echo "MySQL is not installed. Installing MySQL using below command."
    echo "yum install -y mysql"
	exit 1
fi

# Prompt the user before generating the certificate

read -p "Do you want to install LetsEncrypt Certificates? (yes/no): " install_certificates

if [ "$install_certificates" == "yes" || "$install_certificates" == "y" ]; then

# Check if certbot is installed, if not install it
	if ! command -v certbot &> /dev/null
	then
		echo "Certbot is not installed. Install mod_ssl mod_http2 certbot python3-certbot-apache. Open Port 80 and 443 in the firewall"
		echo "yum install -y  mod_ssl mod_http2 certbot python3-certbot-apache"
		echo "sudo certbot --apache --non-interactive --agree-tos --email admin@domain.com"
		exit 1
	fi
fi

# Parse credentials from file comment bewlow lines if you want to enter password on prompt and uncomment "Enter MySQL Password:" below.

db_user=$(grep DB_USER $credentials_file | cut -d '=' -f 2-)
db_pass=$(grep DB_PASS $credentials_file | cut -d '=' -f 2-)

# Check if curl is installed, if not install it
if ! command -v curl &> /dev/null
then
    echo "Curl is not installed. Installing curl..."
    sudo yum install -y curl || { echo "Failed to install curl"; exit 1; }
fi


# Check if unzip is installed, if not install it
if ! command -v unzip &> /dev/null
then
    echo "Unzip is not installed. Installing unzip..."
    sudo yum install -y unzip || { echo "Failed to install unzip"; exit 1; }
fi

# Generate database name by replacing '.' with '_'
websitedbname="website_${NewDomainName//./_}"

# Uncomment below lines if you want to Ask for MySQL password
#echo "Enter your MySQL password:"
#read -s db_pass

# Check if wget is installed, if not install it
if ! command -v wget &> /dev/null
then
    echo "Wget is not installed. Installing wget..."
    sudo yum install -y wget || { echo "Failed to install wget"; exit 1; }
fi

# Download WordPress
wget https://wordpress.org/latest.zip -O latest.zip

# Check if HTML directory exists, if not create it
if [ ! -d $html_path ]; then
    mkdir -p $html_path || { echo "Failed to create directory $html_path"; ERROR_FLAG=1; handle_error; }
fi

# Check if LOG directory exists, if not create it
if [ ! -d $log_path ]; then
    mkdir -p $log_path || { echo "Failed to create directory $log_path"; ERROR_FLAG=1; handle_error; }
fi


# Unzip WordPress files
unzip -o -q latest.zip

# Move WordPress files to the domain's directory
mv wordpress/* $html_path/

# Remove the now-empty 'wordpress' directory
rmdir wordpress


# Fetch unique keys and salts from the WordPress API
keys_salts=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Write the keys and salts to a temporary file that includes the website name
echo "$keys_salts" > "${NewDomainName}_temp.txt"

# Define the keys to search for
keys=('AUTH_KEY' 'SECURE_AUTH_KEY' 'LOGGED_IN_KEY' 'NONCE_KEY' 'AUTH_SALT' 'SECURE_AUTH_SALT' 'LOGGED_IN_SALT' 'NONCE_SALT')

# Read the keys and salts from the temporary file line by line
index=0
while IFS= read -r line
do
    # Escape special characters in the line
    line_escaped=$(echo "$line" | sed -e 's/[\/&]/\\&/g')

    # Replace the line with the key with the new one
    sed -i "/define( '${keys[$index]}',/c\\${line_escaped}" $html_path/wp-config-sample.php

    # Go to the next key
    ((index++))
done < "${NewDomainName}_temp.txt"

# Remove the temporary file
rm "${NewDomainName}_temp.txt"


# Change ownership to apache user
sudo chown -R apache:apache $NewDomainPath

# Create a new MySQL database and user with all privileges to the new database
# mysql -u $mysqladminuser -p$password -e "CREATE DATABASE $websitedbname; CREATE USER '$NewDomainName'@'localhost' IDENTIFIED BY '$password'; GRANT ALL PRIVILEGES ON $websitedbname.* TO '$NewDomainName'@'localhost'; FLUSH PRIVILEGES;" || { echo "Failed to setup MySQL"; exit 1; }
mysql -u $db_user -p$db_pass -e "CREATE DATABASE $websitedbname;" || { echo "Failed to setup MySQL"; ERROR_FLAG=1; handle_error; }

# Rename the wp-config-sample.php and update the database name, user, and password
cp $html_path/wp-config-sample.php $html_path/wp-config.php
sed -i "s/database_name_here/$websitedbname/g" $html_path/wp-config.php
sed -i "s/username_here/$db_user/g" $html_path/wp-config.php
sed -i "s/password_here/$db_pass/g" $html_path/wp-config.php


# Ask the user if they're using SendGrid
read -p "Are you planning using SendGrid and FluentMail Plugin for email delivery? (yes/no): " sendgrid_response

if [ "$sendgrid_response" == "yes" ]; then
# Parse credentials from file comment bewlow lines if you want to enter the key on prompt and uncomment "Sendgrid Key" below.
	fluentmail_api_key=$(grep FLUENTMAIL_SENDGRID_API_KEY $credentials_file | cut -d '=' -f 2-)
    #read -p "Please provide your SendGrid API Key: " fluentmail_api_key
    # Insert the Sendgrid key line into wp-config.php before the specified pattern
	sed -i "/\/\* That's all, stop editing! Happy publishing. \*\//i\define( 'FLUENTMAIL_SENDGRID_API_KEY', '$fluentmail_api_key' );" $html_path/wp-config.php
   
fi


# Create and configure the virtual host in Apache

# Check if domain or subdomain
if [[ $NewDomainName == *.*.* ]]; then
    # Handle subdomains
    cat > /etc/httpd/conf.d/$NewDomainName.conf << EOF
<VirtualHost *:80>
    ServerName $NewDomainName
    DocumentRoot $html_path
    <Directory $html_path/>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>
    ErrorLog $NewDomainPath/log/error.log
    CustomLog $NewDomainPath/log/requests.log combined
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$NewDomainName
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOF
else
    # Handle main domains
    cat > /etc/httpd/conf.d/$NewDomainName.conf << EOF
<VirtualHost *:80>
    ServerName $NewDomainName
    ServerAlias www.$NewDomainName
    DocumentRoot $html_path
    <Directory $html_path/>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>
    ErrorLog $NewDomainPath/log/error.log
    CustomLog $NewDomainPath/log/requests.log combined
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$NewDomainName [OR]
    RewriteCond %{SERVER_NAME} =www.$NewDomainName
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOF
fi


# Reload Apache to apply changes
sudo systemctl reload httpd || { echo "Failed to reload Apache"; exit 1; }

# Generate a certificate for the new domain using certbot
# sudo certbot --apache --non-interactive --agree-tos --email admin@$NewDomainName --domain $NewDomainName --domain www.$NewDomainName || { echo "Failed to setup Certbot"; exit 1; }

if [[ $NewDomainName == *.*.* ]]; then
   	 # Handle subdomains
	echo "Adding 127.0.0.1 $NewDomainName /etc/hosts..."
	echo "127.0.0.1 $NewDomainName" >> /etc/hosts
else
	 # Handle maindomain
	echo "Adding 127.0.0.1 $NewDomainName www.$NewDomainName to /etc/hosts..."
	echo "127.0.0.1 $NewDomainName www.$NewDomainName" >> /etc/hosts
fi


# Prompt the user before generating the certificate

#read -p "Do you want to install LetsEncrypt Certificates? (yes/no): " install_certificates

if [ "$install_certificates" == "yes" || "$install_certificates" == "y" ]; then

read -p "Have you completed the DNS entry? (yes/no): " dns_completed

if [ "$dns_completed" == "yes" || "$dns_completed" == "y" ]; then
   	if [[ $NewDomainName == *.*.* ]]; then
   	 # Handle subdomains

	 # Generate a certificate for the new domain using certbot
    	sudo certbot --apache --domain $NewDomainName
	#sudo certbot --apache --non-interactive --agree-tos --domain $NewDomainName --domain www.$NewDomainName || { echo "Failed to setup Certbot"; exit 1; }
	# Setup a cron job to auto-renew SSL certificate
	(crontab -l 2>/dev/null; echo "15 3 * * * /usr/bin/certbot renew --quiet") | crontab -
	else
	 # Handle maindomain

         # Generate a certificate for the new domain using certbot
        sudo certbot --apache --domain $NewDomainName --domain www.$NewDomainName
        #sudo certbot --apache --non-interactive --agree-tos --domain $NewDomainName --domain www.$NewDomainName || { echo "Failed to setup Certbot"; exit 1; }
        # Setup a cron job to auto-renew SSL certificate
        (crontab -l 2>/dev/null; echo "15 3 * * * /usr/bin/certbot renew --quiet") | crontab -
   fi
else
    echo "Please run the following command to generate the certificate once the DNS entry is completed:"
    echo "sudo certbot --apache --domain $NewDomainName --domain www.$NewDomainName"
	# Add the renew command to crontab
	echo "(crontab -l 2>/dev/null; echo '# This cron job renews SSL certificates automatically daily at 3:15 AM'; echo '15 3 * * * /usr/bin/certbot renew --quiet') | crontab -"
fi

#sudo certbot --apache --non-interactive --agree-tos --domain $NewDomainName --domain www.$NewDomainName || { echo "Failed to setup Certbot"; exit 1; }

# Setup a cron job to auto-renew SSL certificates
#(crontab -l 2>/dev/null; echo "15 3 * * * /usr/bin/certbot renew --quiet") | crontab -

fi


if [ $ERROR_FLAG -eq 0 ]; then
    echo "WordPress has been set up! Please complete the installation through the web browser."
else
    echo "Setup failed. All changes have been reversed."
fi
