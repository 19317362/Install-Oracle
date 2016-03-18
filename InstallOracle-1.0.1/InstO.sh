#!/bin/bash

OH=`su - oracle -c ./echoOH.sh`
OB=`grep ORACLE_BASE= /home/oracle/.bash_profile | cut -f2 -d=`

#### Install the oracle binaries on the local node
#su - oracle -c "echo -ne '\n' | /kits/oradb/runInstaller -silent -responseFile /home/oracle/db_install.rsp -ignorePrereq -waitforcompletion"
su - oracle -c "echo -ne '\n' | $2/runInstaller -silent -responseFile /home/oracle/db_install.rsp -ignorePrereq -waitforcompletion"

#### If the orainstroot file exist, root run it
if [ -f ${OB}/oraInventory/orainstRoot.sh ]
then
  /ora1/app/oracle/oraInventory/orainstRoot.sh
else
  echo "orainst root file not in the orainventory location"
fi

#### If the root.sh file exist, root run it
if [ -f ${OH}/root.sh ]
then
  /ora1/app/oracle/12c/root.sh
else
  echo "root.sh root file not in the orainventory location"
fi

#### Start of the LISTENER
su - oracle -c ". /home/oracle/.bash_profile | lsnrctl start"

#### Database creation if requested
if [ $1 = "Y" ]
then
  su - oracle -c ". /home/oracle/.bash_profile | dbca -silent -responseFile /home/oracle/dbca.rsp"
fi

exit 

