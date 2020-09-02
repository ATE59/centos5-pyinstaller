FROM centos:centos5

# Configure YUM to use vault as official repositories are disabled
RUN mkdir /var/cache/yum/base/ \
    && mkdir /var/cache/yum/extras/ \
    && mkdir /var/cache/yum/updates/ \
    && mkdir /var/cache/yum/libselinux/ \
    && echo "http://vault.centos.org/5.11/os/x86_64/" > /var/cache/yum/base/mirrorlist.txt \
    && echo "http://vault.centos.org/5.11/extras/x86_64/" > /var/cache/yum/extras/mirrorlist.txt \
    && echo "http://vault.centos.org/5.11/updates/x86_64/" > /var/cache/yum/updates/mirrorlist.txt \
    && echo "http://vault.centos.org/5.11/centosplus/x86_64/" > /var/cache/yum/libselinux/mirrorlist.txt

# Install dependencies
RUN yum install -y gcc gcc44 zlib-devel python-setuptools readline-devel wget make perl

# OpenSSL installation
## Copy and uncompress
WORKDIR /tmp/pyinstaller
COPY openssl-1.0.2u.tar.gz .
RUN tar zxf openssl-1.0.2u.tar.gz
WORKDIR /tmp/pyinstaller/openssl-1.0.2u
# Needed to avoid compilation problems
ENV CC /usr/bin/gcc44
# Build shared version
# Install in /usr/local
RUN ./config shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl -Wl,-rpath=/usr/local/ssl/lib
# Modify Makefile to include -fPIC in CFLAGS, similar to export CFLAGS=-fPIC
RUN sed -i.orig '/^CFLAG/s/$/ -fPIC/' Makefile
# Build and install
RUN make && make install
# Add library path
RUN echo "/usr/local/ssl/lib" >> /etc/ld.so.conf
RUN ldconfig

# Python 3.6.11 installation
# Copy and uncompress
WORKDIR /tmp/pyinstaller
COPY Python-3.6.11.tgz .
RUN tar zxf Python-3.6.11.tgz
# Configure SSL path
WORKDIR /tmp/pyinstaller/Python-3.6.11/Modules
COPY Setup.dist .
# Configure with shared
WORKDIR /tmp/pyinstaller/Python-3.6.11
RUN ./configure --prefix=/opt/python36 --enable-shared
# Build and install
RUN make altinstall

# Install curl
# Copy and uncompress
WORKDIR /tmp/pyinstaller
COPY curl-7.42.1.tar.gz .
RUN tar zxf curl-7.42.1.tar.gz
# Configure
WORKDIR /tmp/pyinstaller/curl-7.42.1
RUN ./configure --with-ssl=/usr/local/ssl --disable-ldap
# Build and install
RUN make && make install

# Install git
# Copy and uncompress
WORKDIR /tmp/pyinstaller
COPY git-2.28.0.tar.gz .
RUN tar zxf git-2.28.0.tar.gz
# Install dependencies
RUN yum install -y gettext-devel
# Configure
WORKDIR /tmp/pyinstaller/git-2.28.0
RUN ./configure --with-openssl=/usr/local/ssl --without-tcltk
# Build
RUN make && make install

# Configuration
WORKDIR /root

# Libs in /usr/local
RUN echo "/usr/local/lib" >> /etc/ld.so.conf
RUN ldconfig

# Python3.6 lib and path
RUN echo "export LD_LIBRARY_PATH=/opt/python36/lib/" >> ~/.bashrc
RUN echo "export PATH=/opt/python36/bin:${PATH}" >> ~/.bashrc

# Install pip and pyinstaller
RUN source ~/.bashrc \
    && /opt/python36/bin/pip3.6 install --upgrade pip \
    && /opt/python36/bin/pip3.6 install pyinstaller

# Cleanup
RUN rm -rf /tmp/pyinstaller

# Volume used to put python sources
VOLUME /src

# Get in the volume and start building
WORKDIR /src
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
