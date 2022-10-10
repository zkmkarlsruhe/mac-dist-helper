# mac-app-builder
# helper makefilesfor building & packaging macOS binary distributions
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

##### variables to override

# set the default "all" target?
mac.target.all ?= true

# set the default "clean" target?
mac.target.clean ?= true

##### mac-app-builder

# dirname of this makefile
mac.app.builder.mk.dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# makefile version
mac.app.builder.version = 0.1.0

##### app

include $(mac.app.builder.mk.dir)/app.mk

# pull version string from project, this is slow...
ifndef mac.dist.version
	mac.dist.version := $(shell ${XCBUILD} -project "${mac.app.project}" -showBuildSettings 2> /dev/null | grep MARKETING_VERSION | tr -d 'MARKETING_VERSION =')
endif

##### codesign

mac.codesign.name ?= $(mac.app.name)
include $(mac.app.builder.mk.dir)/codesign.mk

##### notarize

mac.notarize.name ?= $(mac.app.name)
include $(mac.app.builder.mk.dir)/notarize.mk

##### dist

mac.dist.name ?= $(mac.app.name)
include $(mac.app.builder.mk.dir)/dist.mk

# pull zip and dmg naming from dist:
# build/dist/MyApp-1.0.0 -> "MyApp-1.0.0"
mac.app.builder.dist.name := $(shell basename $(mac.dist.dir))
mac.app.builder.dist.dir := $(shell dirname $(mac.dist.dir))

##### zip

mac.zip.name ?= $(mac.app.builder.dist.name)
mac.zip.dir ?= $(mac.app.builder.dist.dir)
include $(mac.app.builder.mk.dir)/zip.mk

##### dmg

mac.dmg.name ?= $(mac.app.builder.dist.name)
mac.dmg.dir ?= $(mac.app.builder.dist.dir)
include $(mac.app.builder.mk.dir)/dmg.mk

##### combined targets

.PHONY: var

# print all variables
var: app-var codesign-var notarize-var dist-var zip-var dmg-var
	@echo "mac-app-builder version $(mac.app.builder.version)"

# build app by default
ifeq ($(mac.app.target.all),true)
.PHONY: all
all: app app-verify app-version
endif

# clean everything
ifeq ($(mac.app.target.clean),true)
.PHONY: clean
clean: app-clean notarize-clean dist-clean zip-clean dmg-clean
endif
