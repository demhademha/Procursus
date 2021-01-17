ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += iptables
IPTABLES_VERSION  := 1..8.7
DEB_IPTABLES_V    ?= $(IPTABLES_VERSION)

iptables-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.netfilter.org/pub/iptables/iptables-$(IPTABLES_VERSION).tar.bz2
	$(call EXTRACT_TAR,iptables-$(IPTABLES_VERSION).tar.bz2,iptables-$(IPTABLES_VERSION),iptables)
	
ifneq ($(wildcard $(BUILD_WORK)/iptables/.build_complete),)
iptables:
	@echo "Using previously built iptables."
else
iptables: iptables-setup libmnl
	cd $(BUILD_WORK)/iptables && ././configure \
	--host=$(GNU_HOST_TRIPLE) \
	--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/iptables
	+$(MAKE) -C $(BUILD_WORK)/iptables install \
		DESTDIR=$(BUILD_STAGE)/iptables
	+$(MAKE) -C $(BUILD_WORK)/iptables install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/iptables/.build_complete
endif
iptables-package: iptables-stage
	# iptables.mk Package Structure
	rm -rf $(BUILD_DIST)/iptables
	mkdir -p $(BUILD_DIST)/iptables
	
	# iptables.mk Prep iptables
	cp -a $(BUILD_STAGE)/iptables/usr $(BUILD_DIST)/iptables
	
	# iptables.mk Sign
	$(call SIGN,iptables,general.xml)
	
	# iptables.mk Make .debs
	$(call PACK,iptables,DEB_IPTABLES_V)
	
	# iptables.mk Build cleanup
	rm -rf $(BUILD_DIST)/iptables

	.PHONY: iptables iptables-package
