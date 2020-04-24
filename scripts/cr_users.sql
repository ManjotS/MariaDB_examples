CREATE USER 'repuser'@'%' IDENTIFIED BY 'letmein';
GRANT ALL PRIVILEGES ON *.* TO 'repuser'@'%' WITH GRANT OPTION;
CREATE USER 'maxuser'@'%' IDENTIFIED BY 'letmein';
GRANT ALL PRIVILEGES ON *.* TO 'maxuser'@'%' WITH GRANT OPTION;
CREATE USER 'mdb'@'%' IDENTIFIED BY 'letmein';
GRANT ALL PRIVILEGES ON *.* TO 'mdb'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;