#########################################################################
# Custom routines to make development easier
#
# @2019 Kevin Hoos
##########################################################################  

genkey:
	@if [ ! -d keys ]; \
	then \
		mkdir keys; \
	fi
	@echo "*** Generate Key on host $(ROKU_DEV) ***"
	@echo "genkey" | ncat -t $(ROKU_DEV) 8080 -o exclude/keys/key.txt 2> /dev/null; echo
	@echo "*** Key stored in exclude/keys/key.txt  ***"

rekey:
	@if [ "$(PREKEY)" ]; \
	then \
		echo "Copying $(PREKEY)* files to primary key files..."; \
		cp exclude/keys/$(PREKEY)key.txt exclude/keys/key.txt; \
		cp exclude/keys/$(PREKEY)$(APPNAME).pkg exclude/keys/$(APPNAME).pkg; \
		$(eval PKG_KEY := `grep -s Password: exclude/keys/key.txt | cut -d' ' -f2`) \
	fi 
	@echo "Setting Key for $(PREKEY)$(APPNAME) on host $(ROKU_DEV)"
	@curl --user $(USERPASS) --digest -s -S -F "mysubmit=Rekey" -F "archive=@exclude/keys/$(APPNAME).pkg" -F "passwd=$(PKG_KEY)" http://$(ROKU_DEV)/plugin_inspect | grep "Roku.Message" | sed "s/.*trigger('Set message content', '//" | sed "s/').trigger('Render', node);//" ;

inc-build:
	@echo "  >> Incrementing Build Number..."	
	@awk -F= '{if($$1 == "build_version"){$$2=$$2+1}}1' OFS== manifest > manifest.tmp
	@mv manifest.tmp manifest
	@echo "*** Version $(V1).$(V2).$(V3) ***"

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

launch:
	@curl -d '' http://$(ROKU_DEV):8060/launch/dev
	
home:
	@curl -d '' http://$(ROKU_DEV):8060/keypress/home
	
setconfig:
	@echo "*** Setting config options in manifest ***"
	@if [ "$(CONFIG_FILE)" ]; \
	then \
		awk -F= '{if($$1 == "config_file"){$$2="pkg:/$(CONFIG_FILE).json"}}1' OFS== manifest > manifest.tmp; \
		mv manifest.tmp manifest; \
		cat manifest | grep config_file; \
	fi 
	@if [ "$(CHANNEL_TOKEN)" ]; \
	then \
		awk -F= '{if($$1 == "channel_token"){$$2="pkg:/$(CHANNEL_TOKEN).json"}}1' OFS== manifest > manifest.tmp; \
		mv manifest.tmp manifest; \
		cat manifest | grep channel_token; \
	fi 

build: inc-build install
