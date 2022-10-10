# mac-app-builder: dist
# assemble files for distribution, can be single .app or directory with multiple
# files and subdirs
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

##### required variables

# base dist name, required
mac.dist.name ?= MyApp

##### variables to override

# root build dir
mac.builddir ?= build

# main app or binaries to distribute (relative to main makefile dir)
mac.dist ?= $(mac.builddir)/$(mac.dist.name).app

# temp dist dir
ifndef mac.dist.version
mac.dist.dir ?= $(mac.builddir)/dist/$(mac.dist.name)
else
mac.dist.dir ?= $(mac.builddir)/dist/$(mac.dist.name)-$(mac.dist.version)
endif

# include these in the release dist package (relative to main makefile dir)
mac.dist.include ?=

# remove these from the release dist package (relative to final dist dir)
# ex: "mac.dist.exclude = data/icon.icns"
#     removes icon.icns from data dir which was included by
#     "mac.dist.include = bin/data"
mac.dist.exclude ?=

##### dist

.PHONY: dist dist-list dist-var dist-clean

dist: $(mac.dist.dir)

# copy files into dist dir
# FIXME: this probably can't handle paths with spaces
$(mac.dist.dir):
	@echo "===== dist"
	mkdir -p "$@"
	for path in $(mac.dist) ; do echo "$$path" && cp -R "$$path" "$(mac.dist.dir)/" ; done
	for path in $(mac.dist.include) ; do cp -R "$$path" "$(mac.dist.dir)/" ; done
	for path in $(mac.dist.exclude) ; do rm -rf "$(mac.dist.dir)/$$path" ; done
	@find $(mac.dist.dir) -name ".DS_Store" -type f -delete
	@find $(mac.dist.dir) -name ".git*" -delete

# list contents of dist directory (one level only)
dist-list:
	@echo "===== dist list"
	@find $(mac.dist.dir) -depth 1

# print variables
dist-var:
	@echo "===== dist var"
	@echo "mac.dist: $(mac.dist)"
	@echo "mac.dist.dir: $(mac.dist.dir)"
	@echo "mac.dist.name: $(mac.dist.name)"
	@echo "mac.dist.include: $(mac.dist.include)"
	@echo "mac.dist.exclude: $(mac.dist.exclude)"

# clean dist directory
dist-clean:
	@echo "===== dist clean"
	rm -rf $(mac.dist.dir)
