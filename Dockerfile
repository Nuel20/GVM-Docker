FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

EXPOSE 9392

COPY install-pkgs.sh /install-pkgs.sh
RUN bash /install-pkgs.sh

ENV gvm_libs_version="v20.8.0" \
    openvas_scanner_version="v20.8.0" \
    gvmd_version="v20.8.0" \
    gsa_version="v20.8.0" \
    open_scanner_protocol_daemon="v20.8.1" \
    ospd_openvas="v20.8.0" \
    gvm_tools_version="v2.1.0" \
    openvas_smb="v1.0.5" \
    python_gvm_version="v1.6.0"



    #
    # install libraries module for the Greenbone Vulnerability Management Solution
    #




RUN bash /gvm-modules/gvm-libs.sh
#RUN echo "Starting Build..." && rm -rf /build &&\
#    mkdir -p /build && \
#    cd /build && \
#    pwd && \
#    wget --no-verbose https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz && \
#    tar -zxf $gvm_libs_version.tar.gz && \
#    ls -l /build/ && \
#    cd /build/*/ && \
#    mkdir build && \
#    cd build && \
#    cmake -DCMAKE_BUILD_TYPE=Release .. && \
#    make && \
#    make install && \
#    cd /build && \
#    rm -rf *

    #
    # install smb module for the OpenVAS Scanner
    #

RUN bash /gvm-modules/openvas-smb.sh
#RUN cd /build && \
#    wget --no-verbose https://github.com/greenbone/openvas-smb/archive/$openvas_smb.tar.gz && \
#    tar -zxf $openvas_smb.tar.gz && \
#    cd /build/*/ && \
#    mkdir build && \
#    cd build && \
#    cmake -DCMAKE_BUILD_TYPE=Release .. && \
#    make && \
#    make install && \
#    cd /build && \
#    rm -rf *
    
    #
    # Install Greenbone Vulnerability Manager (GVMD)
    #

RUN bash /gvm-modules/gvmd-sh
#RUN cd /build && \
#    wget --no-verbose https://github.com/greenbone/gvmd/archive/$gvmd_version.tar.gz && \
#    tar -zxf $gvmd_version.tar.gz && \
#    cd /build/*/ && \
#    mkdir build && \
#    cd build && \
#    cmake -DCMAKE_BUILD_TYPE=Release .. && \
#    make && \
#    make install && \
#    cd /build && \
#    rm -rf *
    
    #
    # Install Open Vulnerability Assessment System (OpenVAS) Scanner of the Greenbone Vulnerability Management (GVM) Solution
    #

RUN bash /gvm-modules/openvas-scanner.sh
#RUN cd /build && \
#    wget --no-verbose https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz && \
#    tar -zxf $openvas_scanner_version.tar.gz && \
#    cd /build/*/ && \
#    mkdir build && \
#    cd build && \
#    cmake -DCMAKE_BUILD_TYPE=Release .. && \
#    make && \
#    make install && \
#    cd /build && \
#    rm -rf *
    
    #
    # Install Greenbone Security Assistant (GSA)
    #

RUN bash /gvm-modules/gsa.sh
#RUN cd /build && \
#    wget --no-verbose https://github.com/greenbone/gsa/archive/$gsa_version.tar.gz && \
#    tar -zxf $gsa_version.tar.gz && \
#    cd /build/*/ && \
#    mkdir build && \
#    cd build && \
#    cmake -DCMAKE_BUILD_TYPE=Release .. && \
#    make && \
#    make install && \
#    cd /build && \
#    rm -rf *
    
    #
    # Install Greenbone Vulnerability Management Python Library
    #
RUN python3 -m pip install python-gvm==$python_gvm_version
    
#RUN cd /build && \
    #wget --no-verbose https://github.com/greenbone/python-gvm/archive/$python_gvm_version.tar.gz && \
    #tar -zxf $python_gvm_version.tar.gz && \
    #cd /build/*/ && \
    #python3 setup.py install && \
    #cd /build && \
    #rm -rf *
    
    #
    # Install Open Scanner Protocol daemon (OSPd)
    #
    
RUN bash /gvm-modules/ospd.sh
#RUN cd /build && \
#    wget --no-verbose https://github.com/greenbone/ospd/archive/$open_scanner_protocol_daemon.tar.gz && \
#    tar -zxf $open_scanner_protocol_daemon.tar.gz && \
#    cd /build/*/ && \
#    python3 setup.py install && \
#    cd /build && \
#    rm -rf *
    
    #
    # Install Open Scanner Protocol for OpenVAS
    #
    
RUN bash /gvm-modules/ospd-openvas.sh
#RUN cd /build && \
#    wget --no-verbose https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas.tar.gz && \
#    tar -zxf $ospd_openvas.tar.gz && \
#    cd /build/*/ && \
#    python3 setup.py install && \
#    cd /build && \
#    rm -rf *
    

# Install GVM-Tools
# Make sure all libraries are linked and add a random directory suddenly needed by ospd :/
RUN python3 -m pip install gvm-tools==$gvm_tools_version && \
    apt-get clean && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/openvas.conf && ldconfig  && \
    ldconfig && \ 
    kdir /var/run/ospd
 

COPY scripts/* /
HEALTHCHECK --interval=600s --start-period=1200s --timeout=3s \
  CMD curl -f http://localhost:9392/ || exit 1
ENTRYPOINT [ "/start.sh" ]