# mac-app-builder: notarize-altool
# notarization process for Xcode 11-12
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
# references:
# https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow/notarizing_apps_when_developing_with_xcode_12_and_earlier

CURL ?= /usr/bin/curl

##### variables to override

# temp zip bundle id, convert spaces to -
mac.notarize.bundleid ?= com.unknown.$(shell echo $(mac.notarize.name) | tr ' ' '-').zip

##### legacy Xcode 11-12 notarization using altool

define mac.notarize.update_request
$(XCRUN) altool --notarization-info $(call mac.notarize.get_request_uuid) \
    --password $(mac.notarize.password) --output-format xml > $(mac.notarize.requestinfo)
endef

define mac.notarize.get_request_uuidw
`$(PLIST_BUDDY) -c "Print :notarization-upload:RequestUUID" $(mac.notarize.uploadinfo)`
endef

define mac.notarize.get_request_status
`$(PLIST_BUDDY) -c "Print :notarization-info:Status" $(mac.notarize.requestinfo)`
endef

define mac.notarize.get_request_status_msg
`$(PLIST_BUDDY) -c "Print :notarization-info:'Status Message'" $(mac.notarize.requestinfo)`
endef

define mac.notarize.get_log_url
`$(PLIST_BUDDY) -c "Print :notarization-info:LogFileURL" $(mac.notarize.requestinfo)`
endef

define mac.notarize.wait_for_notarization
while true; do \
	$(call mac.notarize.update_request) ;\
	if [ "$(call mac.notarize.get_request_status)" != "in progress" ]; then \
		echo "===== notarize: waking up..." ;\
		break ;\
	fi ;\
	echo "===== notarize: zzz..." ;\
	sleep 60 ;\
done
endef

# upload zip for notarization
notarize-upload: $(mac.notarizedir)
	@echo "===== notarize: uploading"
	$(XCRUN) altool --notarize-app --primary-bundle-id $(mac.notarize.bundleid) \
	    --password "@keychain:$(mac.notarize.password)" \
	    --file $(mac.notarizedir)/$(mac.notarize.zip) \
	    --show-progress --output-format xml > $(mac.notarize.uploadinfo)

# manually download request info
notarize-info:
	@echo "===== notarize: update request info"
	$(call mac.notarize.update_request)

# wait in a loop checking request info until success or failure
notarize-wait:
	@echo "===== notarize: waiting"
	@$(call mac.notarize.wait_for_notarization)

# download notarization log file on success 
notarize-log:
	@echo "===== notarize: downloading log file"
	@if [ "$(call mac.notarize.get_request_status)" != "success" ]; then \
	    echo "===== notarize: request in progress or failed..." && false; \
	fi
	$(CURL) -o $(mac.notarize.loginfo) $(call mac.notarize.get_log_url)

# staple notarized apps or binaries
# FIXME: this probably can't handle paths with spaces
notarize-staple:
	@echo "===== notarize: staple"
	for path in $(mac.notarize) ; do $(XCRUN) stapler staple $$path ; done

# print request history
notarize-history:
	@echo "===== notarize: history"
	$(XCRUN) altool --notarization-history 0 --password "@keychain:$(mac.notarize.password)"

# print current request UUID
notarize-uuid:
	@echo "===== notarize: uuid"
	@echo "$(call mac.notarize.get_request_uuid)"

# print current request status
notarize-status:
	@echo "===== notarize: status"
	@echo "Status: $(call mac.notarize.get_request_status)"
	@echo "Status Message: $(call mac.notarize.get_request_status_msg)"
