#!/bin/bash

mkdir -p /work/shim /work/out

cd /work/shim
tar -xf /opt/shim.tar

make VENDOR_CERT_FILE=/opt/vendor_cert.der EFI_PATH=/usr/lib -j4
make DESTDIR=/work/out EFIDIR=ZeronsoftN install

