# Makefile-mac-app.mk
# export a signed single macOS .app from an Xcode project as an archive build
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
#
# See https://github.com/zkmkarlsruhe/mac-dist-makefiles

# makefile version
makefile.mac.app.version = 0.2.0

XCBUILD ?= /usr/bin/xcodebuild

##### required variables, set this in the main Makefile before including

# base app name
mac.app.name ?=

ifeq ($(mac.app.name),)
$(error required mac.app.name not set...)
endif

##### variables to override, if needed

# temp export dir
mac.app.dir ?= export

# output app
mac.app ?= $(mac.app.name).app

# xcode project
mac.app.project ?= $(mac.app.name).xcodeproj

# xcode build config: Debug or Release
mac.app.project.config ?= Release

# xcode build scheme
mac.app.project.scheme ?= $(mac.app.name)

################################################################################
# app
#####

# build archive
mac.app.archive = $(mac.app.dir)/$(mac.app.name).xcarchive

# export options plist required for archiving
# note: overwritten during export, so use | order-only prereqs to avoid
#       circular dependencies
mac.app.export.opts = $(mac.app.dir)/ExportOptions.plist

# export log files
mac.app.export.files = DistributionSummary.plist ExportOptions.plist Packaging.log

.PHONY: app app-archive app-verify app-version app-vars app-clean app-clobber

app: $(mac.app)

# make build dir
$(mac.app.dir):
	mkdir -p "$@"

# generate plist required for xcodebuild
$(mac.app.export.opts): | $(mac.app.dir)
	echo '<?xml version="1.0" encoding="UTF-8"?>\n\
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
	<plist version="1.0">\n\
	<dict>\n\
	    <key>method</key>\n\
	    <string>developer-id</string>\n\
	</dict>\n\
	</plist>' > $(mac.app.export.opts)

# archive app
$(mac.app.archive): | $(mac.app.dir)
	@echo "===== app archive"
	$(XCBUILD) -project "$(mac.app.project)" \
	           -config "$(mac.app.project.config)" \
	           -scheme "$(mac.app.project.scheme)" \
	           -archivePath "$(mac.app.archive)" archive

# export a signed app
$(mac.app): | $(mac.app.export.opts) $(mac.app.archive)
	@echo "===== app"
	$(XCBUILD) -exportArchive -archivePath "$(mac.app.archive)" \
	           -exportOptionsPlist $(mac.app.export.opts) -exportPath .
	@for path in $(mac.app.export.files) ; do \
	    mv "$$path" "$(mac.app.dir)" ; \
	done

# verify the app is both signed and accepted by the SIP system aka Gatekeeper
app-verify:
	@echo "===== app verify"
	@echo "=== verify codesign $(mac.app)"
	codesign --verify --display -vv "$(mac.app)"
	@echo "=== verify notarize $(mac.app)"
	spctl --assess --type exec -v "$(mac.app)"

# print variables
app-vars:
	@echo "mac.app: $(mac.app)"
	@echo "mac.app.dir: $(mac.app.dir)"
	@echo "mac.app.name: $(mac.app.name)"
	@echo "mac.app.project: $(mac.app.project)"
	@echo "mac.app.project.config: $(mac.app.project.config)"
	@echo "mac.app.project.scheme: $(mac.app.project.scheme)"
	@echo "mac.app.export.opts: $(mac.app.export.opts)"
	@echo "mac.app.archive: $(mac.app.archive)"
	@echo "Makefile-mac-dist.mk version $(makefile.mac.app.version)"

# clean export directory
app-clean:
	rm -rf $(mac.app.dir)

# remove app export
app-clobber: app-clean
	rm -rf "$(mac.app)"

# for syntax highlighting in vim and github
# vim: set filetype=make:
# vim: set tabstop=4
