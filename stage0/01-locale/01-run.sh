#!/bin/bash -e
# fix the annoying perl warnings 
on_chroot << EOF
export LANGUAGE=${LOCALE_DEFAULT}
export LC_ALL=${LOCALE_DEFAULT}
dpkg-reconfigure -f noninteractive locales
echo  ": "${LANG:=${LOCALE_DEFAULT}}"; export LANG" >> /etc/profile
# TODO: 
cat /etc/profile
EOF

