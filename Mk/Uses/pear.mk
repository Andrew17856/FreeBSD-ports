# $FreeBSD$
#
# Use the PHP Extension and Application Repository
#
# Feature:	pear
# Usage:	USES=pear
# Valid ARGS:	none
#
# MAINTAINER=	portmgr@FreeBSD.org

.if !defined(_INCLUDE_USES_PEAR_MK)
_INCLUDE_USES_PEAR_MK=	yes
_USES_POST+=	pear

.if !empty(pear_ARGS)
IGNORE+=	USES=pear takes not arguments
.endif

MASTER_SITES?=	http://pear.php.net/get/ \
		http://us.pear.php.net/get/ \
		http://de.pear.php.net/get/

EXTRACT_SUFX?=	.tgz
DIST_SUBDIR?=	PEAR

BUILD_DEPENDS+=	pear:devel/pear
RUN_DEPENDS+=	pear:devel/pear

.if !defined(USE_PHPIZE)
NO_BUILD=	yes
.endif

.if defined(PEAR_CHANNEL) && ${PEAR_CHANNEL} != ""
PKGNAMEPREFIX?=	pear-${PEAR_CHANNEL}-
PEARPKGREF=	${PEAR_CHANNEL}/${PORTNAME}
.else
PKGNAMEPREFIX?=	pear-
PEARPKGREF=	${PORTNAME}
.endif

.if exists(${LOCALBASE}/bin/php-config)
PHP_BASE!=	${LOCALBASE}/bin/php-config --prefix
.else
PHP_BASE=	${LOCALBASE}
.endif
PEAR=		${LOCALBASE}/bin/pear
LPEARDIR=	share/pear
LPKGREGDIR=	${LPEARDIR}/packages/${PKGNAME}
LDATADIR=	${LPEARDIR}/data/${PORTNAME}
LDOCSDIR=	share/doc/pear/${PORTNAME}
LEXAMPLESDIR=	share/examples/pear/${PORTNAME}
LSQLSDIR=	${LPEARDIR}/sql/${PORTNAME}
LSCRIPTSDIR=	bin
LTESTSDIR=	${LPEARDIR}/tests/${PORTNAME}
PEARDIR=	${PHP_BASE}/${LPEARDIR}
PKGREGDIR=	${PHP_BASE}/${LPKGREGDIR}
DATADIR=	${PHP_BASE}/${LDATADIR}
DOCSDIR=	${PHP_BASE}/${LDOCSDIR}
EXAMPLESDIR=	${PHP_BASE}/${LEXAMPLESDIR}
SQLSDIR=	${PHP_BASE}/${LSQLSDIR}
SCRIPTFILESDIR=	${LOCALBASE}/bin
TESTSDIR=	${PHP_BASE}/${LTESTSDIR}
.if defined(CATEGORY) && !empty(CATEGORY)
LINSTDIR=	${LPEARDIR}/${CATEGORY}
.else
LINSTDIR=	${LPEARDIR}
.endif
INSTDIR=	${PHP_BASE}/${LINSTDIR}

SUB_LIST+=	PKG_NAME=${PEARPKGREF}

.if !defined(USE_PHPIZE) && !exists(${.CURDIR}/pkg-plist)
PLIST=		${WRKDIR}/PLIST
.endif
PLIST_SUB+=	PEARDIR=${LPEARDIR} PKGREGDIR=${LPKGREGDIR} \
		TESTSDIR=${LTESTSDIR} INSTDIR=${LINSTDIR} SQLSDIR=${LSQLSDIR} \
		SCRIPTFILESDIR=${LCRIPTSDIR}

PKGINSTALL?=	${PORTSDIR}/devel/pear/pear-install
PKGDEINSTALL?=	${WRKDIR}/pear-deinstall

.endif
.if defined(_POSTMKINCLUDED) && !defined(_INCLUDE_USES_PEAR_POST_MK)
_INCLUDE_USES_PEAR_POST_MK=	yes

pear-pre-install:
.if exists(${LOCALBASE}/lib/php.DIST_PHP)	\
	|| exists(${PHP_BASE}/lib/php.DIST_PHP)	\
	|| exists(${LOCALBASE}/.PEAR.pkg)	\
	|| exists(${PHP_BASE}/.PEAR.pkg)
	@${ECHO_MSG} ""
	@${ECHO_MSG} "	Sorry, the PEAR structure has been modified;"
	@${ECHO_MSG} "	Please deinstall your installed pear- ports."
	@${ECHO_MSG} ""
	@${FALSE}
.endif

DIRFILTER=	${SED} -En '\:^.*/[^/]*$$:s:^(.+)/[^/]*$$:\1:p' \
		    | ( while read r; do \
			C=1; \
			while [ $$C = 1 ]; do \
			    echo $$r; \
			    if echo $$r | ${GREP} '/' > /dev/null; then \
	                        r=`${DIRNAME} $$r`; \
			    else  \
	                        C=0; \
	                    fi; \
	                done; \
	            done \
	      ) | ${SORT} -ur

.if !defined(USE_PHPIZE)
do-autogenerate-plist: patch
	@${ECHO_MSG} "===>   Generating packing list with pear"
	@${LN} -sf ${WRKDIR}/package.xml ${WRKSRC}/package.xml
	@cd ${WRKSRC} && ${PEAR} install -n -f -P ${WRKDIR}/inst package.xml > /dev/null 2> /dev/null
.for R in .channels .depdb .depdblock .filemap .lock .registry
	@${RM} -rf ${WRKDIR}/inst/${PREFIX}/${LPEARDIR}/${R}
	@${RM} -rf ${WRKDIR}/inst/${R}
.endfor
	@FILES=`cd ${WRKDIR}/inst && ${FIND} . -type f | ${CUT} -c 2- | \
	${GREP} -v -E "^${PREFIX}/"` || exit 0; \
	${ECHO_CMD} $${FILES}; if ${TEST} -n "$${FILES}"; then \
	${ECHO_CMD} "Cannot generate packing list: package files outside PREFIX"; \
	exit 1; fi;
	@${ECHO_CMD} "${LPKGREGDIR}/package.xml" > ${PLIST}
# pkg_install needs to escape $ in directory name while pkg does not
	@cd ${WRKDIR}/inst/${PREFIX} && ${FIND} . -type f | ${SORT} \
	| ${CUT} -c 3- >> ${PLIST}

pre-install:	pear-pre-install do-autogenerate-plist do-generate-deinstall-script
do-install:	do-auto-install pear-post-install

do-auto-install:
	@cd ${WRKSRC} && ${PEAR} install -n -f -P ${STAGEDIR} package.xml
# Clean up orphans re-generated by pear-install
.for R in .channels .depdb .depdblock .filemap .lock .registry
	@${RM} -rf ${STAGEDIR}${PREFIX}/${LPEARDIR}/${R}
	@${RM} -rf ${STAGEDIR}/${R}
.endfor
.endif

do-generate-deinstall-script:
	@${SED} ${_SUB_LIST_TEMP} -e '/^@comment /d' ${PORTSDIR}/devel/pear/pear-deinstall.in > ${WRKDIR}/pear-deinstall

pear-post-install:
	@${MKDIR} ${STAGEDIR}${PKGREGDIR}
	@${INSTALL_DATA} ${WRKDIR}/package.xml ${STAGEDIR}${PKGREGDIR}

show-depends: patch
	@${PEAR} package-dependencies ${WRKDIR}/package.xml

.endif
