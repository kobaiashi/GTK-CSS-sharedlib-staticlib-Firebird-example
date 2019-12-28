#!/bin/bash
echo $0
echo $1
#loading shared libraries
export LD_LIBRARY_PATH=./ShLibs
export ISC_USER=sysdba
export ISC_PASSWORD=masterkey

if [[ $1 == -d ]] ; then
#--enable-debug GOBJECT_DEBUG=instance-count
GTK_DEBUG=interactive ./out_app
else
./out_app
fi
