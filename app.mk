# mac-app-builder: app
# build a single macOS .app from an Xcode project as an signed archive export
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

XCBUILD ?= /usr/bin/xcodebuild
PLIST_BUDDY ?= /usr/libexec/PlistBuddy

##### required variables, set this in the main Makefile before including

# base app name
mac.app.name ?= MyApp

##### variables to override, if needed

# root build dir
mac.builddir ?= build

# output app
mac.app ?= $(mac.builddir)/$(mac.app.name).app

# xcode project
mac.app.project ?= $(mac.app.name).xcodeproj

# xcode build config: Debug or Release
mac.app.project.config ?= Release

# xcode build scheme
mac.app.project.scheme ?= $(mac.app.name)

# # app version string, used for zip file and/or app naming
# ifndef mac.app.version
# 	# pull version string from project, this is slow...
# 	mac.app.version := $(shell ${XCBUILD} -project "${mac.app.project}" -showBuildSettings 2> /dev/null | grep MARKETING_VERSION | tr -d 'MARKETING_VERSION =')
# 	ifeq ($(mac.app.version),)
# 		mac.app.version = 0.0.0
# 	endif
# endif

##### app

# temp app dir
mac.app.dir = $(mac.builddir)/app

# export options plist required for archiving
mac.app.exportopts = $(mac.app.dir)/ExportOptions.plist

# build archive
mac.app.archive = $(mac.app.dir)/$(mac.app.name).xcarchive

.PHONY: app app-verify app-version app-var app-clean

app: $(mac.app.dir) $(mac.app)

# make build dir
$(mac.app.dir):
	mkdir -p "$@"

# generate plist required for xcodebuild
$(mac.app.exportopts): $(mac.app.dir)
	echo '<?xml version="1.0" encoding="UTF-8"?>\n\
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
	<plist version="1.0">\n\
	<dict>\n\
	    <key>method</key>\n\
	    <string>developer-id</string>\n\
	</dict>\n\
	</plist>' > $(mac.app.exportopts)

# archive and export a signed app
$(mac.app): $(mac.app.exportopts)
	@echo "===== app"
	$(XCBUILD) -project "$(mac.app.project)" -config "$(mac.app.project.config)" -scheme "$(mac.app.project.scheme)" -archivePath $(mac.app.archive) archive
	$(XCBUILD) -exportArchive -archivePath $(mac.app.archive) -exportOptionsPlist $(mac.app.exportopts) -exportPath $(mac.builddir)
	@for path in DistributionSummary.plist ExportOptions.plist Packaging.log ; do mv "$(mac.builddir)/$$path" "$(mac.app.dir)" ; done

# verify the app is both signed and accepted by the SIP system aka Gatekeeper
app-verify:
	@echo "===== app verify"
	codesign --verify --verbose=3 --display $(mac.app)
	spctl --assess --verbose $(mac.app)

# print built app version
app-version:
	@echo "===== app version"
	@$(PLIST_BUDDY) -c Print:CFBundleShortVersionString $(mac.app)/Contents/Info.plist

# print variables
app-var:
	@echo "===== app var"
	@echo "mac.app: $(mac.app)"
	@echo "mac.app.dir: $(mac.app.dir)"
	@echo "mac.app.name: $(mac.app.name)"
	@echo "mac.app.project: $(mac.app.project)"
	@echo "mac.app.project.config: $(mac.app.project.config)"
	@echo "mac.app.project.scheme: $(mac.app.project.scheme)"
	@echo "mac.app.exportopts: $(mac.app.exportopts)"
	@echo "mac.app.archive: $(mac.app.archive)"

# clean build directory
app-clean:
	rm -rf $(mac.app.dir) $(mac.app)
