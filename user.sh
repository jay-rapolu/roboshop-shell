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

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading source code"

cd /app 
rm -rf *
unzip /tmp/user.zip &>> $LOG_FILE
VALIDATE $? "deploying source code"
rm -rf /tmp/user.zip

npm install &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_PATH/user.service /etc/systemd/system/user.service 
VALIDATE $? "creating user service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "reloading systemctl service"

systemctl enable user &>> $LOG_FILE
VALIDATE $? "enabling user service"

systemctl start user
VALIDATE $? "starting user service"

