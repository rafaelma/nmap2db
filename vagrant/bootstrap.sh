#!/usr/bin/env bash

rpm -ivh http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm
yum -y groupinstall "PostgreSQL Database Server 9.3 PGDG"
yum -y install python-setuptools gcc postgresql93-devel python-devel


