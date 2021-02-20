cd /build && \
wget --no-verbose https://github.com/greenbone/openvas-smb/archive/$openvas_smb.tar.gz && \
tar -zxf $openvas_smb.tar.gz && \
cd /build/*/ && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release .. && \
make && \
make install && \
cd /build && \
rm -rf *