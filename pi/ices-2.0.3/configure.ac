dnl Process this file with autoconf to produce a configure script.
dnl
dnl Options refactored to allow all audio input modules to be enabled/disabled
dnl by Thomas B. "dm8tbr" Ruecker <thomas.ruecker@tieto.com>
dnl
AC_INIT([IceS], [2.0.3], [icecast@xiph.org])
AC_PREREQ(2.54)
AC_CONFIG_SRCDIR([src/ices.c])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE
AM_CONFIG_HEADER(config.h)
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_LIBTOOL

dnl Set some options based on environment

dnl BSD headers break when _XOPEN_SOURCE is defined but without it seems
dnl to be fine
if test -n "$GCC"; then
    AC_DEFINE(_GNU_SOURCE, ,[Define if you have POSIX and GNU specifications])
    XIPH_VAR_APPEND([XIPH_CPPFLAGS], [-ffast-math -fsigned-char])
    XIPH_VAR_APPEND([DEBUG],[-g])
    XIPH_VAR_APPEND([PROFILE],[-g -pg])
else
    case "$host" in 
        *-*-irix*)
            XIPH_VAR_APPEND([DEBUG], [-g -signed -D_REENTRANT])
            XIPH_VAR_APPEND([XIPH_CPPFLAGS],[-O2 -w -signed -D_REENTRANT])
            XIPH_VAR_APPEND([PROFILE],[-p -g3 -O2 -signed -D_REENTRANT])
            ;;
        *-*-solaris*)
            AC_DEFINE(__EXTENSIONS__, 1, [define to 1 to resolve header problem on solaris])
            XIPH_VAR_APPEND([DEBUG],[-v -g -D_REENTRANT])
            XIPH_VAR_APPEND([XIPH_CPPFLAGS],[-xO4 -fast -w -fsimple -native -xcg92 -D_REENTRANT])
            XIPH_VAR_APPEND([PROFILE],[-v -xpg -g -xO4 -fast -native -fsimple -xcg92 -Dsuncc -D_REENTRANT])
            ;;
        *)
            DEBUG="-g -D_REENTRANT"
            XIPH_CPPFLAGS="-O -D_REENTRANT"
            PROFILE="-g -p -D_REENTRANT" 
            ;;
    esac
fi

dnl Checks for programs.

dnl Checks for libraries.

dnl Checks for header files.
AC_HEADER_STDC
AC_HEADER_TIME
AC_CHECK_HEADERS([stropts.h sys/timeb.h sys/select.h])

dnl ================================================================
dnl Check for OSS
dnl ================================================================

AC_ARG_ENABLE(oss,
 	[AC_HELP_STRING([--disable-oss],
 	[OSS support [default=autodetect]])],,
 	enable_oss=yes)

if test "x$enable_oss" = xyes ; then
    AC_CHECK_HEADER(sys/soundcard.h, have_oss=yes, have_oss=no)
    AC_CHECK_HEADER(machine/soundcard.h, have_oss=yes, )
    if test "$have_oss" = yes; then
	AC_DEFINE(HAVE_OSS,,[Define to enable OSS input module])
    fi
else
    have_oss=no
fi

AM_CONDITIONAL(HAVE_OSS,test "$have_oss" = yes)


dnl ================================================================
dnl Check for Sun audio
dnl ================================================================

AC_C_BIGENDIAN
AC_ARG_ENABLE(sun-audio,
    AC_HELP_STRING([--disable-sun-audio],
                   [Sun audio input [default=autodetect]]),
    enable_sun="$enableval",
    enable_sun=yes
)
if test x$enable_sun = xyes; then
   AC_CHECK_HEADER(sys/audioio.h, have_sun_audio=yes, have_sun_audio=no)

   if test "$have_sun_audio" = yes; then
       AC_DEFINE(HAVE_SUN_AUDIO,,[Define to enable sun audio input module])
   fi
else
    have_sun_audio=no
fi

AM_CONDITIONAL(HAVE_SUN_AUDIO,test "$have_sun_audio" = yes)

dnl ================================================================
dnl Check for ALSA audio
dnl ================================================================

AC_ARG_ENABLE(alsa,
 	[AC_HELP_STRING([--disable-alsa],
 	[ALSA support [default=autodetect]])],,
 	enable_alsa=yes)

if test "x$enable_alsa" = xyes ; then
    AC_CHECK_HEADER(alsa/asoundlib.h, have_alsa=yes, have_alsa=no)

    if test "$have_alsa" = yes; then
        ALSA_LIBS="-lasound"
	AC_DEFINE(HAVE_ALSA, ,[Define to enable ALSA input module])
    fi
else
    have_alsa=no
fi

AM_CONDITIONAL(HAVE_ALSA,test "$have_alsa" = yes)

dnl ================================================================
dnl Check for RoarAudio
dnl ================================================================

AC_ARG_ENABLE(roaraudio,
 	[AC_HELP_STRING([--disable-roaraudio],
 	[Roaraudio support [default=autodetect]])],,
 	enable_roaraudio=yes)

if test "x$enable_roaraudio" = xyes ; then
#    PKG_CHECK_MODULES(RoarAudio, [libroar >= 0.4.0], have_roaraudio=yes, have_roaraudio=no)
    echo -n "checking for libroar... "
    if roar-config --compare-versions current ge 0.4.0
    then
        have_roaraudio=yes
    else
        have_roaraudio=no
    fi

    if test "$have_roaraudio" = yes; then
	ROARAUDIO_LIBS="`roar-config --libs`"
	ROARAUDIO_CFLAGS="`roar-config --cflags`"
        XIPH_VAR_APPEND([XIPH_CFLAGS], [$ROARAUDIO_CFLAGS])
        AC_DEFINE(HAVE_ROARAUDIO, ,[Define to enable RoarAudio input module])
        echo "ok"
    else
        echo "failed"
    fi
else
    have_roaraudio=no
fi

AM_CONDITIONAL(HAVE_ROARAUDIO,test "$have_roaraudio" = yes)


dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST

dnl Check for types
AC_CHECK_TYPES([uint64_t],,AC_ERROR([could not find a uint64_t type]))

dnl Checks for library functions.

AC_CHECK_FUNCS([gettimeofday ftime])

XIPH_PATH_XML
XIPH_VAR_APPEND([XIPH_CFLAGS], [$XML_CFLAGS])
XIPH_VAR_PREPEND([XIPH_LIBS], [$XML_LIBS])

XIPH_PATH_SHOUT(, AC_MSG_ERROR([must have libshout installed!]))
if test "$SHOUT_THREADSAFE" != "yes"
then
  AC_MSG_ERROR([This libshout isn't threadsafe])
fi

XIPH_VAR_APPEND([XIPH_CPPFLAGS], [$SHOUT_CPPFLAGS])
XIPH_VAR_APPEND([XIPH_CFLAGS], [$SHOUT_CFLAGS])
XIPH_VAR_PREPEND([XIPH_LIBS], [$SHOUT_LIBS])

XIPH_PATH_VORBIS(, AC_MSG_ERROR([must have Ogg Vorbis v1.0 or above installed!]))
XIPH_VAR_APPEND([XIPH_CPPFLAGS], [$VORBIS_CFLAGS $VORBISENC_CFLAGS])
XIPH_VAR_PREPEND([XIPH_LIBS], [$VORBISENC_LIBS $VORBIS_LIBS])

dnl Make substitutions

AC_SUBST(ALSA_LIBS)
AC_SUBST(ROARAUDIO_LIBS)
AC_SUBST(ROARAUDIO_CFLAGS)
AC_SUBST(XML_LIBS)
AC_SUBST(XML_CFLAGS)
AC_SUBST(LIBTOOL_DEPS)
AC_SUBST(DEBUG)
AC_SUBST(PROFILE)
AC_SUBST(XIPH_CFLAGS)
AC_SUBST(XIPH_CPPFLAGS)
AC_SUBST(XIPH_LIBS)

AC_OUTPUT(
  Makefile
  conf/Makefile 
  doc/Makefile 
  src/Makefile 
   src/common/log/Makefile 
   src/common/timing/Makefile
   src/common/thread/Makefile
   src/common/avl/Makefile
)

echo "

                Build with alsa:           $have_alsa
                Build with OSS:            $have_oss
                Build with Sun audio:      $have_sun_audio
                Build with RoarAudio:      $have_roaraudio

"
