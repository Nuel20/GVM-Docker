cd /build && \
wget --no-verbose https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas.tar.gz && \
tar -zxf $ospd_openvas.tar.gz && \
cd /build/*/ && \
python3 setup.py install && \
cd /build && \
rm -rf *