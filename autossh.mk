ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += autossh
AUTOSSH_VERSION  := 1.4g
DEB_AUTOSSH_V    ?= $(AUTOSSH_VERSION)

autossh-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.harding.motd.ca/autossh/autossh-$(AUTOSSH_VERSION).tgz
	$(call PGP_VERIFY,autossh-$(AUTOSSH_VERSION).tar.gz)
	$(call EXTRACT_TAR,autossh-$(AUTOSSH_VERSION).tgz,autossh-$(AUTOSSH_VERSION),autossh)

ifneq ($(wildcard $(BUILD_WORK)/autossh/.build_complete),)
autossh:
	@echo "Using previously built autossh."
else
autossh: autossh-setup
	cd $(BUILD_WORK)/autossh && ./configure \
	--host=$(GNU_HOST_TRIPLE) \
	CFLAGS="$(CFLAGS)" \
	--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/autossh
	+$(MAKE) -C $(BUILD_WORK)/autossh install \
		DESTDIR=$(BUILD_STAGE)/autossh
		touch $(BUILD_WORK)/autossh/.build_complete
endif
autossh-package: autossh-stage
	# autossh.mk Package Structure
	rm -rf $(BUILD_DIST)/autossh
	mkdir -p $(BUILD_DIST)/autossh
	
	# autossh.mk Prep autossh
	cp -a $(BUILD_STAGE)/autossh/usr $(BUILD_DIST)/autossh
	
	# autossh.mk Sign
	$(call SIGN,autossh,general.xml)
	
	# autossh.mk Make .debs
	$(call PACK,autossh,DEB_AUTOSSH_V)
	
	# autossh.mk Build cleanup
	rm -rf $(BUILD_DIST)/autossh

	.PHONY: autossh autossh-package
