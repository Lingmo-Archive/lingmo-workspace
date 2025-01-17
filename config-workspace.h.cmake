/* config-workspace.h.  Generated by cmake from config-workspace.h.cmake  */

/* Defines if your system has the libfontconfig library */
#cmakedefine HAVE_FONTCONFIG 1

/* Define to 1 if you have the <sys/time.h> header file. */
#cmakedefine HAVE_SYS_TIME_H 1

/* Define to 1 if you have libxcrypt with crypt_gensalt and the shadow package is linked against it */
#cmakedefine01 HAVE_CRYPT_GENSALT

/* place where lingmo-frameworks things are installed */
#define LINGMO_RELATIVE_DATA_INSTALL_DIR "@LINGMO_RELATIVE_DATA_INSTALL_DIR@"

#define WORKSPACE_VERSION_STRING "${PROJECT_VERSION}"
#define PROJECT_VERSION_MAJOR ${PROJECT_VERSION_MAJOR}
#define PROJECT_VERSION_MINOR ${PROJECT_VERSION_MINOR}
#define PROJECT_VERSION_PATCH ${PROJECT_VERSION_PATCH}

#cmakedefine01 UBUNTU_LOCALE
#cmakedefine01 GLIBC_LOCALE_AUTO
#cmakedefine01 GLIBC_LOCALE_GENERATED
#cmakedefine GLIBC_LOCALE
