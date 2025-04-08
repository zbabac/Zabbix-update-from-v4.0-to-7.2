# Zabbix-update-from-v4.0-to-7.2

## A little background info.  
While looking for useful hints on the Internet to upgrade our old Zabbix infrastructure monitoring server to the new version (with new features), I realized that there are no detailed instructions how to do it.  
Furthermore, no one has done specifically update from rather old v4.0 to 7.2. While I found general path how to update from any version, I decided to document it, together with SQL script that helps to shorten the update task.   
This script, ***sql-fix.sql***, is specifically for update from v4.0 DB to the v7.2. I have no idea if it is going to fullfill the requirements of upgrading from other Zabbix versions.

General assumption is that you DON'T perform upgrade from Zabbix 4.0 to Zabbix 7.2, as it involves upgrading Linux (in my case Centos 7) and there are many unknowns that can go wrong.  

What I did, and what most of the people recommend, was to install new Zabbix Server VM (this time Debian 12), then export zabbix DB from the old one and import it into the new zabbix DB.  

After migration, I changed DNS of the new Zabbix URL to match the old one, and all connected clients (around 300 of them) would instantly be connected with Zabbix. I would also have all Hosts, Templates (I have around 100 custom templates that are critical to monitoring), Users, Groups, etc.   
The old and new Zabbix are in the same VLAN, so changing DNS with new IP and achieving connectivity was trivial.  

### Zabbix feature for automatic DB version upgrade
There is nice feature of zabbix-server that after starting the service, if it detects old DB, it performs zabbix DB upgrade (tables, indexes, the whole structure is recreated). If you are upgrading from Zabbix v6.x then it will work seamlessly, but with older versions, there are DB structure differencies that require manual adjustments (deletion of some tables, creation of new ones, etc.).   
You can either take my script and do it in a single run, or start zabbix-server service multiple times, tail output from *zabbix-server.log* and follow hints there.

## Update manual
The general path for update is the following:
1. Install new VM (Debian 12 with Apache, or some other combination of OS and web server), described here: https://www.zabbix.com/download?zabbix=7.2&os_distribution=debian&os_version=12&components=server_frontend_agent&db=mysql&ws=apache or read also very good article here: https://bestmonitoringtools.com/how-to-install-zabbix-server-on-debian/
2. Setup Apache with SSL (self-signed cert or letsencrypt or your own cert)
3. Check that your Zabbix is running at *https://<your_ip>/zabbix*
4. Now perform export from your old Zabbix 4.0:  
   We will do SQL dump without history tables. It is faster, and in case of errors, you will be able to correct that quickly and continue. If you import history at the same time, every script will last minutes, if not hours!  
   First, SQL dump zabbix db:
  ```
  mysqldump -u root -p  --ignore-table=zabbix.history --ignore-table=zabbix.history_uint --ignore-table=zabbix.history_text --ignore-table=zabbix.history_log --ignore-table=zabbix.history_str --ignore-table=zabbix.trends --ignore-      table=zabbix.trends_uint --ignore-table=zabbix.acknowledges --ignore-table=zabbix.alerts --ignore-table=zabbix.auditlog --ignore-table=zabbix.auditlog_details --ignore-table=zabbix.escalations --ignore-table=zabbix.events zabbix >> /home/zabbix/old_zabbix_backup.sql
  ```  

5.   Copy **old_zabbix_backup.sql** to the new zabbix server, e.g. in *<new_zabbix>:/home/zabbix/*
6. On destination stop new zabbix-server instance:  
    `systemctl stop zabbix-server`  
7. Login to mysql as root and first drop then create zabbix DB:
    `mysql -u root -p`  
    `DROP DATABASE zabbix;`  
    `CREATE DATABASE zabbix;`  
8. While still in mysql prompt, give user zabbix required privileges, but also extra privileges required to import and change DB structure.
   You will at the end revoke some of them, but for now we need them.  
    `grant all privileges on zabbix.* to zabbix@localhost;`  
    `set global log_bin_trust_function_creators = 1;`  
    `GRANT SUPER ON *.* TO zabbix@'localhost'`  
    `FLUSH PRIVILEGES;`  
9. Go back to bash and edit /etc/mysql/my.cnf by adding it in the server section
    `[mysqld]`  
     `innodb_log_file_size = 512M`  
     `innodb_strict_mode = 0`  
      Restart MariaDB:  
     `systemctl restart mysqld`  
10. Import copied sqldump into the new zabbix DB  
      `mysql -u zabbix -p zabbix < old_zabbix_backup.sql`  
11. Now try to start zabbix server and check the log:  
      `systemctl start zabbix-server `  
      `tail -n 50 /var/log/zabbix/zabbix_server.log`  
    
    There are errors. In case of zabbix DB v.4 it looks like this:
    
    `36520:20250403:145043.684 ***database upgrade failed on patch 04030052***, exiting in 10 seconds`  
    ```
     36554:20250403:145539.725 SSH support:               YES
     36554:20250403:145539.725 IPv6 support:              YES
     36554:20250403:145539.725 TLS support:               YES
     36554:20250403:145539.725 ******************************
     36554:20250403:145539.725 using configuration file: /etc/zabbix/zabbix_server.conf
     36554:20250403:145539.729 current database version (mandatory/optional): 04030051/04030051
     36554:20250403:145539.729 required mandatory version: 07020000
     36554:20250403:145539.729 mandatory patches were found
     36554:20250403:145540.264 [Z3005] query failed: [1146] Table 'zabbix.auditlog' doesn't exist [alter table `auditlog` change column `details` `note` varchar(128) default '0' not null]
     36554:20250403:145540.264 database upgrade failed on patch 04050036, exiting in 10 seconds 
    ```
    The log clearly states that table 'zabbix.auditlog' doesn't exist, so we should create it.
    That is what I originally did: I followed these hints, created table, started zabbix-server and checked the log again.
    Then I created, or deleted some table/index, and every time the patch number mentioned above (04030052) increased slightly.  

    You don't have to do it manually, you will run the fix script that will do it automatically in the next step.
    But first, stop zabbix server:  
    `systemctl stop zabbix-server.service`  

12. Use **sql-fix.sql** script to skip all these manual tweaking and create and drop all neccessary tables/indexes in order to update from Zabbix DB structure of 4.0 to the structure of Zabbix DB 6.0.  
      
      `mysql -u zabbix -p zabbix < sql-fix.sql`  

      Now, start zabbix server and check the log again:  
      `systemctl start zabbix-server`  
      `tail -n 50 /var/log/zabbix/zabbix_server.log`  
      The log should look like this, without DB upgrade error message:  
    ```
      38027:20250403:155114.317 SMTP authentication:       YES
      38027:20250403:155114.317 ODBC:                      YES
      38027:20250403:155114.317 SSH support:               YES
      38027:20250403:155114.317 IPv6 support:              YES
      38027:20250403:155114.317 TLS support:               YES
      38027:20250403:155114.317 ******************************
      38027:20250403:155114.317 using configuration file: /etc/zabbix/zabbix_server.conf
      38027:20250403:155114.322 current database version (mandatory/optional): 06050008/06050008
      38027:20250403:155114.322 required mandatory version: 07020000
      38027:20250403:155114.322 mandatory patches were found```   
13. Login again to Zabbix web GUI and check if your Users, Templates, Hosts, etc. are there.
14. If everything ok, then remove extra privileges of Zabbix user in mysql:  
     `revoke SUPER ON *.* from zabbix@'localhost';`  
     `set global log_bin_trust_function_creators = 1;`  

     And that's it! If you encountered some errors, please check **/var/log/zabbix/zabbix_server.log** for DB upgrade errors and correct manually.  

     I hope that this manual can help you to migrate your data from old Zabbix version to the new one!
      
      
