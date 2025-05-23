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

dnf module disable nginx -y &>> $LOG_FILE
VALIDATE $? "disabling default nginx"

dnf module enable nginx:1.24 -y &>> $LOG_FILE
VALIDATE $? "disabling nginx version 1.24"

dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Installing Nginx"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading source code"

cd /usr/share/nginx/html
rm -rf *
unzip /tmp/frontend &>> $LOG_FILE
rm -rf /tmp/frontend
VALIDATE $? "deploying source code"

systemctl enable nginx &>> $LOG_FILE
VALIDATE $? "Enabling Nginx"

systemctl start nginx
VALIDATE $? "Starting Nginx"

cp $SCRIPT_PATH/nginx.conf /etc/nginx/nginx.conf 
VALIDATE $? "Updating Nginx configuration file"

systemctl restart nginx
VALIDATE $? "restarting Nginx"