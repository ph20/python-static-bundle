et -e  # Exit on error

# Define versions
OPENSSL_VERSION="openssl-1.1.1k"
ZLIB_VERSION="zlib-1.2.12"
LIBFFI_VERSION="libffi-3.3"
PYTHON_VERSION="3.8.18"

# Define the final installation directory
FINAL_INSTALL_DIR="/opt/python3.8-static"

# Remove the final installation directory if it exists, then recreate it
if [ -d "$FINAL_INSTALL_DIR" ]; then
    echo "Removing existing directory: $FINAL_INSTALL_DIR"
    sudo rm -rf "$FINAL_INSTALL_DIR"
fi
echo "Creating directory: $FINAL_INSTALL_DIR"
sudo mkdir -p "$FINAL_INSTALL_DIR"
sudo chown "$(whoami):$(whoami)" "$FINAL_INSTALL_DIR"

# Define build and downloads directories within the current directory
BUILD_DIR="$(pwd)/build-static-python"
DOWNLOADS_DIR="${BUILD_DIR}/downloads"
mkdir -p "$BUILD_DIR" "$DOWNLOADS_DIR"

# Clean up previously extracted directories to ensure a fresh build environment
for dir in "$OPENSSL_VERSION" "$ZLIB_VERSION" "$LIBFFI_VERSION" "Python-${PYTHON_VERSION}"; do
    if [ -d "$BUILD_DIR/$dir" ]; then
        echo "Removing existing directory: $BUILD_DIR/$dir"
        rm -rf "$BUILD_DIR/$dir"
    fi
done

# Function to download a file if it doesn't already exist
download_if_not_exists() {
  local url=$1
  local target_path=$2
  if [ ! -f "$target_path" ]; then
    echo "Downloading $target_path..."
    wget -O "$target_path" "$url"
  else
    echo "File $target_path already exists, skipping download."
  fi
}

# Download sources
download_if_not_exists "https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz" "${DOWNLOADS_DIR}/${OPENSSL_VERSION}.tar.gz"
download_if_not_exists "https://www.zlib.net/fossils/${ZLIB_VERSION}.tar.gz" "${DOWNLOADS_DIR}/${ZLIB_VERSION}.tar.gz"
download_if_not_exists "https://github.com/libffi/libffi/releases/download/v3.3/${LIBFFI_VERSION}.tar.gz" "${DOWNLOADS_DIR}/${LIBFFI_VERSION}.tar.gz"
download_if_not_exists "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz" "${DOWNLOADS_DIR}/Python-${PYTHON_VERSION}.tar.xz"

# Extract sources
tar -xf "${DOWNLOADS_DIR}/${OPENSSL_VERSION}.tar.gz" -C "$BUILD_DIR"
tar -xf "${DOWNLOADS_DIR}/${ZLIB_VERSION}.tar.gz" -C "$BUILD_DIR"
tar -xf "${DOWNLOADS_DIR}/${LIBFFI_VERSION}.tar.gz" -C "$BUILD_DIR"
tar -xf "${DOWNLOADS_DIR}/Python-${PYTHON_VERSION}.tar.xz" -C "$BUILD_DIR"

# Environment variables for Python build to find local dependencies
export LD_LIBRARY_PATH="$FINAL_INSTALL_DIR/lib:$LD_LIBRARY_PATH"
export LDFLAGS="-Wl,-rpath,$FINAL_INSTALL_DIR/lib -L$FINAL_INSTALL_DIR/lib"
export CPPFLAGS="-I$FINAL_INSTALL_DIR/include"
export PKG_CONFIG_PATH="$FINAL_INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export PATH="$FINAL_INSTALL_DIR/bin:$PATH"

# Build and install zlib with PIC
cd "$BUILD_DIR/$ZLIB_VERSION"
CFLAGS="-fPIC" ./configure --prefix="$FINAL_INSTALL_DIR" --static
make -j$(nproc) && make install

# Build and install OpenSSL with rpath
cd "$BUILD_DIR/$OPENSSL_VERSION"
./config --prefix="$FINAL_INSTALL_DIR" no-shared -Wl,-rpath,"$FINAL_INSTALL_DIR/lib"
make -j$(nproc) && make install

# Build and install libffi with PIC
cd "$BUILD_DIR/$LIBFFI_VERSION"
./configure --prefix="$FINAL_INSTALL_DIR" --disable-shared --with-pic
make -j$(nproc) && make install

# Build and install Python
cd "$BUILD_DIR/Python-$PYTHON_VERSION"
LDFLAGS="$LDFLAGS" ./configure --prefix="$FINAL_INSTALL_DIR" --with-openssl="$FINAL_INSTALL_DIR" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}"
make -j$(nproc)
make install
cd "$BUILD_DIR/.."
echo "Python 3.8 has been installed to $FINAL_INSTALL_DIR"

$FINAL_INSTALL_DIR/bin/pip3 install --ignore-installed setuptools==69.1.1

#echo "Starting minimization process..."
# Define PREFIX for easier reuse
#PREFIX=${FINAL_INSTALL_DIR}
# Strip debug symbols and unneeded sections
#/usr/bin/strip --strip-debug ${PREFIX}/bin/* || true
#/usr/bin/strip --strip-unneeded ${PREFIX}/lib/*.so || true
#/usr/bin/strip --strip-debug ${PREFIX}/lib/python3.8/lib-dynload/*.so || true
# Delete .la files
#find ${PREFIX}/{lib,libexec} -name "*.la" -delete
#echo "Minimization process completed."

# Define the name and path of the tar.gz archive
ARCHIVE_NAME="python3.8-static-$(date +%Y-%m-%d).tar.gz"
ARCHIVE_PATH="$(pwd)/$ARCHIVE_NAME"

tar --owner=0 --group=0 -czf "$ARCHIVE_PATH" "$FINAL_INSTALL_DIR" -C /

echo "Python 3.8 installation has been archived into $ARCHIVE_PATH"
