#!/bin/bash
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# set TOSROOT to the head of the tinyos source tree root.
# used to find default PACKAGES_DIR.
#
#
# Env variables used....
#
# TOSROOT	head of the tinyos source tree root.  Used for base of default repo
# PACKAGES_DIR	where packages get stashed.  Defaults to ${BUILD_ROOT}/packages
# REPO_DEST	Where the repository is being built (${TOSROOT}/packaging/repo)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   Examples of reprepo configuration can be found in
#               ${TOSROOT}/packaging/repo/conf.
#

COMMON_FUNCTIONS_SCRIPT=../functions-build.sh
source ${COMMON_FUNCTIONS_SCRIPT}


BUILD_ROOT=$(pwd)
CODENAME=squeeze

SOURCENAME=tinyos-tools
SOURCEVERSION=1.4.3
SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
#PACKAGE_RELEASE=1
PREFIX=/usr
MAKE="make -j8"

download()
{
  mkdir -p ${SOURCEDIRNAME}
  cp -R ${TOSROOT}/tools ${SOURCEDIRNAME}
  cp -R ${TOSROOT}/licenses ${SOURCEDIRNAME}
}

build()
{
  set -e
  (
    cd ${SOURCEDIRNAME}/tools
    ./Bootstrap
    ./configure --prefix=${PREFIX}
    ${MAKE}
  )
}

installto()
{
  cd ${SOURCEDIRNAME}/tools
  ${MAKE} DESTDIR=${INSTALLDIR} install
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${SOURCEVERSION}-${PACKAGE_RELEASE} tinyos-tools.control tinyos-tools.postinst
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} ${PREFIX} tinyos-tools.spec
}

cleanbuild(){
  remove ${SOURCEDIRNAME}
}

cleandownloaded(){
  remove ${SOURCEFILENAME} ${PATCHES}
}

cleaninstall(){
  remove ${INSTALLDIR}
}

#main function
case $1 in
  test)
    installto
#   cd ${BUILD_ROOT}
#   package_deb
    ;;

  download)
    download
    ;;
	
	
  clean)
    cleanbuild
    ;;

  veryclean)
    cleanbuild
    cd ${BUILD_ROOT}
    cleandownloaded
    ;;

  deb)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    cd ${BUILD_ROOT}
    download
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    cd ${BUILD_ROOT}
    package_deb
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  sign)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    if [[ -z "$2" ]]; then
        dpkg-sig -s builder ${PACKAGES_DIR}/*
    else
        dpkg-sig -s builder -k $2 ${PACKAGES_DIR}/*
    fi
    ;;

  rpm)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    cd ${BUILD_ROOT}
    download
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    cd ${BUILD_ROOT}
    package_rpm
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  repo)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    if [[ -z "${REPO_DEST}" ]]; then
      REPO_DEST=${TOSROOT}/packaging/repo
    fi
    echo -e "\n*** Building Repository: [${CODENAME}] -> ${REPO_DEST}"
    echo -e   "*** Using packages from ${PACKAGES_DIR}\n"
    find ${PACKAGES_DIR} -iname "*.deb" -exec reprepro -b ${REPO_DEST} includedeb ${CODENAME} '{}' \;
    ;;

  local)
    setup_local_target
    cd ${BUILD_ROOT}
    download
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    ;;
    
  tarball)
    cd ${BUILD_ROOT}
    download
    tar -cjf ${SOURCEDIRNAME}.tar.bz2 ${SOURCEDIRNAME}
    ;;

  *)
    echo -e "\n./build.sh <target>"
    echo -e "    local | rpm | deb | sign | repo | clean | veryclean | download | tarball"
esac
