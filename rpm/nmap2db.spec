#
# File: nmap2db.spec
#
# Autor: Rafael Martinez <rafael@postgreslq.org.es>
#  

%define majorversion 1.0
%define minorversion 0
%define nmap2db_owner nmap2db
%define nmap2db_group nmap2db
%{!?pybasever: %define pybasever %(python -c "import sys;print(sys.version[0:3])")}
%{!?python_sitelib: %define python_sitelib %(python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")}

Summary:        NMAP scan manager
Name:           nmap2db
Version:        %{majorversion}.%{minorversion}
Release:        1%{?dist}
License:        GPLv3
Group:          Applications/Databases
Url:            https://github.com/rafaelma/nmap2db
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-buildroot-%(%{__id_u} -n)
BuildArch:      noarch
Requires:       python-psycopg2 python-argparse nmap python-setuptools shadow-utils logrotate

%description 
NMAP2DB is a tool for managing nmap scans and save the results in a
PostgreSQL database.

%prep
%setup -n %{name}-%{version} -q

%build
python setup.py build

%install
python setup.py install -O1 --skip-build --root %{buildroot}
mkdir -p %{buildroot}/var/lib/%{name}
touch %{buildroot}/var/log/%{name}/%{name}.log

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc INSTALL
%{python_sitelib}/%{name}-%{version}-py%{pybasever}.egg-info/
%{python_sitelib}/%{name}/
%{_bindir}/%{name}*
%{_sysconfdir}/init.d/%{name}*
%{_datadir}/%{name}/*
/var/log/%{name}/*
%config(noreplace) %{_sysconfdir}/%{name}/%{name}.conf
%attr(700,%{nmap2db_owner},%{nmap2db_group}) %dir /var/lib/%{name}
%attr(755,%{nmap2db_owner},%{nmap2db_group}) %dir /var/log/%{name}
%attr(600,%{nmap2db_owner},%{nmap2db_group}) %ghost /var/log/%{name}/%{name}.log

%pre
groupadd -f -r nmap2db >/dev/null 2>&1 || :
useradd -M -N -g nmap2db -r -d /var/lib/nmap2db -s /bin/bash \
        -c "NMAP scan manager" nmap2db >/dev/null 2>&1 || :

%changelog
* Mon Jun 24 2014 - Rafael Martinez Guerrero <rafael@postgresql.org.es> 1.0.0-1
- New release 1.0.0
