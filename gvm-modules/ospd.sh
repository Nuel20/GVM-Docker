cd /build && \
wget --no-verbose https://github.com/greenbone/ospd/archive/$open_scanner_protocol_daemon.tar.gz && \
tar -zxf $open_scanner_protocol_daemon.tar.gz && \
cd /build/*/ && \
python3 setup.py install && \
cd /build && \
rm -rf *