FROM centos:centos5

RUN mkdir /var/cache/yum/base/ \
    && mkdir /var/cache/yum/extras/ \
    && mkdir /var/cache/yum/updates/ \
    && mkdir /var/cache/yum/libselinux/ \
    && echo "http://vault.centos.org/5.11/os/x86_64/" > /var/cache/yum/base/mirrorlist.txt \
    && echo "http://vault.centos.org/5.11/extras/x86_64/" > /var/cache/yum/extras/mirrorlist.txt \
    && echo "http://vault.centos.org/5.11/updates/x86_64/" > /var/cache/yum/updates/mirrorlist.txt \
    && echo "http://vault.centos.org/5.11/centosplus/x86_64/" > /var/cache/yum/libselinux/mirrorlist.txt

WORKDIR /srv/pyinstaller

RUN yum install -y gcc gcc44 zlib-devel python-setuptools readline-devel wget make perl

COPY openssl-1.0.2u.tar.gz .

RUN tar zxf openssl-1.0.2u.tar.gz

WORKDIR /srv/pyinstaller/openssl-1.0.2u

ENV CC /usr/bin/gcc44

RUN ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl

RUN sed -i.orig '/^CFLAG/s/$/ -fPIC/' Makefile

RUN make && make install

WORKDIR /srv/pyinstaller

COPY Python-3.6.11.tgz .

RUN tar zxf Python-3.6.11.tgz

WORKDIR /srv/pyinstaller/Python-3.6.11/Modules

COPY Setup.dist .

WORKDIR /srv/pyinstaller/Python-3.6.11

RUN ./configure --prefix=/opt/python36 --enable-shared

RUN make altinstall

WORKDIR /root

RUN echo "export LD_LIBRARY_PATH=/opt/python36/lib/" >> ~/.bashrc

RUN echo "export PATH=/opt/python36/bin:${PATH}" >> ~/.bashrc

RUN source ~/.bashrc \
    && /opt/python36/bin/pip3.6 install --upgrade pip \
    && /opt/python36/bin/pip3.6 install pyinstaller

RUN rm -rf /srv/pyinstaller

VOLUME /src
WORKDIR /src

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]