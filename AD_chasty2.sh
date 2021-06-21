#!/bin/bash
#This has been brought to you by Joe Burnitz and Ramon Castillo!!
#Updated by Cody Hasty on 6/2/21

green='\e[0;32m'
blue='\e[0;34m'
endColor='\e[0m'

if [[ $EUID -ne 0 ]]; then
        echo -e "\e[1;31mSudo Required${endColor}"
        exit
fi

debian(){
##############
#begin debian#
##############

apt-get update

apt-get install likewise-open
echo -e "${green}"

domainjoin-cli join "$DOMAIN" "$ADUSERNAME" "$ADPASSWORD"
echo -e "${endColor}"
exit
}

###################
#begin RedHat part#
###################
redhat(){

#OSNAME=$(lsb_release -i -s)
#OSVER=$(lsb_release -s -r)
#
#echo -n "Querying for Domain Controller..."
#
##figure out what the domain controller is
#dc=$(host -t NS $DOMAIN | head -n 1 | awk '{print $4}')
#echo "done!"
#echo "Using $dc for domain controller"

echo -n "Enter the domain workgroup \(i.e ad.example.com is usually just AD\):"
read workgroup

echo -e "${blue}Installing Samba and Winbind${endColor}"
yum install -y samba-winbind samba-winbind-clients oddjob-mkhomedir pam_krb5 krb5-workstation
echo -e"${green}Samba and Winbind complete${endColor}"

echo -e "${blue}Checking oddjobd config${endColor}"
chkconfig oddjobd on
echo -e "${green}oddjobd config complete${endColor}"

#echo -e "${blue}Syncing time with $dc ${endColor}"
#service ntpd stop
#ntpdate $dc
#service ntpd start
#
#echo -e "${green}Sync complete${endColor}"

echo -e "${blue}Binding Server with UIC AD${endColor}"
authconfig --update --kickstart --enablewinbind --enablewinbindauth --enablemkhomedir --smbsecurity=ads --smbworkgroup=$workgroup --smbrealm=$DOMAIN --smbservers=$dc  --winbindtemplatehomedir=/home/AD/%U --winbindtemplateshell=/bin/bash --enablewinbindusedefaultdomain --enablelocauthorize

#net ads join osName="$OSNAME" osVer="$OSVER" -U "$ADUSERNAME%$ADPASSWORD"
net ads join -U "$ADUSERNAME%$ADPASSWORD"
echo -e "{$green}Bind Complete${endColor}"

if p=$(pgrep winbind)
then
echo -e "${blue}Restarting winbind${endColor}"
service winbind restart
echo -e "${green}Winbind restart complete${endColor}"
else
echo -e "${blue}Starting winbind${endColor}"
service winbind start
fi

}
######################
#end red hat specifics
######################

read -p "Enter your full domain name i.e. ad.windows.com: " DOMAIN

read -p "${DOMAIN} account with bind credentials: " ADUSERNAME

read -s -p ""$DOMAIN"\\"$ADUSERNAME" Password: " ADPASSWORD

if command -v apt-get &>/dev/null
        then
                echo -e"\nhas apt-get"
                debian
                exit
        elif command -v yum &>/dev/null
        then
                echo -e "\nhas yum."
                redhat
                exit
        else
                echo "install manually, neither yum or apt found"
                return 0
fi
