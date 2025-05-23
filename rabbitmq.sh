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

rabbitmqctl version &>> $LOG_FILE
if [ $? -eq 0 ]
then
    echo "rabbitmq is already installed.. skipping"
    exit 1
else
    read -s -p "enter a password for rabbitmq roboshop user:" RABBITMQ_PASSWORD
    echo ""

    cp ./rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
    VALIDATE $? "creating rabbitmq repo"

    dnf install rabbitmq-server -y &>> $LOG_FILE
    VALIDATE $? "installing rabbitmq"

    systemctl enable rabbitmq-server &>> $LOG_FILE
    VALIDATE $? "enabling rabbitmq"

    systemctl start rabbitmq-server
    VALIDATE $? "starting rabbitmq"

    rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD &>> $LOG_FILE
    VALIDATE $? "adding user to rabbitmq server"

    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
    VALIDATE $? "setting permissions to user"
fi
