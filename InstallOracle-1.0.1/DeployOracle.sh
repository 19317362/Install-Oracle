# User creation file :
#
# $Id: DeployOracle  1.0.0 2016/03/08 14:02:00 Yann Allandit $
#==============================================================================
#       (c) Copyright 2004 Hewlett-Packard Development Company, L.P.
#    The information contained herein is subject to change without notice.
#==============================================================================
#
#  YY/MM/DD  BY                Modification History
#  16/03/02  Yann Allandit     Creation for 12c on RHEL/CentOS 7.x
###############################################################################
#!/bin/bash


################### Variable definition #################
node_number=0           # Number of nodes in the cluster
node_name=empty         # Node name
list_node=empty         # List of all nodes name
i=0                     # Loop counter
name_input=N            # Boolean value for name nodes checking
name_check=N            # Temp Boolean value for name nodes checking
ssh_valid=0             # Check the ssh setting
sshd_check=0	        # Check if sshd is running
user_test=X             # Check the user running the script
local_node_name="empty" # Local node name got by "uname -a"
input_nodes=Y		# Boolean for input of nodes name
rhrelease="empty"	# Collect the version of the OS
dbcreation=Y		# Ask if the script need to create the DB on top of the installation
nfsdir="/kits/oradb"		# Contain the name of the directory where the Oracle installation files are
nfsdiranswer=Y		# Boolean checking the location of the installation file
runinstloc=N		# Boolean checking the location of the runInstaller


#############################################
# Check Environment
#############################################

##################### need to be root to run this script ###########
clear
user_test=`whoami`
if [ "X${user_test}" != "Xroot" ]
then
  echo "You need to be root to run this script"
  exit 1
fi

#################### Check the Red Hat release ####################
rhrelease=`cat /etc/redhat-release |grep Maipo`
if [ "X${rhrelease}" = "X" ]
then
  echo "This server does not run a Red Hat 7.x release"
  echo "Check /etc/redhat-release"
  exit 1
fi


########################################
# Files definition 
########################################
if [[ ! -d /tmp/scripts ]]
then
  mkdir -p /tmp/scripts
fi

# /tmp/scripts/nod_list.txt : Temp file for list of nodes name
file_nname=/tmp/scripts/nod_list.txt

# /tmp/scripts/log_rac.txt : log file
file_log=/tmp/scripts/log_rac.txt
: > /tmp/scripts/file_log.txt 

# /tmp/scripts/rhosts.txt : .rhosts template file
file_rhosts=/tmp/scripts/rhosts.txt
: > /tmp/scripts/rhosts.txt

# /tmp/scripts/packages_added.txt : List of added packages
file_pack=/tmp/scripts/packages_added.txt

###########################################
# Define the number of nodes in the cluster
###########################################

################ Check if a list of node file already exist ##############
if [ -f $file_nname ]
then
  node_number=`more ${file_nname}|wc|awk '{print $2}'`
  echo "There is ""${node_number}"" nodes in this cluster"
  read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

  for ((i=1; i<=node_number; i++))
  do
    show_name="N${i}"
    eval show_name=\$$show_name
    echo "Private node ${i} name is ${show_name}."
  done

  echo
  echo "Is this list correct (Y/N)?"
  read name_check
  while [ "X${name_check}" != "XN" ] && [ "X${name_check}" != "XY" ]
  do
    echo "The answer can only be Y or N"
    echo "Is this list correct (Y/N)?"
    read name_check
  done

  if [ "X${name_check}" = "XY" ]
  then
    input_nodes=N
  else
    : > ${file_nname}
  fi
fi


if [ "X${input_nodes}" != "XN" ]
then
  echo
  echo "######################################################################"
  echo " The script will ask you to define the number of nodes in the cluster"
  echo

  echo "Enter the number of nodes in your cluster (min 1, max 12):"
  read node_number

  while [ -z $node_number ]
  do 
    echo "The number can't be null"
    echo "Enter the number of nodes:"
    read node_number
  done

  while (($node_number<1)) || (($node_number>12))
  do
    echo "The number need to be 0<n<13"
    echo "Enter the number of nodes:"
    read node_number

    while [ -z $node_number ]
    do
      echo "The number can't be null"
      echo "Enter the number of nodes:"
      read node_number
    done
  done
fi

##########################################
# Register name of each node
##########################################

if [ "X${input_nodes}" != "XN" ]
then
  echo
  echo "#############################################################"
  echo " You will now enter the private name of the cluster nodes"
  echo " The private name is the name linked to the interconnect port"
  echo

  while [ ${name_input} == "N" ]
  do
    for ((i=1; i<=node_number; i++))
    do
      if [ $i = 1 ]
      then
        : > $file_nname
      fi
    
      node_name=""
      while [ -z $node_name ]
      do
        echo "Enter the private node name of the node Number $i:"
        read node_name
        if [ -n $node_name ]
        then
          list_node=`head -1 $file_nname`
          list_node=`echo "${list_node} ${node_name}"`
          echo $list_node>$file_nname
        else
          echo "Node name cant be null"
        fi
      done
    done

# Check node name
    read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

    for ((i=1; i<=node_number; i++))
    do
      show_name="N${i}" 
      eval show_name=\$$show_name
      echo " Node number $i name is $show_name"
    done
  
    echo "Is this list correct (Y/N)?" 
    read name_check
    while [ "X${name_check}" != "XN" ] && [ "X${name_check}" != "XY" ]
    do
      echo "The answer can only be Y or N"
      echo "Is this list correct (Y/N)?"
      read name_check
    done
    name_input=${name_check}
  done
fi

#################################################
# Ask if the script need to create a database
#################################################

echo
echo "Do you also want to create a database on top of the Oracle installation? (Y/N)"
read dbcreation
while [ "X${dbcreation}" != "XN" ] && [ "X${dbcreation}" != "XY" ]
do
  echo "The answer can only be Y or N"
  echo "Do you also want to create a database on top of the Oracle installation?"
  read dbcreation
done

if [ "X${dbcreation}" = "XY" ]
then
  dbcreation=Y
else
  dbcreation=N
fi


#################################################
# Ask for the location of the Oracle installation files
#################################################

echo
echo "The Oracle installation files are located in $nfsdir"
echo "Is that correct (Y/N)?"
read nfsdiranswer
while [ "X${nfsdiranswer}" != "XN" ] && [ "X${nfsdiranswer}" != "XY" ]
do
  echo "The answer can only be Y or N"
  echo "Is $nfsdir the location of the Oracle Installation files?"
  read nfsdiranswer
done

if [ "X${nfsdiranswer}" = "XN" ]
then
  while [ ${runinstloc} = "N" ]
  do
    echo " "
    echo "Enter the location of the Oracle installation files (without / at the end of the path)"
    echo "This is the directory where the runInstaller is"
    read nfsdir
    if [ -f ${nfsdir}/runInstaller ]
    then 
      runinstloc=Y
    else
      echo " "
      echo "runInstaller is not in ${nfsdir}"
    fi
  done
fi
	

#################################################
# Check if ssh works
#################################################

echo
echo "################################################################"
echo " The script will now test the ssh setting"
echo " If the script hang, it means that the ssh doesn't work properly"
echo

sshd_check=`ps -ef|grep /usr/sbin/sshd|grep -v grep|wc|awk '{print $1}'`
if [ "$sshd_check" -lt 1 ]
then
  echo "ssh daemon is not running on the local node."
  echo "start it before running this script."
  exit 
fi

################# RSA security checking ######
if [[ ! -f /root/.ssh/authorized_keys ]]
then
  local_node_name=`uname -a|awk '{print $2}'`
  echo "ssh with RSA security level is not correctly set on ${local_node_name}"
  echo "perform the steps describes in the SSH_setting.txt file"
  echo
  exit
fi

################# Test ssh between nodes #########
read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh $show_name date>/dev/null 2>$file_log
  ssh_valid=$?
  if [ $ssh_valid -ne 0 ]
  then
    echo "ssh doesn't work with $show_name"
    exit 1
  else
    echo "ssh works with $show_name"
  fi
done


#######################################################
# Trace file directory creation on remote nodes
#######################################################

read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=2; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  if [ -n "`ssh ${show_name} \"test ! -d /etc/scripts && echo exists\"`" ]
  then
    ssh ${show_name} mkdir -p /tmp/scripts
    ssh ${show_name} : >/tmp/scripts/packages_added.txt
  fi
done

  
############################################################
# Install the remote files
############################################################
 
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  scp ./*rsp ${show_name}:/home/oracle/
  scp ./InstO.sh ${show_name}:/tmp/scripts/
  ssh ${show_name} chown oracle:oinstall /home/oracle/*rsp
  ssh ${show_name} chmod +x /tmp/scripts/InstO.sh

  echo "Files copied on node ${show_name}"
done


###########################################################
# Install Oracle on all nodes
###########################################################
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} /tmp/scripts/InstO.sh $dbcreation ${nfsdir} &
done

exit 1


