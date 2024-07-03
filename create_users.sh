#!/bin/bash

#Log file and password location
logfile="/var/log/user_management.log"
password_file="/var/secure/user_passwords.csv"
text_file=$1

#check for file input
if [ -z "$text_file" ]
then
echo "Usage is: $0 <name of text file>"
exit 1
fi

#Create Log file and password files
mkdir -p /var/secure
touch $logfile $password_file
chmod 600 $password_file

#function to generate randompasswords
generate_random_password() {
  local length=${1:-10}
  tr -dc 'A-Za-z0-9!?%+=' < /dev/urandom | head -c $length
}

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $text_file" >> $logfile
}

#FUNCTION TO CREATE USER
create_user() {
local username=$1
local groups=$2

if getent passwd "$username" > /dev/null;
then
 log_message "User $username already exists"
else
  useradd -m $username
  log_message "Created  user $username"
fi

#Adding user to groups
groups_array=($(echo $groups | tr "," "\n"))
for group in "${groups_array[@]}";
do
  if ! getent group "$group" > /dev/null; 
then
  groupadd "$group"
  log_message "Group created $group"
  else
  log_message "Group $group already exists"
  fi
  usermod -aG "$group" "$username"
  log_message "Added user $username to group $group"
done

chmod 700 /home/$username
chown $username:$username /home/$username
log_message "Set up home directory for user $username"

#Assigning Random password to users
password=$(generate_random_password 12)
echo "$username:$password" | chpasswd
echo "$username,$password" >> $password_file
log_message "Set password for $username"
}

while IFS=';' read -r username groups;
do
  create_user "$username" "$groups"
  done < "$text_file"

echo "User creation done." | tee -a $logfile
