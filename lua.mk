ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += lua
LUA_VERSION := 5.4.1
DEB_LUA_V   ?= $(LUA_VERSION)

lua-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz 
	$(call EXTRACT_TAR,lua-$(LUA_VERSION).tar.gz,lua-$(LUA_VERSION),lua)

ifneq ($(wildcard $(BUILD_WORK)/lua/.build_complete),)
lua:
	@echo "Using previously built lua."
else
lua: lua-setup readline
	+$(MAKE) -C $(BUILD_WORK)/lua posix \
CC=$(CC) \
CFLAGS="$(CFLAGS)" \
LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/lua install \
INSTALL_TOP="$(BUILD_STAGE)"/lua
		touch $(BUILD_WORK)/lua/.build_complete
endif

lua-package: lua-stage
	# lua.mk Package Structure
	rm -rf $(BUILD_DIST)/lua
	mkdir -p $(BUILD_DIST)/lua/usr
	
	# lua.mk Prep lua
	cp -a $(BUILD_STAGE)/lua/usr/ $(BUILD_DIST)/lua/usr
	# lua.mk Sign
	$(call SIGN,lua,general.xml)
	# lua.mk Make .debs
	$(call PACK,lua,DEB_LUA_V)
	
	# lua.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua
	
.PHONY: lua lua-package
	
