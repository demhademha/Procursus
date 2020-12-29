ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


SUBPROJECTS       += tcl
TCL_VERSION  := 8.6.10
DEB_TCL_V    ?= $(TCL_VERSION)
tcl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://prdownloads.sourceforge.net/tcl/tcl$(TCL_VERSION)-src.tar.gz

	$(call EXTRACT_TAR,tcl$(TCL_VERSION)-src.tar.gz,tcl$(TCL_VERSION)-src,tcl$(TCL_VERSION))

ifneq ($(wildcard $(BUILD_WORK)/tcl/.build_complete),)
tcl:
	@echo "Using previously built tcl."
else
tcl: tcl-setup
	cd $(BUILD_WORK)/tcl$(TCL_VERSION)/unix && ./configure \
	--host=aarch64-apple-darwin \
	--build=aarch64-apple-darwin \
	CFLAGS="$(CFLAGS) -w" \
	--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/tcl$(TCL_VERSION)/macosx
	+$(MAKE) -C $(BUILD_WORK)/tcl$(TCL_VERSION)/macosx install \
		DESTDIR=$(BUILD_STAGE)/tcl
		touch $(BUILD_WORK)/tcl$(TCL_VERSION)/.build_complete
endif
tcl-package: tcl-stage
	# tclsh.mk Package Structure
	rm -rf $(BUILD_DIST)/tcl
	mkdir -p $(BUILD_DIST)/tcl
	
	# tcl.mk Prep tcl
	cp -a $(BUILD_STAGE)/tcl/usr $(BUILD_DIST)/tcl
	
	# tcl.mk Sign
	$(call SIGN,tcl,general.xml)
	
	# tclsh.mk Make .debs
	$(call PACK,tcl,DEB_TCL_V)
	
	# tcl.mk Build cleanup
	rm -rf $(BUILD_DIST)/tcl

	.PHONY: tcl tcl-package
