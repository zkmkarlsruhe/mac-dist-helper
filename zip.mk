# mac-app-builder: zip
# package distribution as a zip file 
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


# use "ditto -c -k --keepParent" instead of "zip -r" which invalidates sigs
DITTO ?= /usr/bin/ditto

##### required variables

# base zip name
mac.zip.name ?= MyApp

##### variables to override

# root build dir
mac.builddir ?= build

# zip file
mac.zip ?= $(mac.builddir)/$(mac.zip.name).zip

# zip content src directory
mac.zip.dir ?= $(mac.builddir)/dist

##### zip

.PHONY: zip-list zip-var zip-clean

zip: $(mac.zip)

# create zip
$(mac.zip):
	@echo "===== zip"
	$(DITTO) -c -k $(mac.zip.dir) $(mac.zip)
	@echo "===== zip: $(mac.zip)"

# list zip contents
zip-list:
	@echo "===== zip list"
	zipinfo -1 $(mac.zip)

# print variables
zip-var:
	@echo "===== zip var"
	@echo "mac.zip: $(mac.zip)"
	@echo "mac.zip.name: $(mac.zip.name)"
	@echo "mac.zip.dir: $(mac.zip.dir)"

# clean zips and zip directory
zip-clean:
	@echo "===== zip clean"
	rm -f $(dir $(mac.zip))*.zip
