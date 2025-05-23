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

read -s -p "enter mysql root password" MSQL_ROOT_PASSWORD
dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing maven"

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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading source code"

cd /app 
rm -rf *
unzip /tmp/shipping.zip &>> $LOG_FILE
VALIDATE $? "deploying source code"
rm -rf /tmp/shipping.zip

mvn clean package &>> $LOG_FILE
mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Building source code"

cp $SCRIPT_PATH/shipping.service /etc/systemd/system/shipping.service 
VALIDATE $? "creating shipping service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "reloading systemctl service"

systemctl enable shipping &>> $LOG_FILE
VALIDATE $? "enabling shipping service"

systemctl start shipping
VALIDATE $? "starting shipping service"

dnf install mysql -y 
VALIDATE $? "Installing mysql client"

mysql -h mysql.jayachandrarapolu.site -u root -p$MSQL_ROOT_PASSWORD -e 'use cities' &>> $LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.jayachandrarapolu.site -uroot -p$MSQL_ROOT_PASSWORD < /app/db/schema.sql
    mysql -h mysql.jayachandrarapolu.site -uroot -p$MSQL_ROOT_PASSWORD < /app/db/app-user.sql
    mysql -h mysql.jayachandrarapolu.site -uroot -p$MSQL_ROOT_PASSWORD < /app/db/master-data.sql
else
    echo "db already exists skipping"
fi