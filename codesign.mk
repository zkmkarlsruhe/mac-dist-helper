# mac-app-builder: codesign
# codesign files which are signed via Xcode, ie. non-Xcode makefile builds
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

CODESIGN ?= /usr/bin/codesign

##### required variables

# base codesign name
mac.codesign.name ?= MyApp

##### variables to override

# root build dir
mac.builddir ?= build

# files to sign
mac.codesign ?= $(mac.builddir)/$(mac.codesign.name).app

# codesign identity, usually a Developer ID Application string
# default: "-" aka ad-hoc
mac.codesign.identity ?= -

# entitlements plist which allows camera access, etc
mac.codesign.entitlements ?= $(mac.codesign.name).entitlements

##### codesign

# don't apply entitlements if not available
ifeq ($(shell test -e $(mac.codesign.entitlements) && echo "true"),true)
mac.codesign.entitlements.option = --entitlements $(mac.codesign.entitlements)
endif

.PHONY: codesign codesign-verify codesign-var

# codesign files
# FIXME: this probably can't handle paths with spaces
codesign:
	@echo "===== codesign"
	@if test "x$(mac.codesign.identity)" = "x-" ; then \
		echo "warning: signing using ad-hoc identity \"-\"" ; \
	fi
	@for path in $(mac.codesign) ; do \
		echo "$$path" ; \
		$(CODESIGN) --force \
			--sign "$(mac.codesign.identity)" \
			 $(mac.codesign.entitlements.option) \
			"$$path" ; \
	done

# remove codesign from files
# FIXME: this probably can't handle paths with spaces
codesign-remove:
	@echo "===== codesign remove"
	@for path in $(mac.codesign) ; do \
		echo "$$path" ; \
		$(CODESIGN) --remove-signature \
			"$$path" ; \
	done

# verify code signature(s)
codesign-verify:
	@echo "===== codesign verify"
	@for path in $(mac.codesign) ; do \
		$(CODESIGN) -d -v "$$path" ; \
	done

# print variables
codesign-var:
	@echo "===== codesign var"
	@echo "mac.codesign: $(mac.codesign)"
	@echo "mac.codesign.name: $(mac.codesign.name)"
	@echo "mac.codesign.entitlements: $(mac.codesign.entitlements)"
