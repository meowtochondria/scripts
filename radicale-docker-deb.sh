BUILD_DIR='radicale-deb'
mkdir $BUILD_DIR
cd $BUILD_DIR
wget https://salsa.debian.org/debian/radicale/-/archive/debian/latest/radicale-debian-latest.tar.gz
tar -xzf radicale-debian-latest.tar.gz
wget https://github.com/tsaarni/docker-deb-builder/archive/refs/heads/master.zip -O docker-deb-builder.zip
unzip docker-deb-builder.zip
cd docker-deb-builder-master/
docker build -t docker-deb-builder:22.04 -f Dockerfile-ubuntu-22.04 .
PARENT_DIR=$(dirname $PWD)
./build -i docker-deb-builder:22.04 -o $PARENT_DIR $PARENT_DIR/radicale-debian-latest
