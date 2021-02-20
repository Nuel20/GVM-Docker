 cd /build && \
wget --no-verbose https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz && \
tar -zxf $openvas_scanner_version.tar.gz && \
cd /build/*/ && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release .. && \
make && \
make install && \
cd /build && \
rm -rf *