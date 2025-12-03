#!/bin/bash
################################################################
##
##  TinyGW Build Script
##
##  author(s):
##  ENDESGA - https://x.com/ENDESGA | https://bsky.app/profile/endesga.bsky.social
##
##  https://github.com/ENDESGA/TinyGW
##  2025 - CC0 - FOSS forever
##

set -euo pipefail

echo "> building TinyGW..."

echo "> installing packages..."
pacman -S --noconfirm --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-binutils mingw-w64-x86_64-gdb
echo "> packages installed."

MGW="/mingw64"
TGW="tinygw"
XWMGW="x86_64-w64-mingw32"
GCCV=$(gcc -dumpversion)

MBIN="$MGW/bin"
TBIN="$TGW/bin"
MLGCC="$MGW/lib/gcc/$XWMGW/$GCCV"
TLGCC="$TGW/lib/gcc/$XWMGW/$GCCV"
TMGW="$TGW/$XWMGW"
TGINC="$TLGCC/include"
MPY="$MGW/lib/python3.12"
TPY="$TGW/lib/python3.12"

echo -n "> creating directory structure..."
rm -rf "$TGW"
mkdir -p "$TBIN" "$TLGCC" "$TGINC" "$TMGW/lib" "$TGW/share/gdb/python" "$TPY"
echo " done"

echo -n "> copying binaries..."
for bin in {gcc,gdb,windres}.exe; do
	cp "$MBIN/$bin" "$TBIN/"
done
for bin in {as,ld}.exe; do
	cp "$MBIN/$bin" "$TLGCC/"
done
for bin in {cc1,collect2,lto-wrapper,lto1}.exe; do
	cp "$MLGCC/$bin" "$TLGCC/"
done
cp $MLGCC/liblto_plugin*.dll "$TLGCC/"
echo " done"

echo -n "> copying dynamic-link libraries..."
ldd "$TBIN"/{gcc,gdb}.exe | awk '/mingw64/ && $3 {print $3}' | sort -u | while read dll; do
	cp "$dll" "$TBIN/"
done
ldd "$TLGCC"/{as,ld,cc1,collect2,lto-wrapper,lto1}.exe | awk '/mingw64/ && $3 {print $3}' | sort -u | while read dll; do
	cp "$dll" "$TLGCC/"
done
echo " done"

echo -n "> copying headers..."
cp $MLGCC/include/*.h "$TGINC/"
mkdir -p "$TMGW/include"
for ext in h idl inl; do
	cp "$MGW/include"/*.$ext "$TMGW/include/" 2>/dev/null || true
done
for dir in psdk_inc python3.12 sdks sec_api sys tcl8.6 tk8.6; do
	cp -r "$MGW/include/$dir" "$TMGW/include/" 2>/dev/null || true
done
echo " done"

echo -n "> copying objects and libraries..."
for obj in crt*.o libgcc*.a; do
	cp $MLGCC/$obj "$TLGCC/"
done
for obj in {crt2,crtbegin,crtend,default-manifest,dllcrt2}.o; do
	cp "$MGW/lib/$obj" "$TMGW/lib/"
done
for lib in {libmingw32,libmingwex,libmsvcrt,libkernel32,libpthread,libuser32,libgdi32,libadvapi32,libshell32,libm,libmoldname,libgcc_s,libwinmm}.a; do
	cp "$MGW/lib/$lib" "$TMGW/lib/"
done
echo " done"

echo -n "> copying gdb python support..."
cp -r "$MGW/share/gdb/python/gdb" "$TGW/share/gdb/python/"
cp "$MPY"/*.py "$TPY/"
for dir in collections encodings importlib json lib-dynload re; do
	cp -r "$MPY/$dir" "$TPY/"
done
echo " done"

echo ""
echo "> build complete:"
echo "	bin dlls: $(ls "$TBIN"/*.dll 2>/dev/null | wc -l)"
echo "	lib dlls: $(ls "$TLGCC"/*.dll 2>/dev/null | wc -l)"
echo "	gcc headers: $(find "$TGINC" -type f -name '*.h' 2>/dev/null | wc -l)"
echo "	mingw headers: $(find "$TMGW/include" -type f -name '*.h' 2>/dev/null | wc -l)"
echo "	libraries: $(ls "$TMGW/lib"/*.a 2>/dev/null | wc -l)"
echo "	size: $(du -sh "$TGW" | cut -f1)"

