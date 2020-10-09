ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq ($(SSH_STRAP),1)
STRAPPROJECTS   += openssl
else
SUBPROJECTS     += openssl
endif
OPENSSL_VERSION := 1.1.1h
DEB_OPENSSL_V   ?= $(OPENSSL_VERSION)

ifneq (,$(findstring aarch64,$(GNU_HOST_TRIPLE)))
	SSL_SCHEME := aarch64-apple-darwin
else ifneq (,$(findstring arm,$(GNU_HOST_TRIPLE)))
	SSL_SCHEME := arm-apple-darwin
else
	$(error Host triple $(GNU_HOST_TRIPLE) isn't supported)
endif

openssl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,openssl-$(OPENSSL_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssl-$(OPENSSL_VERSION).tar.gz,openssl-$(OPENSSL_VERSION),openssl)
	touch $(BUILD_WORK)/openssl/Configurations/15-diatrus.conf
	@echo -e "my %targets = (\n\
		\"aarch64-apple-darwin\" => {\n\
			inherit_from     => [ \"darwin-common\", asm(\"aarch64_asm\") ],\n\
			CC               => \"$(CC)\",\n\
			cflags           => add(\"-O2 -fomit-frame-pointer -fno-common\"),\n\
			bn_ops           => \"SIXTY_FOUR_BIT_LONG RC4_CHAR\",\n\
			perlasm_scheme   => \"ios64\",\n\
			sys_id           => \"$(PLATFORM)\",\n\
		},\n\
		\"arm-apple-darwin\" => {\n\
			inherit_from     => [ \"darwin-common\", asm(\"armv4_asm\") ],\n\
			CC               => \"$(CC)\",\n\
			cflags           => add(\"-O2 -fomit-frame-pointer -fno-common\"),\n\
			perlasm_scheme   => \"ios32\",\n\
			sys_id           => \"$(PLATFORM)\",\n\
		},\n\
	);" > $(BUILD_WORK)/openssl/Configurations/15-diatrus.conf

ifneq ($(wildcard $(BUILD_WORK)/openssl/.build_complete),)
openssl:
	@echo "Using previously built openssl."
else
openssl: openssl-setup
	cd $(BUILD_WORK)/openssl && ./Configure \
		--prefix=/usr \
		--openssldir=/etc/ssl \
		shared \
		$(SSL_SCHEME)
	+$(MAKE) -C $(BUILD_WORK)/openssl
	+$(MAKE) -C $(BUILD_WORK)/openssl install_sw install_ssldirs \
		DESTDIR=$(BUILD_STAGE)/openssl
	+$(MAKE) -C $(BUILD_WORK)/openssl install_sw \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/openssl/.build_complete
endif

openssl-package: openssl-stage
	# openssl.mk Package Structure
	rm -rf $(BUILD_DIST)/{openssl,libssl{1.1,-dev}}
	mkdir -p $(BUILD_DIST)/{openssl/usr/bin,libssl{1.1,-dev}/usr/lib}

	# openssl.mk Prep libssl1.1
	cp -a $(BUILD_STAGE)/openssl/usr/lib $(BUILD_DIST)/libssl1.1/usr
	rm -rf $(BUILD_DIST)/libssl1.1/usr/lib/{lib{ssl,crypto}.{a,dylib},pkgconfig}

	# openssl.mk Prep libssl-dev
	cp -a $(BUILD_STAGE)/openssl/usr/lib/{lib{ssl,crypto}.{a,dylib},pkgconfig} $(BUILD_DIST)/libssl-dev/usr/lib
	cp -a -R $(BUILD_STAGE)/openssl/usr/include/openssl $(BUILD_DIST)/libssl-dev/usr/include
	
	# openssl.mk Prep openssl
	cp -a $(BUILD_STAGE)/openssl/etc $(BUILD_DIST)/openssl
	cp -a $(BUILD_STAGE)/openssl/usr/bin/* $(BUILD_DIST)/openssl/usr/bin
	
	# openssl.mk Sign
	$(call SIGN,libssl1.1,general.xml)
	$(call SIGN,openssl,general.xml)
	
	# openssl.mk Make .debs
	$(call PACK,libssl1.1,DEB_OPENSSL_V)
	$(call PACK,libssl-dev,DEB_OPENSSL_V)
	$(call PACK,openssl,DEB_OPENSSL_V)
	
	# openssl.mk Build cleanup
	rm -rf $(BUILD_DIST)/{openssl,libssl{1.1,-dev}}

.PHONY: openssl openssl-package
