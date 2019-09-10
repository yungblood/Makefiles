#########################################################################
# Simple makefile for packaging Roku SDK Application
#
# Makefile Usage:
# > make
# > make install
# > make build <Don't use for CBS>
# > make launch
# > make remove
##########################################################################  
APPNAME = cbs-roku
VERSION = 0.1

MAKEDIR = exclude/makefiles
include $(MAKEDIR)/roku-sdk.mk