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

dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "Disabling default redis module"
dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? "Enabling default redis module"
dnf install redis -y &>> $LOG_FILE
VALIDATE $? "Installing redis module"
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected mode/ c protected-mode no/' /etc/redis/redis.conf
VALIDATE $? "updating redis configuration"
systemctl enable redis &>> $LOG_FILE
VALIDATE $? "enabling redis module"
systemctl start redis 
VALIDATE $? "starting redis module"