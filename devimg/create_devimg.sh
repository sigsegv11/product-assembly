#!/bin/bash

if [ -z "${SRCROOT}" ]
then
    SRCROOT=/mnt/src
fi

if [ ! -d "${SRCROOT}" ]
then
    echo "ERROR: SRCROOT=${SRCROOT} does not exist"
    exit 1
fi

set -e
set -x

# link source code for zenoss initialization
echo "Linking in prodbin Products ..."
rm -rf ${ZENHOME}/Products
su - zenoss -c "ln -s ${SRCROOT}/zenoss-prodbin/Products ${ZENHOME}/Products"
echo "Linking in zenpacks directory ..."
su - zenoss -c "ln -s ${SRCROOT} ${ZENHOME}/packs"
echo "Linking in zep sql directory ..."
rm -rf ${ZENHOME}/share/zeneventserver/sql
su - zenoss -c "ln -s ${SRCROOT}/zenoss-zep/core/src/main/sql ${ZENHOME}/share/zeneventserver/sql"
echo "Linking in zep webapp..."
rm -rf ${ZENHOME}/webapps/zeneventserver
su - zenoss -c "ln -s ${SRCROOT}/zenoss-zep ${ZENHOME}/webapps/zeneventserver"

#TODO: do we want to do this for prodbin bin files as well?
if [ -d ${SRCROOT}/zenoss-zep/dist/src/assembly/bin ]
then
    for srcfile in ${SRCROOT}/zenoss-zep/dist/src/assembly/bin/*; do
        filename=$(basename "$srcfile")
        rm -f ${ZENHOME}/bin/${filename}
        su - zenoss -c "ln -s ${srcfile} ${ZENHOME}/bin/${filename}"
    done
else
    echo "${SRCROOT}/zenoss-zep/dist/src/assembly/bin does not exist"
    exit 1
fi



echo "Configuring maven..."
cat /home/zenoss/.bashrc
rm /opt/maven/conf/settings.xml
cp /mnt/devimg/settings.xml /opt/maven/conf/settings.xml
cat <<EOF >> /home/zenoss/.bashrc
export PATH=/opt/maven/bin:\$PATH
EOF


cat /home/zenoss/.bashrc
echo "Starting create_devimg ..."
export BUILD_DEVIMG=1
${ZENHOME}/install_scripts/create_zenoss.sh
echo "Finished create_zenoss.sh"

echo "Link in Java apps"
rm -rf ${ZENHOME}/lib/central-query
su - zenoss -c "ln -s ${SRCROOT}/query ${ZENHOME}/lib/central-query"

rm -rf ${ZENHOME}/lib/metric-consumer-app
su - zenoss -c "ln -s ${SRCROOT}/zenoss.metric.consumer ${ZENHOME}/lib/metric-consumer-app"

#TODO figure out how to install protocols in develop mode. The setup.py doesn't buld protobus.
#echo "Install zenoss-protocols in development mode"
#su - zenoss -c "pip uninstall -y zenoss.protocols"
#su - zenoss -c "pip install -e ${SRCROOT}/zenoss-protocols/python"

echo "Install zenwipe"
su - zenoss -c "ln -s ${SRCROOT}/zenoss-prodbin/devimg ${ZENHOME}/devimg"
cp ${ZENHOME}/devimg/zenwipe.sh ${ZENHOME}/bin/zenwipe.sh
chown zenoss:zenoss ${ZENHOME}/bin/zenwipe.sh
chmod 754 ${ZENHOME}/bin/zenwipe.sh


