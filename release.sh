#!/bin/bash
VERSION=1.4.7
DIR=btop-$VERSION
ARCH=$(uname -m)
ARCH_DPKG=$(dpkg --print-architecture)
export VERSION=$VERSION

# cleanup
rm -rf release build rpm/BUILDROOT rpm/*RPMS rpm/SOURCES

# build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBTOP_GPU=ON -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build -j $(nproc)
strip -s build/btop

# assets
mkdir -p release/$DIR
cp -r src include Img themes cmake CMakeLists.txt debian btop.desktop btop.metainfo.xml.in manpage.md tests release/$DIR

if [ "$1" == "nightly" ]; then
    # Number of commits since last tag
    LAST_TAG=$(git describe --tags --abbrev=0 2> /dev/null || echo "HEAD")
    # Will return 0 if git is not found
    if [ "$LAST_TAG" = "HEAD" ]; then
        COMMITS=0
    else
        TAG_TS=$(git show -s --format=%ct "$LAST_TAG")
        COMMITS=$(git rev-list --count --since=$((TAG_TS + 1)) HEAD 2> /dev/null || echo 0)
    fi
    echo "Build number: $COMMITS"

    # Increase version number
    sed -i "s/$VERSION-/$VERSION+$COMMITS-/g" release/$DIR/debian/changelog

    # Change package name
    sed -i "s/^btop/btop-nightly/g" release/$DIR/debian/changelog
    sed -i "s/ btop$/ btop-nightly/g" release/$DIR/debian/control

    # Prevent conflict with btop
    sed -i "s/Recommends: systemd/Provides: btop\nRecommends: systemd/g" release/$DIR/debian/control
    sed -i "s/Recommends: systemd/Conflicts: btop\nRecommends: systemd/g" release/$DIR/debian/control
    sed -i "s/Recommends: systemd/Replaces: btop\nRecommends: systemd/g" release/$DIR/debian/control

    VERSION="$VERSION+$COMMITS"
    export VERSION=$VERSION
    mv release/$DIR release/btop-nightly-$VERSION
    DIR=btop-nightly-$VERSION
fi

# Change architecture
sed -i "s/^Architecture:\s\+.*$/Architecture: $ARCH_DPKG/g" release/$DIR/debian/control

# tarball
tar -czf release/$DIR.tar.gz -C release $DIR

# linuxdeploy
wget -qc https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$ARCH.AppImage
chmod +x linuxdeploy-$ARCH.AppImage

# appimage
DESTDIR=../release/$DIR cmake --build build --target install -j $(nproc)
./linuxdeploy-$ARCH.AppImage --appdir release/$DIR -i release/$DIR/Img/icon.svg -d release/$DIR/btop.desktop --output appimage
if [ "$1" == "nightly" ]; then
    mv btop++-$VERSION-$ARCH.AppImage release/btop-nightly-$VERSION-$ARCH.AppImage
else
    mv btop++-$VERSION-$ARCH.AppImage release
fi

rm linuxdeploy-$ARCH.AppImage

# debian package
cd release/$DIR
# Define these 2 env variables for dh_make when running inside a container
if [ -z "$LOGNAME" ]; then
    export LOGNAME=$(whoami)
fi
if [ -z "$USER" ]; then
    export USER=$(whoami)
fi
dh_make --createorig --indep --yes
# Force CMake install step to be included in PATH for debuild
debuild --set-envvar=PATH="$PATH" --no-lintian -us -uc
cd ../..

# rpm package
mkdir -p rpm/SOURCES
cp release/$DIR.tar.gz rpm/SOURCES
if [ "$1" == "nightly" ]; then
    # Create a new spec file for nightly builds
    cp rpm/SPECS/btop.spec rpm/SPECS/btop-nightly.spec
    # Change package name
    sed -i "s/^Name:\s\+btop$/Name: btop-nightly/g" rpm/SPECS/btop-nightly.spec
    sed -i "s/%{name}/btop/g" rpm/SPECS/btop-nightly.spec
    # Increase version number
    sed -i "s/^Version:\s\+.*$/Version: $VERSION/g" rpm/SPECS/btop-nightly.spec
    # Change architecture
    sed -i "s/^BuildArch:\s\+.*$/BuildArch: $ARCH/g" rpm/SPECS/btop-nightly.spec

    rpmbuild -bb --build-in-place --define "_topdir $(pwd)/rpm" rpm/SPECS/btop-nightly.spec
    mv rpm/RPMS/$ARCH/btop-nightly-$VERSION-1.$ARCH.rpm release/btop-nightly-$VERSION.$ARCH.rpm
else
    # Change architecture
    sed -i "s/^BuildArch:\s\+.*$/BuildArch:      $ARCH/g" rpm/SPECS/btop.spec

    rpmbuild -bb --build-in-place --define "_topdir $(pwd)/rpm" rpm/SPECS/btop.spec
    mv rpm/RPMS/$ARCH/btop-$VERSION-1.$ARCH.rpm release/btop-$VERSION.$ARCH.rpm
fi
