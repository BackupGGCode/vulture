Requires: openssl python-ldap vulture-common >= 3
%define serverroot /opt
Vendor: Advens
%define release 1
%define name vulture
%define version 2.0.1
AutoReqProv: no

Summary: Vulture Reverse Proxy
Name: %name
Version: %version
Release: %release
License: GPL
Group: System/Servers
URL: http://www.vultureproject.org
Buildarch: %{_target_cpu} noarch
Source0: %{name}-%{version}.tar.bz2
Source1: http://media.djangoproject.com/releases/1.3/Django-1.3.1.tar.gz
Source2: http://ovh.dl.sourceforge.net/sourceforge/pyopenssl/pyOpenSSL-0.6.tar.gz
Patch0: http://arnaud.desmons.free.fr/pyOpenSSL-0.6-pkcs12.patch
Patch1: http://arnaud.desmons.free.fr/pyOpenSSL-0.6-pkcs12_cafile.patch
Patch2: http://arnaud.desmons.free.fr/pyOpenSSL-0.6-crl.patch
Patch3: database_path.patch

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildRequires: perl gcc gcc-c++ sqlite python-devel openssl-devel

%description
Vulture Reverse Proxy

%prep
%setup -c -a 0 -a 1 -a 2
%patch0 -p1 -b .old
%patch1 -p0 -b .old
%patch2 -p0 -b .old
%patch3 -p0 -b .old

%build
	rm -rf $RPM_BUILD_ROOT
	cd %name-%{version} &&\
%if %(test -e /usr/bin/python2.4 && echo 1 || echo 0)
	install -d -m0755 $RPM_BUILD_ROOT/usr/lib/python2.4/site-packages/
	cd ../Django-1.3.1 && PYTHONPATH=$RPM_BUILD_ROOT/usr/lib/python2.4/site-packages/ \
		python setup.py install --prefix=$RPM_BUILD_ROOT/usr
	cd ../pyOpenSSL-0.6 && PYTHONPATH=$RPM_BUILD_ROOT/usr/lib/python2.4/site-packages/ \
		python setup.py install --prefix=$RPM_BUILD_ROOT/usr
%endif
%if %(test -e /usr/bin/python2.5 && echo 1 || echo 0)
	install -d -m0755 $RPM_BUILD_ROOT/usr/lib/python2.5/site-packages/
	cd ../Django-1.3.1 && PYTHONPATH=$RPM_BUILD_ROOT/usr/lib/python2.5/site-packages/ \
		python setup.py install --prefix=$RPM_BUILD_ROOT/usr
	cd ../pyOpenSSL-0.6 && PYTHONPATH=$RPM_BUILD_ROOT/usr/lib/python2.5/site-packages/ \
		python setup.py install --prefix=$RPM_BUILD_ROOT/usr
%else
	install -d -m0755 $RPM_BUILD_ROOT/usr/lib/python2.6/site-packages/
        cd ../Django-1.3.1 && PYTHONPATH=$RPM_BUILD_ROOT/usr/lib/python2.6/site-packages/ \
                python setup.py install --prefix=$RPM_BUILD_ROOT/usr
        cd ../pyOpenSSL-0.6 && PYTHONPATH=$RPM_BUILD_ROOT/usr/lib/python2.6/site-packages/ \
                python setup.py install --prefix=$RPM_BUILD_ROOT/usr
%endif


%install
     cd %{name}-%{version} &&\
     make PREFIX=$RPM_BUILD_ROOT%{serverroot} PREFIXLIB=$RPM_BUILD_ROOT%{serverroot} UID='-o apache' GID='-g apache' install
     rm -f $RPM_BUILD_ROOT%{serverroot}/%{name}/lib/x86_64-linux-thread-multi/perllocal.pod
     rm -f $RPM_BUILD_ROOT%{serverroot}/%{name}/lib/i386-linux-thread-multi/perllocal.pod
     install -d -m0700 $RPM_BUILD_ROOT/etc/init.d
     install -m0755 rpm/vulture $RPM_BUILD_ROOT/etc/init.d/vulture
     install -d -m0755 $RPM_BUILD_ROOT%{serverroot}/%{name}
     cp -r admin $RPM_BUILD_ROOT%{serverroot}/%{name}
     install -m0644 rpm/settings.py\
	$RPM_BUILD_ROOT%{serverroot}/%{name}/admin/settings.py
     install -d -m0755 $RPM_BUILD_ROOT%{serverroot}/%{name}/conf
     install -m0644 rpm/httpd.conf\
	$RPM_BUILD_ROOT%{serverroot}/%{name}/conf/httpd.conf
     install -m0644 rpm/vulture.wsgi\
        $RPM_BUILD_ROOT%{serverroot}/%{name}/conf/vulture.wsgi
     install -m0644 conf/openssl.cnf\
	$RPM_BUILD_ROOT%{serverroot}/%{name}/conf/openssl.cnf 
%clean
     rm -rf $RPM_BUILD_ROOT

%post
    if [ ! -f %{serverroot}/%{name}/conf/server.crt ]; then
        PATH=$PATH:%{serverroot}/bin openssl req -x509 -newkey rsa:1024 -batch\
        	-out %{serverroot}/%{name}/conf/server.crt\
        	-keyout %{serverroot}/%{name}/conf/server.key\
        	-nodes -config %{serverroot}/%{name}/conf/openssl.cnf
    fi
    if [ ! -f %{serverroot}/%{name}/conf/server.pem ]; then
        cat %{serverroot}/%{name}/conf/server.key %{serverroot}/%{name}/conf/server.crt > %{serverroot}/%{name}/conf/server.pem
    fi
    /sbin/chkconfig --add vulture
    /etc/init.d/vulture start
    echo no | python %{serverroot}/%{name}/admin/manage.py syncdb
    if [ -f %{serverroot}/%{name}/admin/vulture/sql/log.sql ] ; then
        BASE_RULE=`%{serverroot}/%{name}/sqlite/bin/sqlite3 %{serverroot}/%{name}/admin/db "SELECT count(*) from log"`
        if [ $BASE_RULE = 0 ]; then
            %{serverroot}/%{name}/sqlite/bin/sqlite3 %{serverroot}/%{name}/admin/db < %{serverroot}/%{name}/admin/vulture/sql/log.sql
        fi
    fi
    if [ -f %{serverroot}/%{name}/admin/vulture/sql/modsecurity.sql ] ; then
        BASE_RULE=`%{serverroot}/%{name}/sqlite/bin/sqlite3 %{serverroot}/%{name}/admin/db "SELECT count(*) from modsecurity"`
        if [ $BASE_RULE = 0 ]; then
            %{serverroot}/%{name}/sqlite/bin/sqlite3 %{serverroot}/%{name}/admin/db < %{serverroot}/%{name}/admin/vulture/sql/modsecurity.sql
        fi
    fi
    chown apache. %{serverroot}/%{name}/admin/db
    if [ ! -f %{serverroot}/%{name}/conf/cacert.pem ]; then
        openssl req -x509 -days 3650 -newkey rsa:1024 -batch\
        	-out %{serverroot}/%{name}/conf/cacert.pem\
        	-keyout %{serverroot}/%{name}/conf/cacert.key\
        	-nodes -config %{serverroot}/%{name}/conf/openssl.cnf -extensions v3_ca
    fi
    if [ ! -f %{serverroot}/%{name}/conf/index.txt ]; then
		touch %{serverroot}/%{name}/conf/index.txt
    fi
    if [ ! -f %{serverroot}/%{name}/conf/serial ]; then
		echo 01 > %{serverroot}/%{name}/conf/serial
    fi
    if [ ! -f %{serverroot}/%{name}/conf/server.crt ]; then
        openssl req -newkey rsa:1024 -batch\
        	-out %{serverroot}/%{name}/conf/server.req\
        	-keyout %{serverroot}/%{name}/conf/server.key\
        	-nodes -config %{serverroot}/%{name}/conf/openssl.cnf
	cd  %{serverroot}/%{name}/conf &&\
	openssl ca -in %{serverroot}/%{name}/conf/server.req\
		-out %{serverroot}/%{name}/conf/server.crt\
		-config %{serverroot}/%{name}/conf/openssl.cnf\
		-keyfile %{serverroot}/%{name}/conf/cacert.key\
		-cert %{serverroot}/%{name}/conf/cacert.pem\
		-outdir %{serverroot}/%{name}/conf/ -batch
    fi

%preun
    /etc/init.d/vulture stop
    /sbin/chkconfig --del vulture

%files
%defattr(-,apache,apache,-)
%config(noreplace) %{serverroot}/%{name}/conf
%config(noreplace) %{serverroot}/%{name}/sql
%{serverroot}/%{name}/admin
%{serverroot}/%{name}/bin
%{serverroot}/%{name}/static
%defattr(-,root,root)
%{serverroot}/%{name}/lib
/etc/init.d/%{name}
%if %(test -e /usr/bin/python2.4 && echo 1 || echo 0)
/usr/lib/python2.4
%ifarch x86_64
/usr/lib64/python2.4
%endif
%endif
%if %(test -e /usr/bin/python2.5 && echo 1 || echo 0)
/usr/lib/python2.5
%ifarch x86_64
/usr/lib64/python2.5
%endif
%else
/usr/lib/python2.6
%ifarch x86_64
/usr/lib64/python2.6
%endif
%endif
%defattr(-,apache,apache,-)
%exclude /usr/bin

%changelog
* Fri Oct 7 2011 Arnaud Desmons <logarno@gmail.com> 2.0.1-1
- 2.0.1

* Fri Jul 29 2011 Arnaud Desmons <logarno@gmail.com> 2.0-1
- admin Django
- perl rewrite