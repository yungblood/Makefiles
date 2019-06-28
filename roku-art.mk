#########################################################################
# Art and Translation routines
#
# Taken from app.mk @Roku.
##########################################################################  

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
