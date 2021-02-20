echo "Starting Build..." && rm -rf /build &&\
mkdir -p /build && \
cd /build && \
pwd && \
wget --no-verbose https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz && \
tar -zxf $gvm_libs_version.tar.gz && \
ls -l /build/ && \
cd /build/*/ && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release .. && \
make && \
make install && \
cd /build && \
rm -rf *