#########################################################################
# include file for NDK applications
#
# Makefile Common Usage:
# > make install_native
# > make remove_native
##########################################################################  
include $(MAKEDIR)/roku-config.mk
include $(MAKEDIR)/roku-art.mk
include $(MAKEDIR)/roku-custom.mk
include $(MAKEDIR)/roku-sdk.mk

NATIVEDEVREL  = $(DISTREL)/rootfs/Linux86_dev.OBJ/root/nvram/incoming
NATIVEDEVPKG  = $(NATIVEDEVREL)/dev.zip
NATIVETICKLER = $(DISTREL)/application/Linux86_dev.OBJ/root/bin/plethora  tickle-plugin-installer

install_native: $(APPNAME)
	@echo "Installing $(APPNAME) to native."
	@mkdir -p $(NATIVEDEVREL)
	@cp $(ZIPREL)/$(APPNAME).zip  $(NATIVEDEVPKG)
	@$(NATIVETICKLER)

remove_native:
	@echo "Removing $(APPNAME) from native."
	@rm $(NATIVEDEVPKG)
	@$(NATIVETICKLER)
