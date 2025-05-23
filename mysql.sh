#!/bin/bash 

USER_ID=$(id -u)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
SCRIPT_DIR="/var/log/roboshop-logs"
LOG_FILE="$SCRIPT_DIR/$SCRIPT_NAME.log"

if [ $USER_ID -ne 0 ]
then
    echo "Please run the script as root user or admin user."
    exit 1
else
    echo "Running script as root user"
    mkdir -p $SCRIPT_DIR
fi

echo "##########################################" &>> $LOG_FILE
echo "Script Started executing at '"$(date)"'" | tee -a $LOG_FILE
echo "##########################################" &>> $LOG_FILE

VALIDATE () {
    if [ $1 -ne 0 ]
    then
        echo "$2 is failed:: Exiting the Script" | tee -a $LOG_FILE
        exit 1
    else
        echo "$2 is Success" | tee -a $LOG_FILE
    fi
}

mysql -v &>> $LOG_FILE
if [ $? -eq 0 ]
then
    echo "mysql is already installed.. skipping" | tee -a $LOG_FILE
else
    read -s -p "Enter a password for your mysql server:" MYSQL_PASSWORD
    
    dnf install mysql-server -y &>> $LOG_FILE
    VALIDATE $? "Installing mysql-server" 

    systemctl enable mysqld &>> $LOG_FILE
    VALIDATE $? "Enabling mysql-server"

    systemctl start mysqld  
    VALIDATE $? "Starting mysql-server"

    mysql_secure_installation --set-root-pass $MYSQL_PASSWORD &>> $LOG_FILE
    VALIDATE $? "Setting root password for mysql server"
fi