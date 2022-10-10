# mac-app-builder: dmg
# package distribtion as a (signed) macOS disk image
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

HDIUTIL ?= /usr/bin/hdiutil
XATTR ?= /usr/bin/xattr
CODESIGN ?= /usr/bin/codesign

##### required variables

# base dmg name
mac.dmg.name ?= MyApp

##### variables to override

# root build dir
mac.builddir ?= build

# dmg file
mac.dmg ?= $(mac.builddir)/$(mac.dmg.name).dmg

# dmg content src directory
mac.dmg.dir ?= $(mac.builddir)/dist

# codesign identity, usually a Developer ID Application string
# default: "-" aka ad-hoc -> replace this with your id for a signed dmg
mac.codesign.identity ?= -

##### dmg

.PHONY = dmg dmg-var dmg-clean

dmg: $(mac.dmg)

# create dmg
$(mac.dmg):
	@echo "===== dmg"
	$(HDIUTIL) create -srcfolder $(mac.dmg.dir) -volname $(mac.dmg.name) -format UDZO -o $(mac.dmg)
	$(XATTR) -rc "$(mac.dmg)"
	@if test "x$(mac.codesign.identity)" != "x-" ; then \
		$(CODESIGN) -s "Developer ID Application: $(mac.codesign.identity)" -v $(mac.dmg) ; \
	else echo "warning: codesign identity \"-\", dmg will be unsigned" ; fi
	@echo "===== dmg: $(mac.dmg)"

# print vars
dmg-var:
	@echo "===== dmg var"
	@echo "mac.dmg: $(mac.dmg)"
	@echo "mac.dmg.name: $(mac.dmg.name)"
	@echo "mac.dmg.dir: $(mac.dmg.dir)"
	@echo "mac.codesign.identity: $(mac.codesign.identity)"

# clean dmg directory
dmg-clean:
	@echo "===== dmg clean"
	rm -f $(dir $(mac.dmg))*.dmg
