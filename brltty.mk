ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += brltty
BRLTTY_VERSION  := 6.1
DEB_BRLTTY_V    ?= $(BRLTTY_VERSION)

brltty-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://brltty.app/archive/brltty-$(BRLTTY_VERSION).tar.xz

	$(call EXTRACT_TAR,brltty-$(BRLTTY_VERSION).tar.xz,brltty-$(BRLTTY_VERSION),brltty)

ifneq ($(wildcard $(BUILD_WORK)/brltty/.build_complete),)
brltty:
	@echo "Using previously built brltty."
else
brltty: brltty-setup
	cd $(BUILD_WORK)/brltty && ././autogen \
	--host=aarch64-apple-darwin \
	-build=aarch64-apple-darwin \
	--disable-speech-support \
		  --without-screen-driver
	  
								
	--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/brltty
	+$(MAKE) -C $(BUILD_WORK)/brltty install \
		DESTDIR=$(BUILD_STAGE)/brltty
		touch $(BUILD_WORK)/brltty/.build_complete
endif
brltty-package: brltty-stage
	# brltty.mk Package Structure
	rm -rf $(BUILD_DIST)/brltty
	mkdir -p $(BUILD_DIST)/brltty
	
	# brltty.mk Prep brltty
	cp -a $(BUILD_STAGE)/brltty/usr $(BUILD_DIST)/brltty
	
	# brltty.mk Sign
	$(call SIGN,brltty,general.xml)
	
	# brltty.mk Make .debs
	$(call PACK,brltty,DEB_BRLTTY_V)
	
	# brltty.mk Build cleanup
	rm -rf $(BUILD_DIST)/brltty

	.PHONY: brltty brltty-package
