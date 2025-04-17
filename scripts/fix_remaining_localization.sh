#!/bin/bash

# Script to fix remaining localization issues

# Directory containing the code
PROJECT_DIR="/Users/rabble/code/verse/plur"
cd "$PROJECT_DIR" || exit 1

echo "Starting fixes for remaining localization issues..."

# Create a sed script with our replacements
cat > /tmp/remaining_patterns.sed << 'EOL'
s/S\.of(context)\.Active/S.of(context).active/g
s/S\.of(context)\.Auto_Open_Sensitive_Content/S.of(context).autoOpenSensitiveContent/g
s/S\.of(context)\.Begin_to_download_translate_model/S.of(context).beginToDownloadTranslateModel/g
s/S\.of(context)\.Begin_to_load_Contact_History/S.of(context).beginToLoadContactHistory/g
s/S\.of(context)\.Broadcast_When_Boost/S.of(context).broadcastWhenBoost/g
s/S\.of(context)\.Communities/S.of(context).communities/g
s/S\.of(context)\.Create_Group/S.of(context).createGroup/g
s/S\.of(context)\.Discover_Groups/S.of(context).discoverGroups/g
s/S\.of(context)\.Find_Group/S.of(context).findGroup/g
s/S\.of(context)\.Gen_invoice_code_error/S.of(context).genInvoiceCodeError/g
s/S\.of(context)\.Join_Group/S.of(context).joinGroup/g
s/S\.of(context)\.Members/S.of(context).members/g
s/S\.of(context)\.Metadata_can_not_be_found/S.of(context).metadataCanNotBeFound/g
s/S\.of(context)\.NWC_TIP1/S.of(context).nwcTip1/g
s/S\.of(context)\.NWC_TIP2/S.of(context).nwcTip2/g
s/S\.of(context)\.Open_Event_from_cache/S.of(context).openEventFromCache/g
s/S\.of(context)\.Open_Note_detail/S.of(context).openNoteDetail/g
s/S\.of(context)\.PLease_input_NWC_URL/S.of(context).pleaseInputNWCURL/g
s/S\.of(context)\.Please_input/S.of(context).pleaseInput/g
s/S\.of(context)\.Search_for_public_groups/S.of(context).searchForPublicGroups/g
s/S\.of(context)\.Verify_error/S.of(context).verifyError/g
s/S\.of(context)\.Verify_failure/S.of(context).verifyFailure/g
s/S\.of(context)\.cache_Relay/S.of(context).cacheRelay/g
s/S\.of(context)\.delete_Account/S.of(context).deleteAccount/g
s/S\.of(context)\.delete_Account_Tips/S.of(context).deleteAccountTips/g
s/S\.of(context)\.followed_Communities/S.of(context).followedCommunities/g
s/S\.of(context)\.followed_Tags/S.of(context).followedTags/g
s/S\.of(context)\.forbid_image/S.of(context).forbidImage/g
s/S\.of(context)\.forbid_profile_picture/S.of(context).forbidProfilePicture/g
s/S\.of(context)\.forbid_video/S.of(context).forbidVideo/g
s/S\.of(context)\.hide_Relay_Notices/S.of(context).hideRelayNotices/g
s/S\.of(context)\.image_service/S.of(context).imageService/g
s/S\.of(context)\.image_service_path/S.of(context).imageServicePath/g
s/S\.of(context)\.input_parse_error/S.of(context).inputParseError/g
s/S\.of(context)\.is_sending/S.of(context).isSending/g
s/S\.of(context)\.network_take_effect_tip/S.of(context).networkTakeEffectTip/g
s/S\.of(context)\.posts_and_replies/S.of(context).postsAndReplies/g
s/S\.of(context)\.relay_Mode/S.of(context).relayMode/g
s/S\.of(context)\.search_User_from_cache/S.of(context).searchUserFromCache/g
s/S\.of(context)\.search_note_content/S.of(context).searchNoteContent/g
s/S\.of(context)\.search_pubkey_event/S.of(context).searchPubkeyEvent/g
s/S\.of(context)\.translate_Source_Language/S.of(context).translateSourceLanguage/g
s/S\.of(context)\.translate_Target_Language/S.of(context).translateTargetLanguage/g
s/S\.of(context)\.view_key/S.of(context).viewKey/g

s/localization\.Active/localization.active/g
s/localization\.Auto_Open_Sensitive_Content/localization.autoOpenSensitiveContent/g
s/localization\.Begin_to_download_translate_model/localization.beginToDownloadTranslateModel/g
s/localization\.Begin_to_load_Contact_History/localization.beginToLoadContactHistory/g
s/localization\.Broadcast_When_Boost/localization.broadcastWhenBoost/g
s/localization\.Communities/localization.communities/g
s/localization\.Create_Group/localization.createGroup/g
s/localization\.Discover_Groups/localization.discoverGroups/g
s/localization\.Find_Group/localization.findGroup/g
s/localization\.Gen_invoice_code_error/localization.genInvoiceCodeError/g
s/localization\.Join_Group/localization.joinGroup/g
s/localization\.Members/localization.members/g
s/localization\.Metadata_can_not_be_found/localization.metadataCanNotBeFound/g
s/localization\.NWC_TIP1/localization.nwcTip1/g
s/localization\.NWC_TIP2/localization.nwcTip2/g
s/localization\.Open_Event_from_cache/localization.openEventFromCache/g
s/localization\.Open_Note_detail/localization.openNoteDetail/g
s/localization\.PLease_input_NWC_URL/localization.pleaseInputNWCURL/g
s/localization\.Please_input/localization.pleaseInput/g
s/localization\.Search_for_public_groups/localization.searchForPublicGroups/g
s/localization\.Verify_error/localization.verifyError/g
s/localization\.Verify_failure/localization.verifyFailure/g
s/localization\.cache_Relay/localization.cacheRelay/g
s/localization\.delete_Account/localization.deleteAccount/g
s/localization\.delete_Account_Tips/localization.deleteAccountTips/g
s/localization\.followed_Communities/localization.followedCommunities/g
s/localization\.followed_Tags/localization.followedTags/g
s/localization\.forbid_image/localization.forbidImage/g
s/localization\.forbid_profile_picture/localization.forbidProfilePicture/g
s/localization\.forbid_video/localization.forbidVideo/g
s/localization\.hide_Relay_Notices/localization.hideRelayNotices/g
s/localization\.image_service/localization.imageService/g
s/localization\.image_service_path/localization.imageServicePath/g
s/localization\.input_parse_error/localization.inputParseError/g
s/localization\.is_sending/localization.isSending/g
s/localization\.network_take_effect_tip/localization.networkTakeEffectTip/g
s/localization\.posts_and_replies/localization.postsAndReplies/g
s/localization\.relay_Mode/localization.relayMode/g
s/localization\.search_User_from_cache/localization.searchUserFromCache/g
s/localization\.search_note_content/localization.searchNoteContent/g
s/localization\.search_pubkey_event/localization.searchPubkeyEvent/g
s/localization\.translate_Source_Language/localization.translateSourceLanguage/g
s/localization\.translate_Target_Language/localization.translateTargetLanguage/g
s/localization\.view_key/localization.viewKey/g
EOL

# Apply all changes at once to all Dart files
echo "Applying all replacements at once..."
find "$PROJECT_DIR/lib" -name "*.dart" -print0 | xargs -0 sed -i '' -f /tmp/remaining_patterns.sed

echo "Completed fixes for remaining localization issues. Please run Flutter analyze to verify the changes."