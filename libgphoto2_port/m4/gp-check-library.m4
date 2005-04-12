dnl @synopsis GP_CHECK_LIBRARY([VARNAMEPART],[libname],[VERSION-REQUIREMENT],[headername],[functionname],[ACTION-IF-FOUND],[ACTION-IF-NOT-FOUND],[OPTIONAL-REQUIRED-ETC],[WHERE-TO-GET-IT])
dnl
dnl Checks for the presence of a certain library.
dnl
dnl Parameters:
dnl
dnl    VARNAMEPART            partial variable name for variable definitions
dnl    libname                name of library
dnl    VERSION-REQUIREMENT    check for the version using pkg-config
dnl                           default: []
dnl    headername             name of header file
dnl                           default: []
dnl    functionname           name of function name in library
dnl                           default: []
dnl    ACTION-IF-FOUND        shell action to execute if found
dnl                           default: []
dnl    ACTION-IF-NOT-FOUND    shell action to execute if not found
dnl                           default: []
dnl    OPTIONAL-REQUIRED-ETC  one of "mandatory", "default-on", "default-off"
dnl                           default: [mandatory]
dnl    WHERE-TO-GET-IT        place where to find the library
dnl                           default: []
dnl
dnl What the ACTION-IFs can do:
dnl
dnl   * change the variable have_[$1] to "yes" or "now" and thus change
dnl     the outcome of the test
dnl   * execute additional checks to define more specific variables, e.g.
dnl     for different API versions
dnl
dnl Results after calling it:
dnl
dnl    AM_CONDITIONAL([HAVE_VARPREFIX],[ if found ])
dnl    AM_SUBST([have_VARPREFIX], [ "yes" if found, "no" if not found ])
dnl    AM_SUBST([VARPREFIX_CFLAGS],[ -I, -D and stuff ])
dnl    AM_SUBST([VARPREFIX_LIBS], [ /path/to/libname.la ])
dnl
dnl Parameters to ./configure which influence the results:
dnl
dnl   * VARNAMEPART_LIBS=/foobar/arm-palmos/lib/libname.la
dnl     VARNAMEPART_CFLAGS=-I/foobar/include
dnl   * --without-libfoo
dnl   * --with-libfoo=/usr/local
dnl   * --with-libfoo-include-dir=/foobar/include
dnl   * --with-libfoo-lib=/foobar/arm-palmos/lib
dnl   * --with-libfoo=autodetect
dnl
dnl Examples:
dnl    GP_CHECK_LIBRARY([LIBEXIF], [libexif])dnl
dnl    GP_CHECK_LIBRARY([LIBEXIF], [libexif-gtk], [>= 0.3.3])dnl
dnl
dnl Possible enhancements:
dnl
dnl   * Derive VAR_PREFIX directly from libname
dnl     This will change the calling conventions, so be aware of that.
dnl   * Give names of a header file and function name and to a test
dnl     compilation.
dnl
AC_DEFUN([_GP_CHECK_LIBRARY_SOEXT],[dnl
AC_MSG_CHECKING([for dynamic library extension])
soext=""
case "$host" in
	*linux*)	soext=".so" ;;
	*sunos*)	soext=".so" ;;
	*bsd*)		soext=".so" ;;
	*darwin*)	soext=".dylib" ;;
	*w32*)		soext=".dll" ;;
esac
if test "x$soext" = "x"; then
	soext=".so"
	AC_MSG_RESULT([${soext}])
	AC_MSG_WARN([
Host system "${host}" not recognized, defaulting to "${soext}".
])
else
	AC_MSG_RESULT([${soext}])
fi
])dnl
dnl
AC_DEFUN([_GP_CHECK_LIBRARY],[
# ----------------------------------------------------------------------
# [GP_CHECK_LIBRARY]([$1],[$2],[$3],
#                    [$4],[$5],
#                    [...],[...],[$8])
m4_ifval([$9],[dnl
# $9
])dnl
# ----------------------------------------------------------------------
dnl
AC_REQUIRE([GP_CONFIG_MSG])dnl
AC_REQUIRE([GP_PKG_CONFIG])dnl
AC_REQUIRE([_GP_CHECK_LIBRARY_SOEXT])dnl
dnl Use _CFLAGS and _LIBS given to configure.
dnl This makes it possible to set these vars in a configure script
dnl and AC_CONFIG_SUBDIRS this configure.
AC_ARG_VAR([$1][_CFLAGS], [CFLAGS for compiling with ][$2])dnl
AC_ARG_VAR([$1][_LIBS],   [LIBS to add for linking against ][$2])dnl
dnl
AC_MSG_CHECKING([for ][$2][ to use])
have_[$1]=no
if test "x${[$1][_LIBS]}" = "x" && test "x${[$1][_CFLAGS]}" = "x"; then
	m4_if([$8], [default-off],
		[m4_pushdef([gp_lib_arg],[--without-][$2])dnl
			try_[$1]=no
		],
		[m4_pushdef([gp_lib_arg],[--with-][$2])dnl
			try_[$1]=auto
		])dnl
	AC_ARG_WITH([$2],[AS_HELP_STRING([gp_lib_arg][=PREFIX],[where to find ][$2][, "no" or "auto"])],[try_][$1][="$withval"])
	if test "x${[try_][$1]}" = "xauto"; then [try_][$1]=autodetect; fi
	AC_MSG_RESULT([${try_][$1][}])
	m4_popdef([gp_lib_arg])dnl
	if test "x${[try_][$1]}" = "xautodetect"; then
		m4_ifval([$3],
			[PKG_CHECK_MODULES([$1],[$2][ $3],[have_][$1][=yes])],
			[PKG_CHECK_MODULES([$1],[$2],     [have_][$1][=yes])]
		)dnl
		if test "x${[have_][$1]}" = "xno"; then
			ifs="$IFS"
			IFS=":" # FIXME: for W32 and OS/2 we need ";" here
			for _libdir_ in \
				${LD_LIBRARY_PATH} \
				"${libdir}" \
				"${prefix}/lib64" "${prefix}/lib" \
				/usr/lib64 /usr/lib \
				/usr/local/lib64 /usr/local/lib \
				/opt/lib64 /opt/lib
			do
				IFS="$ifs"
				for _soext_ in .la ${soext} .a; do
					if test -f "${_libdir_}/[$2]${_soext_}"
					then
						if test "x${_soext_}" = "x.la" ||
						   test "x${_soext_}" = "x.a"; then
							[$1]_LIBS="${_libdir_}/[$2]${_soext_}"
						else
							[$1]_LIBS="-L${_libdir_} -l$(echo "$2" | sed 's/^lib//')"
						fi
						break
					fi
				done
				if test "x${[$1][_LIBS]}" != "x"; then
					break
				fi
			done
			IFS="$ifs"
			if test "x${[$1][_LIBS]}" != "x"; then
				have_[$1]=yes
			fi
		fi
	elif test "x${[try_][$1]}" = "xno"; then
		:
	else
		[$1][_LIBS]="-L${[try_][$1]}/lib -l$(echo "$2" | sed 's/^lib//')"
		[$1][_CFLAGS]="-I${[try_][$1]}/include"
	fi
elif test "x${[$1][_LIBS]}" != "x" && test "x${[$1][_CFLAGS]}" != "x"; then
	AC_MSG_RESULT([user-defined])
	have_[$1]=yes
else
	AC_MSG_ERROR([
* Fatal:
* When calling configure for ${PACKAGE_TARNAME}
*     ${PACKAGE_NAME}
* either set both [$1][_LIBS] *and* [$1][_CFLAGS]
* or neither.
])
fi
dnl
dnl ACTION-IF-FOUND
dnl
m4_ifval([$6],[dnl
if test "x${[have_][$1]}" = "xyes"; then
# ACTION-IF-FOUND
$6
fi
])dnl
dnl
dnl ACTION-IF-NOT-FOUND
dnl
m4_ifval([$7],[dnl
if test "x${[have_][$1]}" = "xno"; then
# ACTION-IF-NOT-FOUND
$7
fi
])dnl
dnl
dnl Run our own test compilation
dnl
m4_ifval([$4],[dnl
if test "x${[have_][$1]}" = "xyes"; then
dnl AC_MSG_CHECKING([whether ][$2][ test compile succeeds])
dnl AC_MSG_RESULT([${[have_][$1]}])
CPPFLAGS_save="$CPPFLAGS"
CPPFLAGS="${[$1]_CFLAGS}"
AC_CHECK_HEADER([$4],[have_][$1][=yes],[have_][$1][=no])
CPPFLAGS="$CPPFLAGS_save"
fi
])dnl
dnl
dnl Run our own test link
dnl    Does not work for *.la libs, so we deactivated it.
dnl
dnl m4_ifval([$5],[dnl
dnl if test "x${[have_][$1]}" = "xyes"; then
dnl AC_MSG_CHECKING([whether ][$2][ test link succeeds])
dnl LDFLAGS_save="$LDFLAGS"
dnl LDFLAGS="${[$1]_LIBS}"
dnl AC_TRY_LINK_FUNC([$5],[],[have_][$1][=no])
dnl LDFLAGS="$LDFLAGS_save"
dnl AC_MSG_RESULT([${[have_][$1]}])
dnl fi
dnl ])dnl
dnl
dnl Abort configure script if mandatory, but not found
dnl
m4_if([$8],[mandatory],[
if test "x${[have_][$1]}" = "xno"; then
	AC_MSG_ERROR([
PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
[$1][_LIBS]=${[$1][_LIBS]}
[$1][_CFLAGS]=${[$1][_CFLAGS]}

* Fatal: ${PACKAGE_NAME} requires $2 to build.
* 
* Possible solutions:
*   - set PKG_CONFIG_PATH to adequate value
*   - call configure with [$1][_LIBS]=.. and [$1][_CFLAGS]=..
*   - call configure with one of the --with-$2 parameters
]m4_ifval([$9],[dnl
*   - get $2 and install it
],[dnl
*   - get $2 and install it:
      $9]))
fi
])dnl
AM_CONDITIONAL([HAVE_][$1], [test "x$have_[$1]" = "xyes"])
if test "x$have_[$1]" = "xyes"; then
	AC_DEFINE([HAVE_][$1], 1, [whether we compile with ][$2][ support])
	GP_CONFIG_MSG([$2],[yes])dnl
	AC_MSG_CHECKING([$2][ library flags])
	AC_MSG_RESULT([${[$1][_LIBS]}])
	AC_MSG_CHECKING([$2][ cpp flags])
	AC_MSG_RESULT([${[$1][_CFLAGS]}])
else
	GP_CONFIG_MSG([$2],[no])dnl
fi
dnl AC_SUBST is done implicitly by AC_ARG_VAR above.
dnl AC_SUBST([$1][_LIBS])
dnl AC_SUBST([$1][_CFLAGS])
])dnl
dnl
dnl ####################################################################
dnl
AC_DEFUN([_GP_CHECK_LIBRARY_SYNTAX_ERROR],[dnl
m4_errprint(__file__:__line__:[ Error:
*** Calling $0 macro with old syntax
*** Aborting.
])dnl
m4_exit(1)dnl
])dnl
dnl
dnl ####################################################################
dnl
AC_DEFUN([GP_CHECK_LIBRARY],[dnl
m4_if([$4], [mandatory],        [_GP_CHECK_LIBRARY_SYNTAX_ERROR($0)],
      [$4], [default-enabled],  [_GP_CHECK_LIBRARY_SYNTAX_ERROR($0)],
      [$4], [default-disabled], [_GP_CHECK_LIBRARY_SYNTAX_ERROR($0)])dnl
m4_if([$8], [], [dnl
      _GP_CHECK_LIBRARY([$1],[$2],[$3],[$4],[$5],[$6],[$7],[mandatory],[$9])],
      [$8], [default-on], [dnl
      _GP_CHECK_LIBRARY([$1],[$2],[$3],[$4],[$5],[$6],[$7],[$8],[$9])],
      [$8], [default-off], [dnl
      _GP_CHECK_LIBRARY([$1],[$2],[$3],[$4],[$5],[$6],[$7],[$8],[$9])],
      [$8], [mandatory], [dnl
      _GP_CHECK_LIBRARY([$1],[$2],[$3],[$4],[$5],[$6],[$7],[$8],[$9])],
      [m4_errprint(__file__:__line__:[ Error:
Illegal argument 6 to $0: `$6'
It must be one of "default-on", "default-off", "mandatory".
])m4_exit(1)])dnl
])dnl
dnl
m4_pattern_disallow([GP_CHECK_LIBRARY])
m4_pattern_disallow([_GP_CHECK_LIBRARY])
m4_pattern_disallow([_GP_CHECK_LIBRARY_SYNTAX_ERROR])
m4_pattern_disallow([_GP_CHECK_LIBRARY_SOEXT])
dnl
dnl ####################################################################
dnl
dnl Please do not remove this:
dnl filetype: 6e60b4f0-acb2-4cd5-8258-42014f92bd2c
dnl I use this to find all the different instances of this file which 
dnl are supposed to be synchronized.
dnl
dnl Local Variables:
dnl mode: autoconf
dnl End: