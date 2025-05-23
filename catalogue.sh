#!/bin/bash 

USER_ID=$(id -u)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_DIR="/var/log/roboshop-logs"
LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"
SCRIPT_PATH=$PWD

if [ $USER_ID -ne 0 ]
then
    echo "Please run the script as root user or admin user."
    exit 1
else
    echo "Running script as root user"
    mkdir -p $LOG_DIR
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

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "enabling nodejs version 20"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>> /dev/null
if [ $? -eq 0 ]
then
    echo "user already exists skipping"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "adding roboshop system user"
fi

mkdir -p /app 
VALIDATE $? "Creating directory for application"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading source code"

cd /app 
rm -rf *
unzip /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "deploying source code"
rm -rf /tmp/catalogue.zip

npm install &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_PATH/catalogue.service /etc/systemd/system/catalogue.service 
VALIDATE $? "creating mongodb repo file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "reloading systemctl service"

systemctl enable catalogue &>> $LOG_FILE
VALIDATE $? "enabling caltalogue service"

systemctl start catalogue
VALIDATE $? "starting caltalogue service"

cp $SCRIPT_PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "creating mongodb repo file"

dnf install mongodb-mongosh -y &>> $LOG_FILE
VALIDATE $? "installing mongodb client"

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.jayachandrarapolu.site </app/db/master-data.js &>> $LOG_FILE
    VALIDATE $? "loading data to db."
else
    echo "db already exists"
fi