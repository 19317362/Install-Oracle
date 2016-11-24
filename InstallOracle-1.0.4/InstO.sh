# User creation file :
#
# $Id: DeployOracle  1.0.2 2016/03/12 14:02:00 Yann Allandit $
#==============================================================================
#       (c) Copyright 2004 Hewlett-Packard Development Company, L.P.
#    The information contained herein is subject to change without notice.
#==============================================================================
#
#  YY/MM/DD  BY                Modification History
#  16/03/02  Yann Allandit     Creation for 12c on RHEL/CentOS 7.x
#  16/04/06  Yann Allandit     Read the $OB and $OH value from the Oracle bash_profile before running the installatio
###############################################################################
#!/bin/bash

################### Parameters received by this script ###
# $1	Boolean for installing a database or not
# $2	Location of the Oracle installation kit

################### Variable definition ##################
OH="empty"		# Location red from the bash_profile
OB="empty"              # Location red from the bash_profile
OraInv="empty"		# new rsp inventory location
OHome="empty"		# new rsp ORACLE_HOME location
OBase="empty"		# new rsp ORACLE_BASE location
FSLoc="empty"		# new rsp oradata location

############################################################
# Read the OACLE_HOME and ORACLE_BASE values of the oracle owner
############################################################

OH=`su - oracle -c /tmp/scripts/echoOH.sh`
OB=`grep ORACLE_BASE= /home/oracle/.bash_profile | cut -f2 -d=`


############################################################
# Alter response file based on the current $OB and $OH
############################################################
OraInv=INVENTORY_LOCATION=${OB}/oraInventory
OHome=ORACLE_HOME=${OH}
OBase=ORACLE_BASE=${OB}
FSLoc=oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=${OB}/oradata

sed -i -e "s@INVENTORY_LOCATION=/ora1/app/oracle/oraInventory@${OraInv}@g" /home/oracle/db_install.rsp 
sed -i -e "s@ORACLE_HOME=/ora1/app/oracle/12c@${OHome}@g" /home/oracle/db_install.rsp 
sed -i -e "s@ORACLE_BASE=/ora1/app/oracle@${OBase}@g" /home/oracle/db_install.rsp 
sed -i -e "s@oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=/ora1/app/oracle/oradata@${FSLoc}@g" /home/oracle/db_install.rsp 


############################################################
# Install the oracle binaries on the local node
############################################################

su - oracle -c "echo -ne '\n' | $2/runInstaller -silent -responseFile /home/oracle/db_install.rsp -ignorePrereq -waitforcompletion SECURITY_UPDATES_VIA_MYORACLESUPPORT=false DECLINE_SECURITY_UPDATES=true"

#### If the orainstroot file exist, root run it
if [ -f ${OB}/oraInventory/orainstRoot.sh ]
then
  ${OB}/oraInventory/orainstRoot.sh
else
  echo "orainst root file not in the orainventory location"
fi

#### If the root.sh file exist, root run it
if [ -f ${OH}/root.sh ]
then
  ${OH}/root.sh
else
  echo "root.sh root file not in the orainventory location"
fi

#### Start of the LISTENER
su - oracle -c ". /home/oracle/.bash_profile | lsnrctl start"


############################################################
# Database creation if requested
############################################################

if [ $1 = "Y" ]
then
  su - oracle -c ". /home/oracle/.bash_profile | dbca -silent -responseFile /home/oracle/dbca.rsp"
fi

exit 0 

