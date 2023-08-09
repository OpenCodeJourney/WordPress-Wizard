## **WordPress Wizard: One-Click Automated Installation & Configuration**

Deploying WordPress shouldn't be a hassle. Introducing **WordPress Wizard**, the definitive one-click solution for fast and hassle-free WordPress installations. Our tool optimizes the process from start to finish, integrating essential tasks into a streamlined flow.

## **Why Choose WordPress Wizard?**

In today's digital era, speed and efficiency are paramount. WordPress Wizard is meticulously crafted to cater to developers, bloggers, and digital agencies who crave an uncomplicated, rapid, and reliable WordPress deployment solution. Dive into the future of WordPress installations.

---

### 🌟 **Features**

- 🚀 **Instant WordPress Deployments**: Download, unpack, and get the latest WordPress version live in seconds.
- 🛡️ **Secure Database Creation**: Automated MySQL setups, custom-tailored for each unique domain.
- 🌐 **Universal Apache Compatibility**: Out-of-the-box virtual host configurations, perfect for all domain types.
- 🔒 **SSL Simplified**: Direct Certbot integrations, offering immediate SSL certificate provisioning for robust site security.
- 🎯 **Beginner Friendly**: You don’t need to be a tech guru to deploy WordPress. We made it simple!

---

### 📜 **Prerequisites for `wp-wizard` Setup**



Ensure your server meets the following requirements before executing the `wp-wizard` script:

1. **CentOS/RedHat OS**
   
2. **Apache Server**

   Installation:
   ```bash
   sudo yum install httpd
   sudo systemctl enable httpd
   sudo systemctl start httpd
   ```

3. **MySQL Database**

   Installation:
   ```bash
   sudo yum install mariadb-server mariadb
   sudo systemctl enable mariadb
   sudo systemctl start mariadb
   mysql_secure_installation
   ```

4. **Certbot (for SSL certificates)**

   Installation:
   ```bash
   sudo yum install epel-release
   sudo yum install certbot python3-certbot-apache
   ```

5. **wget, curl, and unzip utilities**

   Installation:
   ```bash
   sudo yum install wget curl unzip
   ```

6. **PHP and Relevant Extensions**

   Installation:
   ```bash
   sudo yum install php php-mysql php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl-devel
   sudo systemctl restart httpd
   ```
---

Note:
This guide assumes a fresh CentOS/RedHat setup, so adjustments might be necessary if other software or configurations already exist on the server.

---

### Firewalld Configuration for `wp-wizard`

**1. Install and Enable `firewalld` if not installed by default:**

```bash
sudo yum install firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
```

**2. Enable necessary services and ports:**

a. **HTTP and HTTPS:**
Allowing HTTP and HTTPS is essential for web access and Let's Encrypt Certificate Setup:

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
```

b. **MySQL: (Optional)**
If you're planning to allow remote access to MySQL, then you'd want to allow the MySQL port (Usually, it's better to keep this closed and only open it temporarily when necessary):

```bash
sudo firewall-cmd --permanent --add-service=mysql
```

**3. Reload `firewalld` to apply the changes:**

```bash
sudo firewall-cmd --reload
```

**4. (Optional) Check the active zones and services:**

To verify your configurations:

```bash
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
```

---

Note: 
This guide assumes a fresh CentOS/RedHat setup, so adjustments might be necessary if other software or configurations already exist on the server. Always be cautious when configuring your firewall. Only open the ports and services you absolutely need to prevent unnecessary exposure to potential security threats. If your server is hosting multiple services, adjust the firewall rules accordingly.

---


### 🚀 **Installation**

1. Clone this repository:
```bash
git clone https://github.com/OpenCodeJourney/WordPress-Wizard.git
```

2. Navigate to the directory:
```bash
cd WordPress-Wizard
```

3. Make the script executable:
```bash
chmod +x wp-wizard.sh
```

---

### 💼 **Usage**

Execute the script and provide your domain name:

```bash
./wp-wizard.sh YourDomainName.com
```

Follow the on-screen prompts and within a few minutes, your WordPress site will be up and running!

---

### 🔄 **Reversing the Setup**

If you wish to undo the setup, you can run the reversal script:

```bash
./wp-wizard-reverse.sh YourDomainName.com
```

This script will remove all configurations and installations done by the main script.

---

### 💬 **Feedback and Contributions**

Feel free to submit issues or pull requests, we appreciate all contributions from the community!

---

### 📝 **License**

This project is licensed under the GNU GPL License. See the `LICENSE.md` file for details.

---

### 📣 **Acknowledgements**

- [WordPress](https://wordpress.org/)
- [Apache](https://httpd.apache.org/)
- [MySQL](https://www.mysql.com/)
- [Certbot](https://certbot.eff.org/)

---
