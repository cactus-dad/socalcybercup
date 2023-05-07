#!/bin/bash

while true; do
    user_list=""
    user_list=$(cut -d ':' -f 1 /etc/passwd) 
    # Run every ten seconds
    echo "Checking /etc/passwd"
    sleep 10
    new_user_list=""
    new_user_list=$(cut -d ':' -f 1 /etc/passwd)
    
    for new_user in $new_user_list; do
        if ! grep -q "$new_user" <<< "$user_list"; then
            echo "New user $new_user found!"
            read -p "Would you like to delete this user (y/n)? " decision
            # Change to lowercase
            decision="${decision,,}"
            
            if [[ "$decision" == "y" ]]; then
                sudo deluser "$new_user"
                echo "User $new_user has been deleted!"
            else
                echo "No user deleted."
            fi
        fi
    done
done
