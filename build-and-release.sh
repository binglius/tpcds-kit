#!/bin/bash

# TPC-DS Toolkit Build and Release Script
# Compiles tools and creates complete release package

VERSION="2.10.0"
RELEASE_DIR="tpcds-toolkit-${VERSION}"

echo "Building and packaging TPC-DS Toolkit v${VERSION}..."

# Step 1: Clean and build tools
echo "Step 1: Building tools..."
cd tools

# Clean previous build
echo "Cleaning previous build..."
make clean 2>/dev/null || true

# Build configuration
OPTIMIZATION_LEVEL="${1:-O2}"  # Default to O2, allow O3 as parameter
echo "Using optimization level: -${OPTIMIZATION_LEVEL}"

# Compile tools
echo "Compiling tools with static linking..."
if make OS=LINUX LINUX_CFLAGS="-${OPTIMIZATION_LEVEL} -Wall -static"; then
    echo "✓ Build successful"
else
    echo "✗ Build failed"
    exit 1
fi

# Verify executables
echo "Verifying executables..."
for tool in dsdgen dsqgen distcomp checksum mkheader; do
    if [ -x "$tool" ]; then
        echo "✓ $tool built successfully"
    else
        echo "✗ $tool not found or not executable"
        exit 1
    fi
done

# Strip debug symbols to reduce size
echo "Stripping debug symbols..."
echo "Before strip:"
ls -lh dsdgen dsqgen distcomp checksum mkheader | awk '{print $9 ": " $5}'
strip dsdgen dsqgen distcomp checksum mkheader
echo "After strip:"
ls -lh dsdgen dsqgen distcomp checksum mkheader | awk '{print $9 ": " $5}'
echo "✓ Debug symbols stripped"

cd ..

# Step 2: Create release package
echo "Step 2: Creating release package..."
rm -rf ~/${RELEASE_DIR}
mkdir -p ~/${RELEASE_DIR}

# Copy core directories
echo "Copying core directories..."
cp -r query_templates answer_sets specification tests ~/${RELEASE_DIR}/

# Copy compiled tools
echo "Copying compiled tools..."
cp tools/dsdgen tools/dsqgen tools/distcomp tools/checksum tools/mkheader ~/${RELEASE_DIR}/

# Copy data and configuration files
echo "Copying data files..."
cp tools/*.dst tools/tpcds.idx ~/${RELEASE_DIR}/ 2>/dev/null || echo "Some data files may not exist, continuing..."

# Copy documentation
echo "Copying documentation..."
cp tools/*.docx tools/*.doc tools/README tools/HISTORY tools/ReleaseNotes.txt tools/PORTING.NOTES ~/${RELEASE_DIR}/ 2>/dev/null || true
cp tools/*.sql tools/tpcds_20080910.sum ~/${RELEASE_DIR}/ 2>/dev/null || true
cp EULA.txt README.md ~/${RELEASE_DIR}/ 2>/dev/null || true

# Create version and build info
echo "Creating version file..."
cat > ~/${RELEASE_DIR}/VERSION.txt << EOF
TPC-DS Toolkit v${VERSION} - Complete Release Package
Built on: $(date)
Architecture: $(uname -m)
OS: $(uname -s)
Compiler: $(gcc --version | head -1)
Build flags: -O2 -Wall -static
EOF

# Set executable permissions
chmod +x ~/${RELEASE_DIR}/dsdgen ~/${RELEASE_DIR}/dsqgen ~/${RELEASE_DIR}/distcomp ~/${RELEASE_DIR}/checksum ~/${RELEASE_DIR}/mkheader

# Step 3: Test tools
echo "Step 3: Testing tools..."
cd ~/${RELEASE_DIR}
echo "Testing dsdgen..."
./dsdgen -h > /dev/null && echo "✓ dsdgen works" || echo "✗ dsdgen failed"
echo "Testing dsqgen..."
./dsqgen -h > /dev/null && echo "✓ dsqgen works" || echo "✗ dsqgen failed"

echo ""
echo "🎉 Release package created successfully!"
echo "Location: ~/${RELEASE_DIR}"
echo "Size: $(du -sh ~/${RELEASE_DIR} | cut -f1)"
echo ""
echo "Contents:"
ls -la ~/${RELEASE_DIR}/
echo ""
echo "Ready to distribute!"
