cd /build && \
wget --no-verbose https://github.com/greenbone/python-gvm/archive/$python_gvm_version.tar.gz && \
tar -zxf $python_gvm_version.tar.gz && \
cd /build/*/ && \
python3 setup.py install && \
cd /build && \
rm -rf *