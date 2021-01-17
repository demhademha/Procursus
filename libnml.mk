ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libnml
LIBNML_VERSION  := 1..04
DEB_LIBNML_V    ?= $(LIBNML_VERSION)

libnml-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.netfilter.org/pub/libnml/libnml-$(LIBNML_VERSION).tar.bz2
	$(call EXTRACT_TAR,libnml-$(LIBNML_VERSION).tar.bz2,libnml-$(LIBNML_VERSION),libnml)
	
ifneq ($(wildcard $(BUILD_WORK)/libnml/.build_complete),)
libnml:
	@echo "Using previously built libnml."
else
libnml: libnml-setup libmnl
	cd $(BUILD_WORK)/libnml && ././configure \
	--host=$(GNU_HOST_TRIPLE) \
	--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libnml
	+$(MAKE) -C $(BUILD_WORK)/libnml install \
		DESTDIR=$(BUILD_STAGE)/libnml
	+$(MAKE) -C $(BUILD_WORK)/libnml install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libnml/.build_complete
endif
libnml-package: libnml-stage
	# libnml.mk Package Structure
	rm -rf $(BUILD_DIST)/libnml
	mkdir -p $(BUILD_DIST)/libnml
	
	# libnml.mk Prep libnml
	cp -a $(BUILD_STAGE)/libnml/usr $(BUILD_DIST)/libnml
	
	# libnml.mk Sign
	$(call SIGN,libnml,general.xml)
	
	# libnml.mk Make .debs
	$(call PACK,libnml,DEB_LIBNML_V)
	
	# libnml.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnml

	.PHONY: libnml libnml-package
