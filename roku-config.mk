#########################################################################
# config include file for ALL applications
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
ifndef ROKU_DEV
	ROKU_DEV = 192.168.0.69
endif

PKG_KEY = `grep -s Password: exclude/keys/key.txt | cut -d' ' -f2`
PKG_TIME = `date +%s`
V1 = `grep -s major_version manifest | cut -d'=' -f2`
V2 = `grep -s minor_version manifest | cut -d'=' -f2`
V3 = `grep -s build_version manifest | cut -d'=' -f2`
VERSION = "$(V1).$(V2).$(V3)"

APPSOURCEDIR = source
APPCOMPDIR = components
IMPORTFILES = $(foreach f,$(IMPORTS),$(COMMONREL)/$f.brs)
IMPORTCLEANUP = $(foreach f,$(IMPORTS),$(APPSOURCEDIR)/$f.brs)

ifdef ROKU_PASS
    USERPASS = rokudev:$(ROKU_PASS)
else
    USERPASS = rokudev
endif

ifndef ZIP_EXCLUDE
  ZIP_EXCLUDE= -x \*.pkg -x exclude\* -x \.* -x \*/.\* -x /.git\* -x \*~ -x Makefile
endif
