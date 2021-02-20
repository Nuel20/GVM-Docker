cd /build && \
wget --no-verbose https://github.com/greenbone/gsa/archive/$gsa_version.tar.gz && \
tar -zxf $gsa_version.tar.gz && \
cd /build/*/ && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release .. && \
make && \
make install && \
cd /build && \
rm -rf *