#!/bin/bash
# CentOS 6 Config Tool
# by Michael Stine, 2017
 

###########################################################
# VM CLONE SYSPREP
function vmprep {
  printf "#################################################\n"
  printf "VM Clone Sysprep\n\n"
  rm -fv /etc/udev/rules.d/70-persistent-net.rules
  printf "SUCCESS\n\n"
  sleep 2
}

###########################################################
# Set Hostname
# New hostname passed in as $1
# if line in network file contains '*hostname=*', replace line with new value
# else append hostname to end of network file
function hostname_set {
  printf "#################################################\n"
  printf "SETTING HOSTNAME to $1\n\n"

  if grep -q "HOSTNAME=" "/etc/sysconfig/network"; then
    sed -i "s/.*HOSTNAME=.*/HOSTNAME=$1/" /etc/sysconfig/network
  else
    printf "HOSTNAME=$1" >> /etc/sysconfig/network
  fi

  printf "SUCCESS\n"
  sleep 2
}

###########################################################
# Set Hostname
# if line in selinux file contains '*hostname=someletter*', replace line with new value
function selinux_disabled {
  printf "#################################################\n"
  printf "DISABLING SELINUX\n\n"
  #setenforce 0
  sed -i "s/.*SELINUX=\w.*/SELINUX=disabled/" /etc/selinux/config
  printf "SUCCESS\n\n"
  sleep 2
}

function selinux_enforcing {
  printf "#################################################\n"
  printf "ENABLING SELINUX (REBOOT REQUIRED)\n\n"
  #setenforce 1
  sed -i "s/.*SELINUX=\w.*/SELINUX=enforcing/" /etc/selinux/config
  printf "SUCCESS\n\n"
  sleep 2
}

function selinux_permissive {
  printf "#################################################\n"
  printf "PERMISSIVE SELINUX (REBOOT REQUIRED)\n\n"
  #setenforce 0
  sed -i "s/.*SELINUX=\w.*/SELINUX=permissive/" /etc/selinux/config
  printf "SUCCESS\n\n"
  sleep 2
}

###########################################################
# Set IPTables

function iptables_disable {
  printf "#################################################\n"
  printf "DISABLING IPTABLES\n\n"
  service iptables save
  service iptables stop
  chkconfig iptables off
  service ip6tables save
  service ip6tables stop
  chkconfig ip6tables off

  service iptables status
  service ip6tables status
  printf "\n\n"
  sleep 2
}

function iptables_enable {
  printf "#################################################\n"
  printf "ENABLING IPTABLES\n\n"
  service iptables save
  service iptables restart
  chkconfig --level 345 iptables on
  service iptables save
  service ip6tables restart
  chkconfig --level 345 ip6tables on

  service iptables status
  service ip6tables status
  printf "\n\n"
  sleep 2
}

function iptables_flush {
  printf "#################################################\n"
  printf "FLUSHING IPTABLES\n\n"
  /sbin/iptables --flush
  /sbin/iptables --table nat --flush
  /sbin/iptables --table mangle --flush
  /sbin/iptables --zero
  /sbin/iptables --table nat --zero
  /sbin/iptables --table mangle --zero
  /sbin/iptables --delete-chain
  /sbin/iptables --table nat --delete-chain
  /sbin/iptables --table mangle --delete-chain
  /sbin/iptables --policy input ACCEPT
  /sbin/iptables --policy FORWARD ACCEPT
  /sbin/iptables --policy OUTPUT ACCEPT
  service iptables save
  printf "\n\n"
  sleep 2
}
###########################################################
# NETWORK
function network_dhcp {
  printf "#################################################\n"
  printf "ETH0 to DHCP\n\n"

  local eth0="/etc/sysconfig/network-scripts/ifcfg-eth0"
  
  # backup network config
  #cp "$eth0" "bak.${eth0}.$(date +"%Y%m%d-%H%M%S")" 

  # get mac address
  local mac="$(cat /sys/class/net/eth0/address)"
  #sed -i -e 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth0
  #sed -i -e 's/NM_CONTROLLED=yes/NM_CONTROLLED=no/g' /etc/sysconfig/network-scripts/ifcfg-eth0
cat > $eth0 <<EOF
DEVICE=eth0
HWADDR=$mac
TYPE=Ethernet
BOOTPROTO=dhcp
ONBOOT=YES  
NM_CONTROLLED=no
USERCTL=no
EOF

  service network restart
  printf "\n\n"
  sleep 2
}

function network_static {
  printf "#################################################\n"
  printf "ETH0 to STATIC\n\n"

  local input_network_name="$1"
  local choice_network_ipaddr="$2"
  local choice_network_broadcast="$3"
  local choice_network_netmask="$4"
  local choice_network_gateway="$5"
  local choice_network_dns1="$6"
  local choice_network_dns1="$7"
  local eth0="/etc/sysconfig/network-scripts/ifcfg-eth0"
  local mac="$(cat /sys/class/net/eth0/address)"
cat > $eth0 <<EOF
DEVICE=eth0
HWADDR=$(cat /sys/class/net/eth0/address)
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
USERCTL=no
BOOTPROTO=static
NAME=$input_network_name
IPADDR=$choice_network_ipaddr
BROADCAST=$choice_network_broadcast
NETMASK=$choice_network_netmask
GATEWAY=$choice_network_gateway
DNS1=$choice_network_dns1
DNS2=$choice_network_dns1
EOF

  service network restart
  printf "\n\n"
  sleep 2
}

###########################################################
# GLOBAL ALIASES
function global_aliases {
printf "#################################################\n"
printf "CREATING /etc/profile.d/global_aliases.sh\n\n"

cat << EOF > /etc/profile.d/global_aliases.sh
#!/bin/bash
alias vi='vim'
alias vieth0='vim /etc/sysconfig/network-scripts/ifcfg-eth0'
alias vieth1='vim /etc/sysconfig/network-scripts/ifcfg-eth1'
EOF

  chmod 644 /etc/profile.d/global_aliases.sh

  printf "SUCCESS\n\n"
  sleep 2
}

###########################################################
# YUM INSTALLS
function yum_install {
  #installs, updates itself and dependencies, upgrade removes obselete dependencies
  yum -y install "$1" && yum -y update "$1" && yum -y upgrade "$1"
}


function install_essentials {
  printf "#################################################\n"
  printf "YUM Installing Essentials: kernel-headers kernel-devel man vim rsync traceroute nmap telnet tcpdump\n\n"
  yum_install "kernel-headers kernel-devel man vim rsync traceroute nmap telnet tcpdump"
  printf "\n\n"
  sleep 2
}

function install_c_compiler {
  printf "#################################################\n"
  printf "YUM Installing C Compiler: gcc make\n\n"
  yum_install "gcc make"
  printf "\n\n"
  sleep 2
}

function install_perl {
  printf "#################################################\n"
  printf "YUM Installing Perl: perl\n\n"
  yum_install "perl"
  printf "\n\n"
  sleep 2
}

function install_network_tools {
  printf "#################################################\n"
  printf "YUM Network Tools: net-tools links wget lsof iotop iptraf psacct nc\n\n"
  yum_install "net-tools links wget lsof iotop iptraf psacct nc"
  printf "\n\n"
  sleep 2
}
 
function upgrade_os {
  printf "#################################################\n"
  printf "YUM UPGRADING OS"
  yum -y update && yum -y upgrade
  printf "\n\n"
  sleep 2
}

###########################################################
# SETUP SSH
function ssh_enable {
  printf "#################################################\n"
  printf "ENABLING SSH on port: $1"
  yum -y install openssh-server
  yum -y update openssh-server && yum -y upgrade openssh-server
  sed -i "s/.*Port .*/Port $1/" /etc/ssh/sshd_config
  service sshd restart
  service sshd status
  chkconfig sshd on
  printf "\n\n"
  sleep 2
}
 
function ssh_disable {
  printf "#################################################\n"
  printf "DISABLING SSH"
  service sshd stop
  service sshd status
  chkconfig sshd off
  printf "\n\n"
  sleep 2
}



###########################################################
# NTP
function ntp_enable {
  printf "#################################################\n"
  printf "Enabling NTP: $1\n\n"
  yum_install "ntp ntpdate ntp-doc"
  chkconfig ntpd on
  ntpdate "$1"
  service ntpd start

  #check status
  ntpstat 
  printf "\n"
  if [ "$?" -eq "0" ]; then
    printf "NTP Clock is synchronised"
  elif [ "$?" -eq "1" ]; then
    printf "NTP ERROR!!!! Clock is not synchronised"
  elif [ "$?" -eq "2" ]; then
    printf "NTP ERROR!!!! Clock state is indeterminant, ntpd not contactable."
  fi
  printf "\n\n"
  sleep 2
}

function ntp_disable {
  printf "#################################################\n"
  printf "Disabling NTP\n\n"
  service ntpd stop
  chkconfig ntpd off
  printf "\n\n"
  sleep 2
}

###########################################################
# REBOOT 
function reboot_machine {
  printf "#################################################\n"
  printf "Rebooting in...\n\n"
  printf "5\n"; sleep 1
  printf "4\n"; sleep 1
  printf "3\n"; sleep 1
  printf "2\n"; sleep 1
  printf "1\n"; sleep 1
  printf "Goodnight Papa\n"; sleep 1
  shutdown -r now
}

###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
# MAIN FUNCTION

function main {
  #set -o xtrace
  local reboot_required=""

  printf "###########################################################\n"
  printf "Welcome to CentOS 6 Config Tool\n"
  printf "by Michael Stine, 2017\n\n"
  sleep .75

  printf "###########################################################\n"
  # VM Clone Sys Prep
  local ask_vmprep=""
  read -p "Is this a VM Clone or will be Cloned [y/n]? " -n 1 -r ask_vmprep; printf "\n\n"

  printf "###########################################################\n"
  # Hostname
  local change_hostname=""
  local input_hostname=""

  read -p "CHANGE Hostname ($(hostname)) (REBOOT REQUIRED) [y/n]? " -n 1 -r change_hostname; printf "\n"
  if [[ $change_hostname =~ ^[Yy]$ ]]; then 
    read -p "ENTER Hostname: " -i "$(hostname)" -e input_hostname
    reboot_required="y"; 
  fi
  printf "\n"

  printf "###########################################################\n"
  # SELinux
  local change_selinux=""
  local input_selinux_state=""

  read -p "CHANGE SELinux state ($(getenforce)) [y/n]?" -n 1 -r change_selinux; printf "\n"
  if [[ $change_selinux =~ ^[Yy]$ ]]; then 
    read -p "SET SELinux state: (e)nforce, (p)ermissive, or (d)isabled (REBOOT REQUIRED) [e/p/d]? " -n 1 -r input_selinux_state; printf "\n"
    reboot_required="y"
  fi
  printf "\n"
  
  printf "###########################################################\n"
  # Disable or Flush IP Tables
  local change_iptables=""
  local input_iptables_state=""
  local input_iptables_flush=""

  local iptables_current_status="Enabled"
  if [[ "$(service iptables status)" = "iptables: Firewall is not running." ]]; then iptables_current_status="Disabled"; fi
  
  read -p "CHANGE IPTABLES state ($iptables_current_status) [y/n]? " -n 1 -r change_iptables; printf "\n"
  if [[ $change_iptables =~ ^[Yy]$ ]]; then 
    read -p "SET IPTables state: (e)nable or (d)isable [e/d]? " -n 1 -r input_iptables_state; printf "\n"
  fi

  if ( [ "$iptables_current_status" = "Enabled" ] && [[ $change_iptables =~ ^[Nn]$ ]]) || [[ $input_iptables_state =~ ^[Ee]$ ]]  ; then 
    read -p "FLUSH IPTables [y/n]? " -n 1 -r input_iptables_flush; printf "\n"
  fi


  printf "###########################################################\n"
  # Setup NETWORK
  local change_network=""
  local input_network_bootproto=""
 
  local input_network_name=""
  local input_network_ipaddr=""
  local input_network_broadcast=""
  local input_network_netmask=""
  local input_network_gateway=""
  local input_network_dns1=""
  local input_network_dns1=""

  printf "\n<CURRENT NETWORK CONFIGURATION>\n"
  cat /etc/sysconfig/network-scripts/ifcfg-eth0 
  
  printf "\n"

  read -p "CHANGE eth0 config [y/n]? " -n 1 -r change_network; printf "\n"
  if [[ $change_network =~ ^[Yy]$ ]]; then 
    read -p "SET BOOTPROTO: (s)tatic or (d)hcp [s/d]? " -n 1 -r input_network_bootproto; printf "\n\n"

    if [[ $input_network_bootproto =~ ^[Ss]$ ]]; then
      printf "DEVICE=eth0\n"
      printf "HWADDR=$(cat /sys/class/net/eth0/address)"
      printf "TYPE=Ethernet\n"
      printf "ONBOOT=yes\n"
      printf "NM_CONTROLLED=no\n"
      printf "USERCTL=no\n"
      printf "BOOTPROTO=static\n"

      read -p "SET NAME: " -i "System eth0" -e input_network_name
      read -p "SET IPADDR: " -i "10.102.215.143" -e input_network_ipaddr
      read -p "SET BROADCAST: " -i "10.102.215.255" -e input_network_broadcast
      read -p "SET NETMASK: " -i "255.255.255.0" -e input_network_netmask
      read -p "SET GATEWAY: " -i "10.102.215.1" -e input_network_gateway
      read -p "SET DNS1: " -i "170.20.134.160" -e input_network_dns1
      read -p "SET DNS2: " -i "170.20.76.236" -e input_network_dns1
    fi

  fi
  
  printf "###########################################################\n"
  # Install SSH
  local change_ssh=""
  local input_ssh_state=""
  local input_ssh_port=""

  local ssh_status="disabled"
  if (( $(ps -ef | grep -v grep | grep sshd | wc -l) > 0 )); then ssh_status="enabled"; fi

  read -p "CHANGE SSH state ($ssh_status) [y/n]?" -n 1 -r change_ssh; printf "\n"
  if [[ $change_ssh =~ ^[Yy]$ ]]; then  
    read -p "SET SSH state: (e)nable or (d)isable [e/d]? " -n 1 -r input_ssh_state; printf "\n"
    if [[ $input_ssh_state =~ ^[Ee]$ ]]; then 
      read -p "SET SSH port: " -i "7800" -e input_ssh_port
    fi
  fi
  printf "\n"

  printf "###########################################################\n"
  # NTP
  local change_ntp=""
  local input_ntp_state=""
  local input_ntp_addr=""

  local ntp_status="disabled"
  if (( $(ps -ef | grep -v grep | grep ntpd | wc -l) > 0 )); then ntp_status="enabled"; fi

  read -p "CHANGE NTP state ($ntp_status) [y/n]?" -n 1 -r change_ntp; printf "\n"
  if [[ $change_ntp =~ ^[Yy]$ ]]; then  
    read -p "NTP (e)nable or (d)isable [e/d]? " -n 1 -r input_ntp_state; printf "\n"
    if [[ $input_ntp_state =~ ^[Ee]$ ]]; then 
      read -p "SET NTP Address: " -i "ntp.cbs.com" -e input_ntp_addr
    fi
  fi
  printf "\n"

  printf "###########################################################\n"
  # Install Essentials
  local ask_install_essentials=""
  read -p "INSTALL Essentials (kernel-headers kernel-devel man vim rsync traceroute nmap telnet tcpdump) [y/n]? " -n 1 -r choice_install_essentials; printf "\n\n"

  printf "###########################################################\n"
  # Install Network Tools
  local ask_install_network_tools=""
  read -p "INSTALL Network Tools (net-tools links wget lsof iotop iptraf psacct nc) [y/n]? " -n 1 -r ask_install_network_tools; printf "\n\n"
  
  printf "###########################################################\n"
  # Install C & C++
  local ask_install_c_compiler=""
  read -p "INSTALL C/C++ Compiler & Make [y/n]? " -n 1 -r ask_install_c_compiler; printf "\n\n"
  
  printf "###########################################################\n"
  # Install Perl
  local ask_install_perl=""
  read -p "INSTALL Perl [y/n]? " -n 1 -r ask_install_perl; printf "\n\n"
   
  printf "###########################################################\n"
  # Upgrade Operating System
  local ask_upgrade_os=""
  read -p "UPGRADE Operating System [y/n]? " -n 1 -r ask_upgrade_os; printf "\n\n"
  
  printf "###########################################################\n"
  # Global Alias
  local ask_global_alias=""
  read -p "CREATE Global Alias File (/etc/profile.d/global_aliases.sh) [y/n]? " -n 1 -r ask_global_alias; printf "\n\n"
  
  printf "###########################################################\n"
  # Reboot
  local ask_reboot=""
  if [[ $reboot_required = "y" ]]; then 
    read -p "You have selected an option that requires a reboot.  Reboot after Committing changes? [y/n]" -n 1 -r ask_reboot; printf "\n\n"
  fi
 
  printf "###########################################################\n"
  printf "###########################################################\n"
  # Commit Changes
  local ask_commit_changes=""
  read -p "Commit Changes [y/n]? " -n 1 -r ask_commit_changes
  printf "\n\n"
  sleep 2
  printf "READY\n"
  sleep 1
  printf "SET\n"
  sleep 1
  printf "GO\n"
  sleep 1

  if [[ $ask_commit_changes = "y" ]]; then 

    if [[ $ask_vmprep =~ ^[Yy]$ ]]; then vmprep; fi 
    if [[ $change_hostname =~ ^[Yy]$ ]]; then hostname_set "$input_hostname"; fi 
    if [[ $input_selinux_state =~ ^[Ee]$ ]]; then selinux_enforcing; fi
    if [[ $input_selinux_state =~ ^[Pp]$ ]]; then selinux_permissive; fi
    if [[ $input_selinux_state =~ ^[Dd]$ ]]; then selinux_disabled; fi
    if [[ $input_iptables_state =~ ^[Ee]$ ]]; then iptables_enable; fi
    if [[ $input_iptables_state =~ ^[Dd]$ ]]; then iptables_disable; fi
    if [[ $input_iptables_flush =~ ^[Yy]$ ]]; then iptables_flush; fi
    if [[ $input_network_bootproto =~ ^[Dd]$ ]]; then network_dhcp; fi 
    if [[ $input_network_bootproto =~ ^[Ss]$ ]]; then network_static "$input_network_name", "$choice_network_ipaddr", "$choice_network_broadcast", "$choice_network_netmask", "$choice_network_gateway", "$choice_network_dns1", "$choice_network_dns1"; fi 
    if [[ $input_ssh_state =~ ^[Ee]$ ]]; then ssh_enable "$input_ssh_port"; fi
    if [[ $input_ssh_state =~ ^[Dd]$ ]]; then ssh_disable; fi 
    if [[ $input_ntp_state =~ ^[Ee]$ ]]; then ntp_enable "$input_ntp_addr"; fi 
    if [[ $input_ntp_state =~ ^[Dd]$ ]]; then ntp_disable; fi 
    if [[ $ask_install_essentials =~ ^[Yy]$ ]]; then install_essentials; fi 
    if [[ $ask_install_network_tools =~ ^[Yy]$ ]]; then install_network_tools; fi 
    if [[ $ask_install_c_compiler =~ ^[Yy]$ ]]; then install_c_compiler; fi 
    if [[ $ask_install_perl =~ ^[Yy]$ ]]; then install_perl; fi
    if [[ $ask_upgrade_os =~ ^[Yy]$ ]]; then upgrade_os; fi 
    if [[ $ask_global_alias =~ ^[Yy]$ ]]; then global_aliases; fi 
    if [[ $ask_reboot =~ ^[Yy]$ ]]; then reboot_machine; fi 
  fi

  printf "'ALL DONE!' ~Bashito\n\n"   
}

main
