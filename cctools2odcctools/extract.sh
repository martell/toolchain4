#!/bin/bash

set -e

. ../bash-tools.sh

CCTOOLSNAME=cctools
CCTOOLSVERS=782
LD64NAME=ld64
LD64VERS=85.2.1
LD64DISTFILE=${LD64NAME}-${LD64VERS}.tar.gz
OSXVER=10.5

TOPSRCDIR=`pwd`

MAKEDISTFILE=0
UPDATEPATCH=0
# To use MacOSX headers set USESDK to 999.
#USESDK=999
USESDK=1
FOREIGNHEADERS=

while [ $# -gt 0 ]; do
    case $1 in
	--distfile)
	    shift
	    MAKEDISTFILE=1
	    ;;
	--updatepatch)
	    shift
	    UPDATEPATCH=1
	    ;;
	--nosdk)
	    shift
	    USESDK=0
	    ;;
	--help)
	    echo "Usage: $0 [--help] [--distfile] [--updatepatch] [--nosdk]" 1>&2
	    exit 0
	    ;;
	--vers)
	    shift
	    CCTOOLSVERS=$1
	    shift
	    ;;
	--foreignheaders)
	    shift
	    FOREIGNHEADERS=-foreign-headers
	    ;;
	--osxver)
	    shift
	    OSXVER=$1
	    shift
	    ;;
	*)
	    echo "Unknown option $1" 1>&2
	    exit 1
    esac
done

CCTOOLSDISTFILE=${CCTOOLSNAME}-${CCTOOLSVERS}.tar.gz
DISTDIR=odcctools-${CCTOOLSVERS}${FOREIGNHEADERS}

if [[ -z $FOREIGNHEADERS ]] ; then
    USE_OSX_MACHINE_H=1
fi

if [ "`tar --help | grep -- --strip-components 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
elif [ "`tar --help | grep bsdtar 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
else
    TARSTRIP=--strip-path
fi

PATCHFILESDIR=${TOPSRCDIR}/patches-${CCTOOLSVERS}

#PATCHFILES=`cd "${PATCHFILESDIR}" && find * -type f \! -path \*/.svn\* | sort`

if [[ ! ${USE_OSX_MACHINE_H} ]] ; then
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff as/arm.c.diff \
as/bignum.diff as/driver.c.diff as/getc_unlocked.diff as/input-scrub.diff \
as/messages.diff as/relax.diff as/use_PRI_macros.diff \
include/mach/machine.diff include/stuff/bytesex-floatstate.diff \
ld64/FileAbstraction-inline.diff ld64/ld_cpp_signal.diff \
ld64/Options-config_h.diff ld64/Options-ctype.diff \
ld64/Options-defcross.diff ld64/Options_h_includes.diff \
ld64/Options-stdarg.diff ld64/remove_tmp_math_hack.diff \
ld64/Thread64_MachOWriterExecutable.diff ld64/ld_createReader_typename.diff \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
misc/libtool-ldpath.diff misc/libtool-pb.diff misc/ranlibname.diff \
misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff misc/libtool_lipo_transform.diff \
otool/nolibmstub.diff otool/noobjc.diff \
ld64/LTOReader-setasmpath.diff include/mach/machine_armv7.diff \
ld/ld-nomach.diff libstuff/cmd_with_prefix.diff ld64/cstdio.diff \
misc/with_prefix.diff misc/bootstrap_h.diff"

else
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff as/arm.c.diff \
as/bignum.diff as/driver.c.diff as/getc_unlocked.diff as/input-scrub.diff \
as/messages.diff as/relax.diff \
include/mach/machine.diff include/stuff/bytesex-floatstate.diff \
ld64/FileAbstraction-inline.diff ld64/ld_cpp_signal.diff \
ld64/Options-config_h.diff ld64/Options-ctype.diff \
ld64/Options-defcross.diff ld64/Options_h_includes.diff \
ld64/Options-stdarg.diff ld64/remove_tmp_math_hack.diff \
ld64/Thread64_MachOWriterExecutable.diff ld64/ld_createReader_typename.diff \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
misc/libtool-ldpath.diff misc/libtool-pb.diff misc/ranlibname.diff \
misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff misc/libtool_lipo_transform.diff \
otool/nolibmstub.diff otool/noobjc.diff \
ld64/LTOReader-setasmpath.diff include/mach/machine_armv7.diff \
ld/ld-nomach.diff libstuff/cmd_with_prefix.diff ld64/cstdio.diff \
misc/with_prefix.diff misc/bootstrap_h.diff"

fi

ADDEDFILESDIR=${TOPSRCDIR}/files

if [[ ! "$(uname-bt)" == "Windows" ]] ; then
	PATCH_POSIX=--posix
fi

if [ -d "${DISTDIR}" ]; then
    echo "${DISTDIR} already exists. Please move aside before running" 1>&2
    exit 1
fi

mkdir -p ${DISTDIR}
[[ ! -f "${CCTOOLSDISTFILE}" ]] && wget http://www.opensource.apple.com/tarballs/cctools/${CCTOOLSDISTFILE}

tar ${TARSTRIP}=1 -xf ${CCTOOLSDISTFILE} -C ${DISTDIR} > /dev/null 2>&1
# Fix dodgy timestamps.
find ${DISTDIR} | xargs touch

[[ ! -f "${LD64DISTFILE}" ]] && wget http://www.opensource.apple.com/tarballs/ld64/${LD64DISTFILE}
mkdir -p ${DISTDIR}/ld64
tar ${TARSTRIP}=1 -xf ${LD64DISTFILE} -C ${DISTDIR}/ld64
rm -rf ${DISTDIR}/ld64/FireOpal
find ${DISTDIR}/ld64 ! -perm +200 -exec chmod u+w {} \;
find ${DISTDIR}/ld64/doc/ -type f -exec cp "{}" ${DISTDIR}/man \;

# Clean the source a bit
find ${DISTDIR} -name \*.orig -exec rm -f "{}" \;
rm -rf ${DISTDIR}/{cbtlibs,dyld,file,gprof,libdyld,mkshlib,profileServer}

if [[ $USESDK -eq 999 ]] || [[ ! "$FOREIGNHEADERS" = "-foreign-headers" ]]; then
    if [ "$(uname -s)" = "Darwin" ] ; then
	SDKROOT=/Developer/SDKs/MacOSX${OSXVER}.sdk
    else
	SDKROOT=${TOPSRCDIR}/../sdks/MacOSX${OSXVER}.sdk
    fi
    echo "Merging content from $SDKROOT"
    if [ ! -d "$SDKROOT" ]; then
	echo "$SDKROOT must be present" 1>&2
	exit 1
    fi

    mv ${DISTDIR}/include/mach/machine.h ${DISTDIR}/include/mach/machine.h.new;
    for i in mach architecture i386 libkern sys; do
	tar cf - -C "$SDKROOT/usr/include" $i | tar xf - -C ${DISTDIR}/include
    done

    if [[ ! ${USE_OSX_MACHINE_H} ]] ; then
	mv ${DISTDIR}/include/mach/machine.h.new ${DISTDIR}/include/mach/machine.h;
    fi

    rm ${DISTDIR}/include/sys/cdefs.h
    rm ${DISTDIR}/include/sys/types.h
    rm ${DISTDIR}/include/sys/select.h

    for f in ${DISTDIR}/include/libkern/OSByteOrder.h; do
	sed -e 's/__GNUC__/__GNUC_UNUSED__/g' < $f > $f.tmp
	mv -f $f.tmp $f
    done
fi

# process source for mechanical substitutions
echo "Removing #import"
find ${DISTDIR} -type f -name \*.[ch] | while read f; do
    sed -e 's/^#import/#include/' < $f > $f.tmp
    mv -f $f.tmp $f
done

echo "Removing __private_extern__"
find ${DISTDIR} -type f -name \*.h | while read f; do
    sed -e 's/^__private_extern__/extern/' < $f > $f.tmp
    mv -f $f.tmp $f
done

set +e

INTERACTIVE=0
echo "Applying patches"
for p in ${PATCHFILES}; do
    dir=`dirname $p`
    if [ $INTERACTIVE -eq 1 ]; then
	read -p "Apply patch $p? " REPLY
    else
	echo "Applying patch $p"
    fi
    pushd ${DISTDIR}/$dir > /dev/null
    patch --backup $PATCH_POSIX -p0 < ${PATCHFILESDIR}/$p
    if [ $? -ne 0 ]; then
	echo "There was a patch failure. Please manually merge and exit the sub-shell when done"
	$SHELL
	if [ $UPDATEPATCH -eq 1 ]; then
	    find . -type f | while read f; do
		if [ -f "$f.orig" ]; then
		    diff -u -N "$f.orig" "$f"
		fi
	    done > ${PATCHFILESDIR}/$p
	fi
    fi
    find . -type f -name \*.orig -exec rm -f "{}" \;
    popd > /dev/null
done

set -e

echo "Adding new files"
tar cf - --exclude=CVS --exclude=.svn -C ${ADDEDFILESDIR} . | tar xvf - -C ${DISTDIR}

if [ -z $FOREIGNHEADERS ] ; then
	echo "Removing include/foreign"
	rm -rf ${DISTDIR}/include/foreign
else
	echo "Removing include/mach/ppc (so include/foreign/mach/ppc is used)"
	rm -rf ${DISTDIR}/include/mach/ppc
fi

echo "Deleting cruft"
find ${DISTDIR} -name Makefile -exec rm -f "{}" \;
find ${DISTDIR} -name \*~ -exec rm -f "{}" \;
find ${DISTDIR} -name .\#\* -exec rm -f "{}" \;

pushd ${DISTDIR} > /dev/null
autoheader
autoconf
rm -rf autom4te.cache
popd > /dev/null

if [ $MAKEDISTFILE -eq 1 ]; then
    DATE=$(date +%Y%m%d)
    mv ${DISTDIR} ${DISTDIR}-$DATE
    tar jcf ${DISTDIR}-$DATE.tar.bz2 ${DISTDIR}-$DATE
fi
patch odcctools-${CCTOOLSVERS}${FOREIGNHEADERS}/misc/Makefile.in < $PATCHFILESDIR/misc/Makefile.in.diff
