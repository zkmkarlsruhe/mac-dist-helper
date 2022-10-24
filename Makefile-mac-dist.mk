# Makefile-mac-dist.mk
# assemble distribution zip or notarized dmg
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

# references:
# * https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
# * https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/
# * https://www.gnu.org/software/make/manual/html_node/Text-Functions.html

# makefile version
makefile.mac.dist.version = 0.2.0

XCRUN ?= /usr/bin/xcrun
XCBUILD ?= /usr/bin/xcodebuild
RSYNC ?= /usr/bin/rsync
CODESIGN ?= /usr/bin/codesign
HDIUTIL ?= /usr/bin/hdiutil
XATTR ?= /usr/bin/xattr

# use "ditto -c -k --keepParent" instead of zip -r" which invalidates sigs
DITTO ?= /usr/bin/ditto

##### shared variables to override

# temp root build dir
mac.builddir ?= dist

################################################################################
# dist
######

##### required variables

# base dist name, required
# try using mac.app.name if Makefile-mac-app.mk was included
mac.dist.name ?= $(mac.app.name)
ifeq ($(mac.dist.name),)
$(error required mac.dist.name not set...)
endif

# macOS app bundles (.app)
# try using mac.app if Makefile-mac-app.mk was included
mac.dist.apps ?= $(mac.app)

# console programs
mac.dist.progs ?=

# dynamic libraries (.dylib)
mac.dist.libs ?=

# main app or binaries to distribute (relative to main makefile dir)
mac.dist ?= $(strip $(mac.dist.apps) $(mac.dist.progs) $(mac.dist.libs))
ifeq ($(words $(mac.dist)), 0)
$(error required mac.dist empty! nothing to do...)
endif

##### variables to override

# temp dist dir
mac.dist.dir ?= $(mac.builddir)/dist

# dist version, ex. "1.2.3"
mac.dist.version ?=

# dist name with version: name-version
ifeq ($(mac.dist.version),)
mac.dist.name.version ?= $(mac.dist.name)
else
mac.dist.name.version ?= $(mac.dist.name)-$(mac.dist.version)
endif 

# include these in the release dist package (relative to main makefile dir)
mac.dist.include ?=

# remove these from the release dist package (relative to main makefile dir)
mac.dist.exclude ?=

# is distribution a single app? 1 dist, 1 app, no includes = true
mac.dist.apponly ?= true
ifneq ($(words $(mac.dist)) $(words $(mac.dist.apps)) $(words $(mac.dist.include)), 1 1 0)
mac.dist.apponly = false
endif

##### dist

# dist rsync subdir and zip/dmg srcdir
# * apponly true: .app bundle
# * apponly false: named subdir
ifeq ($(mac.dist.apponly),true)
mac.dist.subdir = $(mac.dist.dir)
mac.dist.srcdir = $(mac.dist.dir)/$(mac.dist.apps)
else
mac.dist.subdir = $(mac.dist.dir)/$(mac.dist.name.version)
mac.dist.srcdir = $(mac.dist.dir)/$(mac.dist.name.version)
endif

.PHONY: dist dist-vars dist-clean

dist: $(mac.dist.dir)

# copy files into dist dir
# FIXME: this probably can't handle paths with spaces
$(mac.dist.dir):
	@echo "===== dist"
	mkdir -p "$@"
	$(RSYNC) -a \
		--exclude ".*" --exclude=".DS_Store" $(foreach exc,$(mac.dist.exclude), --exclude="$(exc)") \
		$(mac.dist) $(mac.dist.include) $(mac.dist.subdir)

# print variables
dist-vars:
	@echo "mac.dist: $(mac.dist)"
	@echo "mac.dist.dir: $(mac.dist.dir)"
	@echo "mac.dist.name: $(mac.dist.name)"
	@echo "mac.dist.version: $(mac.dist.version)"
	@echo "mac.dist.include: $(mac.dist.include)"
	@echo "mac.dist.exclude: $(mac.dist.exclude)"
	@echo "mac.dist.apponly: $(mac.dist.apponly)"

# clean dist directory
dist-clean:
	rm -rf $(mac.dist.dir)

################################################################################
# codesign
##########

##### variables to override

# files to sign
mac.codesign ?= $(mac.dist)

# codesign identity, usually a Developer ID Application string
# default: "-" aka ad-hoc
mac.codesign.identity ?= -

# entitlements plist which allows camera access, etc
mac.codesign.entitlements ?= $(mac.dist.name)/$(mac.dist.name).entitlements

##### codesign

# don't apply entitlements if not available
ifeq ($(shell test -e "$(mac.codesign.entitlements)" && echo "true"),true)
mac.codesign.entitlements.option = --entitlements "$(mac.codesign.entitlements)"
endif

.PHONY: codesign codesign-remove codesign-verify codesign-identities codesign-vars

# codesign files
# FIXME: this probably can't handle paths with spaces
codesign:
	@echo "===== codesign"
	@if test "x$(mac.codesign.identity)" = "x-" ; then \
		echo "warning: signing using ad-hoc identity \"-\"" ; \
	fi
	$(CODESIGN) --force --sign "$(mac.codesign.identity)" $(mac.codesign.entitlements.option) $(mac.codesign)

# remove code signature(s) from files
# FIXME: this probably can't handle paths with spaces
codesign-remove:
	@echo "===== codesign remove"
	$(CODESIGN) --remove-signature $(mac.codesign)

# verify code signature(s)
codesign-verify:
	@echo "===== codesign verify"
	$(CODESIGN) --display -vv $(mac.codesign)

# list available codesign identities
codesign-identities:
	@echo "===== codesign identities"
	security find-identity -p basic -v

# print variables
codesign-vars:
	@echo "mac.codesign: $(mac.codesign)"
	@echo "mac.codesign.identity: $(mac.codesign.identity)"
	@echo "mac.codesign.entitlements: $(mac.codesign.entitlements)"

################################################################################
# zip
#####

##### variables to override

# base zip name
mac.zip.name ?= $(mac.dist.name.version)

# zip file
mac.zip ?= $(mac.zip.name).zip

# zip content src directory
mac.zip.dir ?= $(mac.dist.srcdir)

##### zip

.PHONY: zip-list zip-vars zip-clean

zip: $(mac.zip)

# create zip
$(mac.zip):
	@echo "===== zip"
	$(DITTO) -c -k --keepParent "$(mac.zip.dir)" "$(mac.zip)"
	@echo "===== zip: $(mac.zip)"

# print variables
zip-vars:
	@echo "mac.zip: $(mac.zip)"
	@echo "mac.zip.name: $(mac.zip.name)"
	@echo "mac.zip.dir: $(mac.zip.dir)"

# rm zip
zip-clobber:
	rm -f $(mac.zip)

################################################################################
# dmg
#####

##### variables to override

# base dmg name
mac.dmg.name ?= $(mac.dist.name.version)

# dmg file
mac.dmg ?= $(mac.dmg.name).dmg

# dmg content src directory
mac.dmg.dir ?= $(mac.dist.srcdir)/..

# add a convenience link to /Applications inside the dmg?
mac.dmg.applications ?= true

##### dmg

.PHONY = dmg ddmg-verify dmg-vars dmg-clean

dmg: $(mac.dmg)

# create dmg
$(mac.dmg):
	@echo "===== dmg"
	@if test "x$(mac.dmg.applications)" = "xtrue" ; then ln -s /Applications "$(mac.dmg.dir)/Applications" ; fi
	$(HDIUTIL) create -srcfolder "$(mac.dmg.dir)" -volname "$(mac.dmg.name)" -format UDZO -o "$(mac.dmg)"
	rm -f "$(mac.dmg.dir)/Applications"
	$(XATTR) -rc "$(mac.dmg)"
	@if test "x$(mac.codesign.identity)" != "x-" ; then \
		$(CODESIGN) --sign "Developer ID Application: $(mac.codesign.identity)" --timestamp -v "$(mac.dmg)" ; \
	else echo "warning: ad-hoc codesign identity \"-\", dmg will be unsigned" ; fi
	@echo "===== dmg: $(mac.dmg)"

# print vars
dmg-vars:
	@echo "mac.dmg: $(mac.dmg)"
	@echo "mac.dmg.name: $(mac.dmg.name)"
	@echo "mac.dmg.dir: $(mac.dmg.dir)"

# rm dmg
dmg-clobber:
	rm -f $(mac.dmg)

################################################################################
# notarize
##########

##### variables to override

# binaries to notarize
mac.notarize ?= $(mac.dist)

# Keychain profile name for App Store Connect app-specific password
mac.notarize.profile ?= AC_PASSWORD

# temp notarization directory
mac.notarize.dir ?= $(mac.builddir)/notarize

##### notarize for Xcode 13+ using notarytool

# current submission upload path
mac.notarize.submit = $(shell grep -m 1 "path:" "$(mac.notarize.submit.log)" | awk '{print $$2}' || "")

# xcrun output during submission and processing
mac.notarize.submit.log = $(mac.notarize.dir)/Submission.log

# current submission uuid
mac.notarize.submit.uuid = $(shell grep -m 1 "id:" $(mac.notarize.submit.log) | awk '{print $$2}' || "")

# summary log after notarization is finished, either successfully or not
# check this for details on errors
mac.notarize.log = $(mac.notarize.dir)/NotarizationSummary.json

notarize-zip: notarize-submit-zip notarize-log notarize-staple

notarize-dmg: notarize-submit-dmg notarize-log notarize-staple

notarize: notarize-dmg

.PHONY: notarize notarize-zip notarize-dmg \
        notarize-submit-zip notarize-submit-dmg \
        notarize-log notarize-staple notarize-history notarize-clean

# make notarization dir
$(mac.notarize.dir):
	mkdir -p "$@"

# upload and notarize zip
notarize-submit-zip: $(mac.notarize.dir)
	@echo "===== notarize zip"
	$(XCRUN) notarytool submit "$(mac.zip)" \
	    --keychain-profile "$(mac.notarize.profile)" \
	    --wait 2>&1 | tee "$(mac.notarize.submit.log)"

# upload and notarize dmg
notarize-submit-dmg: $(mac.notarize.dir)
	@echo "===== notarize dmg"
	$(XCRUN) notarytool submit "$(mac.dmg)" \
	    --keychain-profile "$(mac.notarize.profile)" \
	    --wait 2>&1 | tee "$(mac.notarize.submit.log)"

# staple notarized apps or binaries,
# zip files cannot be notarized but the binary contents can
# FIXME: this probably can't handle paths with spaces
notarize-staple:
	@echo "===== notarize staple"
	@for path in $(filter-out %.zip, $(mac.notarize) $(mac.notarize.submit)) ; do \
		$(XCRUN) stapler staple "$$path" ; \
	done

# download notarization summary log
notarize-log:
	@echo "===== notarize log"
	$(XCRUN) notarytool log $(mac.notarize.submit.uuid) \
	    --keychain-profile "$(mac.notarize.profile)" 2>&1 | tee "$(mac.notarize.log)"

# verify signature and acceptance by the SIP system aka Gatekeeper
notarize-verify:
	@echo "===== notarize verify"
	@for path in $(filter-out %.dmg %.zip, $(mac.notarize)) ; do \
		echo "=== verify codesign $$path" ; \
		$(CODESIGN) --display -vv "$$path" ; \
		echo "=== verify notarize $$path" ; \
		spctl --assess --type exec -v "$$path" ; \
	done
	@for path in $(filter %.dmg, $(mac.notarize.submit)) ; do \
		echo "=== verify codesign $$path" ; \
		$(CODESIGN) --display -vv "$$path" ; \
		echo "=== verify notarize $$path" ; \
		spctl --assess --type open --context context:primary-signature -v "$$path" ; \
	done

# print request history
notarize-history:
	@echo "===== notarize history"
	@$(XCRUN) notarytool history --keychain-profile "$(mac.notarize.profile)"

# print variables
notarize-vars:
	@echo "mac.notarize: $(mac.notarize)"
	@echo "mac.notarize.dir: $(mac.notarize.dir)"
	@echo "mac.notarize.profile: $(mac.notarize.profile)"
	@echo "mac.notarize.log: $(mac.notarize.log)"
	@echo "mac.notarize.submit.log: $(mac.notarize.submit.log)"

# clean notarization directory
notarize-clean:
	rm -rf $(mac.notarize.dir)

################################################################################
# combined targets
##################

# extra targets when Makefile-mac-app.mk is included
.PHONY: app-var app-clean app-clobber

.PHONY: distzip distdmg distvars distclean distclobber

# create a zip for distribution with notarized contents
distzip: dist zip notarize-zip zip-clean zip notarize-verify

# create and notarize dmg for distribution
distdmg: dist dmg notarize-dmg notarize-verify

# print all variables
distvars: app-vars dist-vars codesign-vars zip-vars dmg-vars notarize-vars
	@echo "Makefile-mac-dist.mk version $(makefile.mac.dist.version)"

# clean entire dist build directory
distclean: app-clean
	rm -rf $(mac.builddir)

# clean dist zip and dmg files
distclobber: app-clobber zip-clobber dmg-clobber
