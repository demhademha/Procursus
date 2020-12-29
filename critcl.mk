ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


SUBPROJECTS       += critcl
CRITCL_VERSION  := 3.1.18.1

DEB_CRITCL_V    ?= $(CRITCL_VERSION)
critcl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/andreas-kupries/critcl/archive/$(CRITCL_VERSION).tar.gz
	$(call EXTRACT_TAR,$(CRITCL_VERSION).tar.gz,$(CRITCL_VERSION),critctl)

ifneq ($(wildcard $(BUILD_WORK)/critctl/.build_complete),)
critcl:
	@echo "Using previously built critcl."
else
critcl: critcl-setup
	cd $(BUILD_WORK)/critcl && ./configure \
	--host=aarch64-apple-darwin \
	--build=aarch64-apple-darwin \
	CFLAGS="$(CFLAGS) -w" \
	--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/critcl
	+$(MAKE) -C $(BUILD_WORK)/critcl install \
		DESTDIR=$(BUILD_STAGE)/critcl
		touch $(BUILD_WORK)/critcl/.build_complete
endif
critcl-package: critcl-stage
	# critcl.mk Package Structure
	rm -rf $(BUILD_DIST)/critcl
	mkdir -p $(BUILD_DIST)/critcl
	
	# critcl.mk Prep critcl
	cp -a $(BUILD_STAGE)/critcl/usr $(BUILD_DIST)/critcl
	
	# critcl.mk Sign
	$(call SIGN,critcl,general.xml)
	
	# critcl.mk Make .debs
	$(call PACK,critcl,DEB_critcl_V)
	
	# critcl.mk Build cleanup
	rm -rf $(BUILD_DIST)/critcl

	.PHONY: critcl critcl-package
