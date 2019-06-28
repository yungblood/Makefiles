#########################################################################
# common include file for application Makefiles
#
# Makefile Common Usage:
# > make
# > make install
# > make remove
#
# Makefile Less Common Usage:
# > make art-opt
# > make pkg
# > make install_native
# > make remove_native
# > make tr
#
# By default, ZIP_EXCLUDE will exclude -x \*.pkg -x storeassets\* -x keys\* -x .\*
# If you define ZIP_EXCLUDE in your Makefile, it will override the default setting.
#
# To exclude different files from being added to the zipfile during packaging
# include a line like this:ZIP_EXCLUDE= -x keys\*
# that will exclude any file who's name begins with 'keys'
# to exclude using more than one pattern use additional '-x <pattern>' arguments
# ZIP_EXCLUDE= -x \*.pkg -x storeassets\*
#
# Important Notes: 
# To use the "install" and "remove" targets to install your
# application directly from the shell, you must do the following:
#
# 1) Make sure that you have the curl command line executable in your path
# 2) Set the variable ROKU_DEV in your environment to the IP 
#    address of your Roku box. (e.g. export ROKU_DEV=192.168.1.1.
#    Set in your this variable in your shell startup (e.g. .bashrc)
##########################################################################  
DISTREL = ../dist
COMMONREL = ../common
SOURCEREL = ..

ZIPREL = $(DISTREL)/apps
PKGREL = $(DISTREL)/packages
ROKU_DEV = 192.168.0.69
DEVPASSWORD = sweetpie
PKG_KEY = `grep -s Password: keys/key.txt | cut -d' ' -f2`
PKG_TIME = `date +%s`
V1 = `grep -s major_version manifest | cut -d'=' -f2`
V2 = `grep -s minor_version manifest | cut -d'=' -f2`
V3 = `grep -s build_version manifest | cut -d'=' -f2`
VERSION = "$(V1).$(V2).$(V3)"

APPSOURCEDIR = source
APPCOMPDIR = components
IMPORTFILES = $(foreach f,$(IMPORTS),$(COMMONREL)/$f.brs)
IMPORTCLEANUP = $(foreach f,$(IMPORTS),$(APPSOURCEDIR)/$f.brs)

NATIVEDEVREL  = $(DISTREL)/rootfs/Linux86_dev.OBJ/root/nvram/incoming
NATIVEDEVPKG  = $(NATIVEDEVREL)/dev.zip
NATIVETICKLER = $(DISTREL)/application/Linux86_dev.OBJ/root/bin/plethora  tickle-plugin-installer

ifdef DEVPASSWORD
    USERPASS = rokudev:$(DEVPASSWORD)
else
    USERPASS = rokudev
endif

ifndef ZIP_EXCLUDE
  ZIP_EXCLUDE= -x \*.pkg -x external\* -x keys\* -x \.* -x \*/.\* -x /.svn\* -x out\* -x docs\* -x /.git\* -x \*~ -x Makefile
endif

.PHONY: all $(APPNAME)

$(APPNAME): manifest
	@echo "  >> Incrementing Build Number..."	
	@awk -F= '{if($$1 == "build_version"){$$2=$$2+1}}1' OFS== manifest > manifest.tmp
	@mv manifest.tmp manifest

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
	fi \

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
		wget -nv --user=rokudev --password=$(DEVPASSWORD) -B http://$(ROKU_DEV)/pkgs/ -i getpkg.url -O keys/$(APPNAME).pkg; \
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

install_native: $(APPNAME)
	@echo "Installing $(APPNAME) to native."
	@mkdir -p $(NATIVEDEVREL)
	@cp $(ZIPREL)/$(APPNAME).zip  $(NATIVEDEVPKG)
	@$(NATIVETICKLER)

remove_native:
	@echo "Removing $(APPNAME) from native."
	@rm $(NATIVEDEVPKG)
	@$(NATIVETICKLER)

APPS_JPG_ART=`\find . -name "*.jpg"`

art-jpg-opt:
	p4 edit $(APPS_JPG_ART)
	for i in $(APPS_JPG_ART); \
	do \
		TMPJ=`mktemp` || return 1; \
		echo "optimizing $$i"; \
		(jpegtran -copy none -optimize -outfile $$TMPJ $$i && mv -f $$TMPJ $$i &); \
	done
	wait
	p4 revert -a $(APPS_JPG_ART)

APPS_PNG_ART=`\find . -name "*.png"`

art-png-opt:
	p4 edit $(APPS_PNG_ART)
	for i in $(APPS_PNG_ART); \
	do \
		(optipng -o7 $$i &); \
	done
	wait
	p4 revert -a $(APPS_PNG_ART)

art-opt: art-png-opt art-jpg-opt

tr:
	p4 edit locale/.../translations.xml
	../../rdk/rokudev/utilities/linux/bin/maketr
	rm locale/en_US/translations.xml
	p4 revert -a locale/.../translations.xml

genkey:
	@if [ ! -d keys ]; \
	then \
		mkdir keys; \
	fi
	@echo "*** Generate Key on host $(ROKU_DEV) ***"
	@echo "genkey" | ncat -t $(ROKU_DEV) 8080 -o keys/key.txt 2> /dev/null; echo
	@echo "*** Key stored in keys/key.txt  ***"

rekey:
	@echo "Setting Key for $(APPNAME) on host $(ROKU_DEV)"
	@curl --user $(USERPASS) --digest -s -S -F "mysubmit=Rekey" -F "archive=@keys/$(APPNAME).pkg" -F "passwd=$(PKG_KEY)" http://$(ROKU_DEV)/plugin_inspect | grep "Roku.Message" | sed "s/.*trigger('Set message content', '//" | sed "s/').trigger('Render', node);//" ;


inc-minor:
	@echo "*** Incrementing Minor Version ***"
	@awk -F= '{if($$1 == "build_version"){$$2=0} if($$1 == "minor_version"){$$2=$$2+1}}1' OFS== manifest > manifest.tmp
	@mv manifest.tmp manifest
	@echo "*** Version $(V1).$(V2).$(V3) ***"

inc-major:
	@echo "*** Incrementing Major Version ***"
	@awk -F= '{if($$1 == "build_version"){$$2=0} if($$1 == "minor_version"){$$2=0} if($$1 == "major_version"){$$2=$$2+1}}1' OFS== manifest > manifest.tmp
	@mv manifest.tmp manifest
	@echo "*** Version $(V1).$(V2).$(V3) ***"

debug:
	@echo "*** Brightscript Debug on host $(ROKU_DEV) ***"
	telnet $(ROKU_DEV) 8085
