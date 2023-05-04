ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by 'my-secret-password';
CREATE USER 'user'@'host' IDENTIFIED WITH mysql_native_password by 'my-secret-password';
GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'user'@'host' WITH GRANT OPTION;
FLUSH PRIVILEGES;