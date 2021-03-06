# Spider Test with High Availability

## Step 1) Start the docker containers using the democtl script located in the MariaDB_examples folder.

In the installation directory execute the democtl script

```ksh
./democtl -s mdbtx -d spider_ha -a [ start | stop ]
```

## Step 2) Testing Layout

Use the following layout to for the test.

![Layout](https://github.com/ainfanzon/MariaDB_examples/blob/master/mdbtx/spider_ha/Topology.jpg)

## Step 3) Enable the Spider storage engine

Installing the spider storage engine is simple. Type the following command in the Spider node, in this case mdbsrv1.
Use the mariadb (mysql) command line interface.

```SQL
SOURCE /usr/share/mysql/install_spider.sql;
SHOW ENGINES;
```
## Step 4) Create the spider servers

At launch time the __spider_head.sql__ is executed. The script:
  
* Creates the __backend__ database
* Creates the spider users sp_user and spider
* Grants privileges to sp_user and spider
* Creates the servers used by spider

To verify the servers were created. Execute the following command in the __mariadb__ command line client:

```SQL
\! clear
SELECT Server_name, Host, Db, Port FROM mysql.servers\G
```

## Step 5) Spider user connectivity

Verify the spider user can connect from the spider node to ALL the backend nodes. In the Spider NODE window execute:

```SQL
\! clear
system  mysql -u sp_user -pletmein -h 172.20.0.2 -e 'SELECT @@hostname'
system  mysql -u sp_user -pletmein -h 172.20.0.3 -e 'SELECT @@hostname'
system  mysql -u sp_user -pletmein -h 172.20.0.4 -e 'SELECT @@hostname'
system  mysql -u sp_user -pletmein -h 172.20.0.5 -e 'SELECT @@hostname'
```

## Step 6) Backend tables

After executing the __spider_node.sql__, the backend tables should have been created on each one of the backend servers.  You can check by executing the following SQL statements on each backend node.

```SQL
SHOW TABLES FROM backend;
SHOW TABLES FROM backend_rpl;
SHOW CREATE TABLE sbtest\G
```

## Step 7) Use case 1: Sharding test without HA

The goal is to demonstrate what happens when querying a sharded table and high availability is not enabled. 

\! clear
 system cat /mdb/mdbtx/spider_ha/cr_sharding_no_ha.sql

# SHOW THE CURRENT VALUES

 SOURCE /mdb/mdbtx/spider_ha/cr_sharding_no_ha.sql
 INSERT INTO backend.sbtest select 10000001, 0, '' ,'replicas test';

 SELECT * FROM sbtest WHERE id=10000001;

# ON ALL SPIDER NODES

 \! clear
 SELECT * FROM backend.sbtest;
 SELECT * FROM backend_rpl.sbtest;

# ON ANY SPIDER NODE: What is happening if we stop one backend?

 SHUTDOWN;

# ON THE SPIDER HEAD NODE

 \! clear
 SELECT * FROM sbtest WHERE id=10000001;

ERROR 1429 (HY000): Unable to connect to foreign data source: backend1_rpl

# EXECUTE NEXT COMMAND ON THE SERVER THAT IS DOWN
  
 \! systemctl start mariadb
 \! clear

===============================================================================
8) Use Case 2: Sharding with HA
Let's fix this with spider monitoring.

COMMANDS
========

# ON THE SPIDER HEAD NODE

 \! clear 
 \! cat /mdb/mdbtx/spider_ha/cr_sharding_ha.sql

 \! clear
 SOURCE /mdb/mdbtx/spider_ha/cr_sharding_ha.sql

# NOTE: THIS STEP SHOWS WHAT HAPPENDS WHEN STARTING MONITORING - NOT NEEDED IN PRODUCTION

 \! clear
 SELECT * FROM backend.sbtest WHERE id=10000001;
 SELECT spider_flush_table_mon_cache();

 SELECT db_name, table_name, server, link_status FROM mysql.spider_tables;

# EXECUTE NEXT COMMAND ON THE SERVER THAT IS DOWN
  
 \! systemctl start mariadb

# ON THE HEAD NODE

 \! clear
 \! cat /mdb/mdbtx/spider_ha/recover.sql

 SOURCE /mdb/mdbtx/spider_ha/recover.sql
 SELECT db_name, table_name, server, link_status FROM mysql.spider_tables;

 INSERT INTO backend.sbtest select 10000003, 0, '' ,'replicas test';

# ON THE SPIDER NODES

 \! clear
 SELECT * FROM backend.sbtest;
 SELECT * FROM backend_rpl.sbtest;

# ON ANY SPIDER NODE;

  SHUTDOWN;

 \! clear
 SELECT * FROM backend.sbtest;
 SELECT * FROM backend_rpl.sbtest;

# ON THE HEAD NODE

 SELECT * FROM backend.sbtest;

# ON THE NODE THAT IS DOWN

 \! systemctl start mariadb

===============================================================================
===============================================================================

ON THIS WINDOW 

 /Users/Shared/mdbtx/spider_ha/setup.sh

===============================================================================
===============================================================================
9) Use case 2: sharding by Range

COMMANDS
========

# ON THE SPIDER NODES:

 SHOW TABLES;

# ON THE SPIDER HEAD NODE:

 \! clear
 \! cat /mdb/mdbtx/spider_ha/cr_byRange.sql

 SOURCE /mdb/mdbtx/spider_ha/cr_byRange.sql
 \! /mdb/mdbtx/spider_ha/ld_opportunities.sh;

 SELECT * FROM backend.opportunities;

# ON EACH SPIDER NODE

 \! clear
 SELECT COUNT(*) FROM backend.opportunities;

 \! clear
 SELECT id, accountName, name, amount FROM backend.opportunities ORDER BY accountName;

===============================================================================
10) Use case 3: sharding by List

COMMANDS
========

# ON THE SPIDER HEAD NODE:

 \! clear
 \! /mdb/mdbtx/spider_ha/cleanup.sh
 \! cat /mdb/mdbtx/spider_ha/cr_byList.sql

 SOURCE /mdb/mdbtx/spider_ha/cr_byList.sql
 \! /mdb/mdbtx/spider_ha/ld_opportunities.sh;

 SELECT * FROM backend.opportunities;

# ON EACH SPIDER NODE

 \! clear
 SELECT COUNT(*) FROM backend.opportunities;

 \! clear
 SELECT id, owner, name, amount FROM backend.opportunities ORDER BY owner;

