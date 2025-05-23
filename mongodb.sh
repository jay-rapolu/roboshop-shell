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

mongod --version
if [ $? -eq 0 ]
then
    echo "mongodb is already installed in the server:: skipping"
else
    cp ./mongo.repo /etc/yum.repos.d/mongo.repo
    VALIDATE $? "Creating mongodb repo file"

    dnf install mongodb-org -y &>> $LOG_FILE
    VALIDATE $? "Installing Mongodb"

    systemctl enable mongod &>> $LOG_FILE
    VALIDATE $? "Enabling Mongodb"

    systemctl start mongod 
    VALIDATE $? "Starting Mongodb" 

    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
    VALIDATE $? "Allowing remote connections" 

    systemctl restart mongod
    VALIDATE $? "Restarting Mongodb" 
fi