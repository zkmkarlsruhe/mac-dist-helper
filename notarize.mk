# mac-app-builder: notarize
# zip binaries and upload to Apple servers for notarization then staple ticket
# on success
#
# Copyright (c) 2022 ZKM | Hertz-Lab
# Dan Wilcox <dan.wilcox@zkm.de>
#
# BSD Simplified License.
# For information on usage and redistribution, and for a DISCLAIMER OF ALL
# WARRANTIES, see the file, "LICENSE.txt," in this distribution.
#
# This code has been developed at ZKM | Hertz-Lab as part of "The Intelligent 
# Museum" generously funded by the German Federal Cultural Foundation.

XCRUN ?= /usr/bin/xcrun

# use "ditto -c -k --keepParent" instead of zip -r" which invalidates sigs
DITTO ?= /usr/bin/ditto

##### required variables

# base notarize name
mac.notarize.name ?= MyApp

##### variables to override

# root build dir
mac.builddir ?= build

# list of apps or binaries to notarize (relative to main makefile)
mac.notarize ?= $(mac.builddir)/$(mac.notarize.name).app

# App Store Connect app-specific password name, stored in keychain
mac.notarize.password ?= AC_PASSWORD

# temp notarization directory
mac.notarize.dir ?= $(mac.builddir)/notarize

# use the altool approach for Xcode 11-12?
mac.notarize.legacy ?= false

##### notarize

# temp zip file to upload to notarization servers
mac.notarize.zip = $(mac.notarize.name).zip

# temp zip file directory
mac.notarize.zipdir = $(mac.notarize.dir)/$(mac.notarize.name)

# xcrun output after uploading zip to Apple notarization servers
mac.notarize.uploadinfo = $(mac.notarize.dir)/UploadInfo.plist

# current request status while notarization is underway on the Apple servers
mac.notarize.requestinfo = $(mac.notarize.dir)/RequestInfo.plist

# log after notarization is finished, either successfully or not
mac.notarize.loginfo = $(mac.notarize.dir)/LogInfo.json

notarize: notarize-zip notarize-upload notarize-wait \
              notarize-log notarize-staple

.PHONY: notarize notarize-upload notarize-wait notarize-log \
        notarize-staple notarize-info notarize-history \
        notarize-uuid notarize-status notarize-clean

# make notarization dir
$(mac.notarize.dir):
	mkdir -p "$@"

notarize-zip: $(mac.notarize.dir)/$(mac.notarize.zip)

# create zip using temp dir
# FIXME: this probably can't handle paths with spaces
$(mac.notarize.dir)/$(mac.notarize.zip): $(mac.notarize.dir)
	@echo "===== notarize: zipping"
	mkdir -p "$(mac.notarize.zipdir)"
	for path in $(mac.notarize) ; do cp -R "$$path" "$(mac.notarize.zipdir)/" ; done
	$(DITTO) -c -k --keepParent $(mac.notarize.zipdir) $(mac.notarize.dir)/$(mac.notarize.zip)
	rm -rf $(mac.notarize.zipdir)

# list contents of zip file
notarize-zip-list:
	@echo "===== notarize zip list"
	zipinfo -1 $(mac.notarize.dir)/$(mac.notarize.zip)

# print variables
notarize-var:
	@echo "===== notarize var"
	@echo "mac.notarize: $(mac.notarize)"
	@echo "mac.notarize.name: $(mac.notarize.name)"
	@echo "mac.notarize.dir: $(mac.notarize.dir)"
	@echo "mac.notarize.zip: $(mac.notarize.zip)"
	@echo "mac.notarize.zipdir: $(mac.notarize.zipdir)"
	@echo "mac.notarize.legacy: $(mac.notarize.legacy)"
	@echo "mac.notarize.password: $(mac.notarize.password)"
	@echo "mac.notarize.uploadinfo: $(mac.notarize.uploadinfo)"
	@echo "mac.notarize.requestinfo: $(mac.notarize.requestinfo)"
	@echo "mac.notarize.loginfo: $(mac.notarize.loginfo)"

# clean notarization directory
notarize-clean:
	rm -rf $(mac.notarize.dir)

# dirname of this makefile
mac.notarize.mk.dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# rest of the targets are implemented for:
ifeq ($(mac.notarize.legacy),true)
	# Xcode 11-12 using altool (legacy), or
	include $(mac.notarize.mk.dir)/notarize-altool.mk
else
	# Xcode 13+ using notarytool
	include $(mac.notarize.mk.dir)/notarize-notarytool.mk
endif
