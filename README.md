# Build Static Python 3.8 on Red Hat-based Systems

This guide explains how to build Python 3.8 statically, including essential libraries (OpenSSL, zlib, libffi), and install it into `/opt/python3.8-static`.

## Prerequisites

Ensure you have development tools and `wget` installed. Run:

```bash
sudo yum groupinstall "Development Tools"
sudo yum install wget
```

## Building Python 3.8

1. **Download the Script**: Get the `build-python3-static.sh` script and make it executable:

    ```bash
    chmod +x build-python3-static.sh
    ```

2. **Run the Script**: Execute the script to start the building and installation process:

    ```bash
    ./build-python3-static.sh
    ```

The script will handle downloading, building, and installing Python 3.8 with all necessary dependencies into `/opt/python3.8-static`. Modify `FINAL_INSTALL_DIR` in the script for a different location.

**Note:** Installation to `/opt` requires `sudo` access. Ensure permissions are adequate.
