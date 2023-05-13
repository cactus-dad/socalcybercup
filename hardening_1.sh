#!/bin/bash

# create new administrator user
# script must be run as sudo
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
if [ $EUID -ne 0 ]; then
    echo -e  "${RED}This script needs to be run as sudo${NC}"
    exit 1
fi

flag=0
while [ "$flag" -eq 0 ]; do
    read -p "Enter new administrative user to create: " new_admin
    current_user_list=$(cut -d ':' -f 1 /etc/passwd)
    if grep -q "$new_admin" <<< "$current_user_list"; then
        echo -e  "${RED}[-] User $new_admin is already a current user${NC}"
        read -p "Would you like to delete $new_admin (y/n)? " decision
        decision="${decision,,}"
        if [[ "$decision" == "y" ]]; then
            deluser "$new_admin"
            echo -e  "${BLUE}[+] User $new_admin has been deleted${NC}"
            
        else 
            echo -e "${RED} Invalid choice. try again ${NC}"
            
        fi
    else
        adduser "$new_admin"
        
        usermod -s /bin/bash -aG sudo "$new_admin"
        echo -e "${BLUE}[+] $new_admin created with /bin/bash shell and sudoer permissions${NC}"
        flag=1
    fi
done
#refresh current user list
current_user_list=$(cut -d ':' -f 1 /etc/passwd)
if grep -qe "^root" <<< "$current_user_list"; then
    echo -e  "${RED}[-] root account exists, setting shell to /bin/false${NC}"
    usermod -s /bin/false root
    echo -e  "${BLUE}[+] New root shell: ${NC}"
    cat /etc/passwd | cut -d ':' -f 1,7 | grep -e "^root"

else 
    echo -e "${BLUE}[+] root account does not exist${NC}"
fi



#ssh hardening steps
# First backup sshd config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.original
echo -e  "${BLUE}[+] sshd_config backed up to sshd_config.original${NC}"

# Manipulate PermitRootLogin
awk '/#PermitRootLogin/ { print "PermitRootLogin no"; next } /^PermitRootLogin yes/ { print "PermitRootLogin no"; next } { print }' /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp
mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
echo -e "${BLUE}[+] PermitRootLogin set to no${NC}"
# Enable PubKey authentication
awk '/^#PubkeyAuthentication/ { print "PubkeyAuthentication yes"; next } /^PubkeyAuthentication/ { print "PubkeyAuthentication yes"; next } { print }' /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp
echo -e "${BLUE}[+] PubkeyAuthentication set to yes${NC}"
mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
echo -e "${BLUE}[+] Restarting ssh sercices...${NC}"

systemctl restart ssh
systemctl restart sshd
