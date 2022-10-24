# mac-app-builder: notarize-notarytool
# notarization process for Xcode 13+
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
# https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow

##### Xcode 13+ notarization using notarytool

define mac.notarize.update_request
$(XCRUN) notarytool info $(call mac.notarize.get_request_uuid) \
    --keychain-profile $(mac.notarize.password) --output-format plist > $(mac.notarize.requestinfo)
endef

define mac.notarize.get_request_uuid
`$(PLIST_BUDDY) -c "Print :id" $(mac.notarize.uploadinfo)`
endef

define mac.notarize.get_request_status
`$(PLIST_BUDDY) -c "Print :status" $(mac.notarize.requestinfo)`
endef

define mac.notarize.get_request_status_msg
`$(PLIST_BUDDY) -c "Print :message" $(mac.notarize.requestinfo)`
endef

define mac.notarize.wait_for_notarization
while true; do \
	$(call mac.notarize.update_request) ;\
	if [ "$(call mac.notarize.get_request_status)" != "In Progress" ]; then \
		echo "===== notarize: waking up..." ;\
		break ;\
	fi ;\
	echo "===== notarize: zzz..." ;\
	sleep 60 ;\
done
endef

# submit to notarization service and wait until processing is finished
notarize-upload: $(mac.notarize.dir)
	@echo "===== notarize: uploading"
	$(XCRUN) notarytool submit $(mac.notarize.dir)/$(mac.notarize.zip) \
	    --keychain-profile $(mac.notarize.password) \
	    --output-format plist > $(mac.notarize.uploadinfo)

# manually download request info
notarize-info:
	@echo "===== mac notarize: update request info"
	$(call mac.notarize.update_request)

# wait in a loop checking request info until success or failure
notarize-wait:
	@echo "===== notarize: waiting"
	@$(call mac.notarize.wait_for_notarization)

# download notarization log file and exit on failure
notarize-log:
	@echo "===== notarize: downloading log file"
	$(XCRUN) notarytool log $(call mac.notarize.get_request_uuid) \
	    --keychain-profile $(mac.notarize.password) > $(mac.notarize.loginfo)
	@if [ "$(call mac.notarize.get_request_status)" != "Accepted" ]; then \
	    echo "===== notarize: request in progress or failed..." && \
	    cat $(mac.notarize.loginfo) && false; \
	fi

# print request history
notarize-history:
	@echo "===== notarize: history"
	@$(XCRUN) notarytool history --keychain-profile $(mac.notarize.password)

# print current request UUID
notarize-uuid:
	@echo "===== notarize: uuid"
	@echo "$(call mac.notarize.get_request_uuid)"

# print current request status
notarize-status:
	@echo "===== notarize: status"
	@echo "Status: $(call mac.notarize.get_request_status)"
	@echo "Status Message: $(call mac.notarize.get_request_status_msg)"
