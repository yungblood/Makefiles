#########################################################################
# include file for SDK applications
#
# Makefile Common Usage:
# > make
# > make install
# > make remove
##########################################################################
include $(MAKEDIR)/roku-config.mk
include $(MAKEDIR)/roku-art.mk
include $(MAKEDIR)/roku-custom.mk

.PHONY: all $(APPNAME)

$(APPNAME): manifest
	@echo "  >> creating destination directory $(ZIPREL)"	
	@if [ ! -d $(ZIPREL) ]; \
	then \
		mkdir -p $(ZIPREL); \
	fi

	@echo "  >> setting directory permissions for $(ZIPREL)"
	@if [ ! -w $(ZIPREL) ]; \
	then \
		chmod 755 $(ZIPREL); \
	fi

	@echo "  >> copying imports"
	@if [ "$(IMPORTFILES)" ]; \
	then \
		mkdir $(APPSOURCEDIR)/common; \
		mkdir $(APPCOMPDIR)/common; \
		cp -rf --preserve=ownership,timestamps --no-preserve=mode -v $(COMMONREL)/* .; \
	fi 

# zip .png files without compression
	@echo "  >> creating application zip $(ZIPREL)/$(APPNAME).$(VERSION).zip"	
	@if [ -d $(SOURCEREL)/$(APPNAME) ]; \
	then \
		(zip -0 -r "$(ZIPREL)/$(APPNAME).$(VERSION).zip" . -i \*.png $(ZIP_EXCLUDE)); \
		(zip -9 -r "$(ZIPREL)/$(APPNAME).$(VERSION).zip" . -x \*.png $(ZIP_EXCLUDE)); \
	else \
		echo "Source for $(APPNAME) not found at $(SOURCEREL)/$(APPNAME)"; \
	fi

	@if [ "$(IMPORTCLEANUP)" ]; \
	then \
		echo "  >> deleting imports";\
		rm -r -f $(APPSOURCEDIR)/common; \
		rm -r -f $(APPCOMPDIR)/common; \
	fi \

	@echo "*** application $(APPNAME) Version $(VERSION) complete ***"

#if DISTDIR is not empty then copy the zip package to the DISTDIR.
	@if [ $(DISTDIR) ];\
	then \
		rm -f $(DISTDIR)/$(DISTZIP).zip; \
		mkdir -p $(DISTDIR); \
		cp -f --preserve=ownership,timestamps --no-preserve=mode $(ZIPREL)/$(APPNAME).zip $(DISTDIR)/$(DISTZIP).zip; \
	fi \

install: $(APPNAME)
	@echo "Installing $(APPNAME) Version $(VERSION) to host $(ROKU_DEV)"
	@echo "Pressing Home on $(ROKU_DEV)"
	@curl -d '' http://$(ROKU_DEV):8060/keypress/home
	@curl -d '' http://$(ROKU_DEV):8060/keypress/home
	@curl --user $(USERPASS) --digest -s -S -F "mysubmit=Install" -F "archive=@$(ZIPREL)/$(APPNAME).$(VERSION).zip" -F "passwd=" http://$(ROKU_DEV)/plugin_install | grep "Roku.Message" | sed "s/.*trigger('Set message content', '//" | sed "s/').trigger('Render', node);//" ;

pkg: install
	@echo "  >> creating destination directory $(PKGREL)"	
	@if [ ! -d $(PKGREL) ]; \
	then \
		mkdir -p $(PKGREL); \
	fi

	@echo "  >> setting directory permissions for $(PKGREL)"
	@if [ ! -w $(PKGREL) ]; \
	then \
		chmod 755 $(PKGREL); \
	fi

	@echo "Packaging  $(APPSRC)/$(APPNAME) on host $(ROKU_DEV)"
	curl -v -S --user $(USERPASS) --digest -Fmysubmit=Package -Fapp_name=$(APPNAME)/$(VERSION) -Fpasswd=$(PKG_KEY) -Fpkg_time=$(PKG_TIME) "http://$(ROKU_DEV)/plugin_package" | grep "Roku.Message" | sed "s/.*trigger('Set message content', '//" | sed "s/').trigger('Render', node);//"
	@curl -s -S --user $(USERPASS) --digest -Fmysubmit=Package -Fapp_name=$(APPNAME)/$(VERSION) -Fpasswd=$(PKG_KEY) -Fpkg_time=$(PKG_TIME) "http://$(ROKU_DEV)/plugin_package" | grep "Roku.Message" | sed "s/.*trigger('Set message content', '//" | sed "s/').trigger('Render', node);//"
	@echo "Downloading Package..."
	@curl -s -S --user $(USERPASS) --digest "http://$(ROKU_DEV)/plugin_package" | grep "a href" | sed 's/.*href=\"\([^\"]*\)\".*/\1/' | sed 's#pkgs//##' > getpkg.url
	@if [ -s getpkg.url ];\
	then \
		wget -nv --user=rokudev --password=$(ROKU_PASS) -B http://$(ROKU_DEV)/pkgs/ -i getpkg.url -O keys/$(APPNAME).pkg; \
		cp keys/$(APPNAME).pkg $(PKGREL)/$(APPNAME).$(VERSION).pkg; \
		rm getpkg.url; \
		echo "*** Package $(APPNAME) Version $(VERSION) complete ***"; \
	else \
		rm getpkg.url; \
		echo "*** Package $(APPNAME) Version $(VERSION) failed ***"; \
	fi

remove:
	@echo "Removing $(APPNAME) from host $(ROKU_DEV)"
	@if [ "$(HTTPSTATUS)" == " 401" ]; \
	then \
		curl --user $(USERPASS) --digest -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \
	else \
		curl -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \
	fi
