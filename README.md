# Install Oracle
================

Install Oracle package
----------------------

### What is Install Oracle made for
Believe it or not "Install Oracle" is a set of scripts that will automatically install Oracle and create a database on up to 12 nodes already configured.
The instances created are single instance (no RAC) on a file system by default.
This tool can deploy up to 12 environments in parallel. Thus, depending on the speed of your servers, you can fully deploy up to 12 Oracle databases in lass than 30 minutes.

### Prerequisites
It is strongly suggested to perform the OS setting using RSFO available at https://github.com/yannallandit/rsfo
The Oracle distribution need to be presented via nfs.
The NFS configuration should be done this way:
1. On the NFS server:
   * # more /etc/exports
     /kits   *(async,no_root_squash)
   * # systemctl restart nfs-config
   * # systemctl restart nfs
2. The Oracle installation files need to be in a directory called /kits/oradb/
   * # ls /kits/oradb/
     install  response  rpm  runInstaller  sshsetup  stage  welcome.html
3. On the client where Oracl will be installed:
   * # mkdir /kits
   * # mount -t nfs rsfodev:/kits /kits

### How to use Install Oracle

1. Download the latest rpm from the Github page https://github.com/yannallandit/rsfo 
2. Install the rpm: yum install –y InstallOracle-1.0.1-1.el7.noarch.rpm
3. Go to the location directory: # cd /opt/hpe/rsfo/
4. Run the script: # ./DeployOracle.sh
	* Provides the list of nodes where Oracle will be installed

