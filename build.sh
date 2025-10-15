#!/bin/bash
###----------------------------------------------------------------------------
# TinyGW Build Script - @ENDESGA - 2025 - Made in NZ - CC0 - foss forever
###----------------------------------------------------------------------------

set -euo pipefail

echo "> building TinyGW..."

echo "> installing packages..."
pacman -S --noconfirm --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-binutils mingw-w64-x86_64-gdb
echo "> packages installed."

M="/mingw64"
N="x86_64-w64-mingw32"
V=$(gcc -dumpversion)

G="$M/lib/gcc/$N/$V"
I="tinygw/lib/gcc/$N/$V/include"

echo -n "> creating directory structure..."
rm -rf tinygw
mkdir -p tinygw/bin tinygw/lib/gcc/$N/$V $I tinygw/$N/lib
echo " done"

echo -n "> copying binaries..."
for bin in {gcc,gdb}.exe;
	do cp "$M/bin/$bin" tinygw/bin/; done
for bin in {as,ld}.exe;
	do cp "$M/bin/$bin" tinygw/lib/gcc/$N/$V/; done
for bin in {cc1,collect2,lto-wrapper,lto1}.exe;
	do cp "$G/$bin" tinygw/lib/gcc/$N/$V/; done
cp $G/liblto_plugin*.dll tinygw/lib/gcc/$N/$V/
echo " done"

echo -n "> copying dynamic-link libraries..."
ldd tinygw/bin/{gcc,gdb}.exe | awk '/mingw64/ && $3 {print $3}' | sort -u | while read dll;
	do cp "$dll" tinygw/bin/; done
ldd tinygw/lib/gcc/$N/$V/{as,ld,cc1,collect2,lto-wrapper,lto1}.exe | awk '/mingw64/ && $3 {print $3}' | sort -u | while read dll;
	do cp "$dll" tinygw/lib/gcc/$N/$V/; done
echo " done"

echo -n "> copying headers..."
cp $G/include/*.h $I/
mkdir -p tinygw/$N/include
cp -r $M/include/* tinygw/$N/include/
for dir in c++ ddk gdiplus GL isl KHR libiberty lzma ncurses ncursesw openssl python* readline tcl* tk* tre wrl X11 gdb qt gtk* glib* pango* cairo* atk*;
	do 
		rm -rf $I/$dir
		rm -rf tinygw/$N/include/$dir
	done
echo " done"

echo -n "> copying objects and libraries..."
for obj in crt*.o libgcc*.a;
	do cp $G/$obj tinygw/lib/gcc/$N/$V/; done
for obj in {crt2,crtbegin,crtend,default-manifest,dllcrt2}.o;
	do cp "$M/lib/$obj" tinygw/$N/lib/; done
for lib in {libmingw32,libmingwex,libmsvcrt,libkernel32,libpthread,libuser32,libgdi32,libadvapi32,libshell32,libm,libmoldname}.a;
	do cp "$M/lib/$lib" tinygw/$N/lib/; done
echo " done"

echo ""
echo "> build complete:"
echo "	bin dlls: $(ls tinygw/bin/*.dll 2>/dev/null | wc -l)"
echo "	lib dlls: $(ls tinygw/lib/gcc/$N/$V/*.dll 2>/dev/null | wc -l)"
echo "	gcc headers: $(find $I -type f -name '*.h' 2>/dev/null | wc -l)"
echo "	mingw headers: $(find tinygw/$N/include/ -type f -name '*.h' 2>/dev/null | wc -l)"
echo "	libraries: $(ls tinygw/$N/lib/*.a 2>/dev/null | wc -l)"

echo "	size: $(du -sh tinygw | cut -f1)"
