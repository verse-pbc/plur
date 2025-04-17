#!/bin/bash

# Focus on fixing the most common patterns

# Directory containing the code
PROJECT_DIR="/Users/rabble/code/verse/plur"
cd "$PROJECT_DIR" || exit 1

echo "Starting common pattern fixes..."

# Create a sed script with our replacements
cat > /tmp/common_patterns.sed << 'EOL'
s/S\.of(context)\.Active/S.of(context).active/g
s/S\.of(context)\.All_media_public/S.of(context).allMediaPublic/g
s/S\.of(context)\.Communities/S.of(context).communities/g
s/S\.of(context)\.Members/S.of(context).members/g
s/S\.of(context)\.Please_input/S.of(context).pleaseInput/g
s/S\.of(context)\.New_Post/S.of(context).newPost/g
s/S\.of(context)\.Posting_to/S.of(context).postingTo/g
s/S\.of(context)\.Please_input_user_pubkey/S.of(context).pleaseInputUserPubkey/g
s/S\.of(context)\.Network_take_effect_tip/S.of(context).networkTakeEffectTip/g
s/S\.of(context)\.Link_preview/S.of(context).linkPreview/g
s/S\.of(context)\.Video_preview_in_list/S.of(context).videoPreviewInList/g
s/S\.of(context)\.Join_Group/S.of(context).joinGroup/g
s/S\.of(context)\.Create_Group/S.of(context).createGroup/g
s/S\.of(context)\.Find_Group/S.of(context).findGroup/g
s/S\.of(context)\.Limit_Note_Height/S.of(context).limitNoteHeight/g
s/S\.of(context)\.image_Compress/S.of(context).imageCompress/g
s/S\.of(context)\.Dont_Compress/S.of(context).dontCompress/g
s/S\.of(context)\.forbidden_image/S.of(context).forbidImage/g
s/S\.of(context)\.forbidden_video/S.of(context).forbidVideo/g
s/S\.of(context)\.forbidden_profile_picture/S.of(context).forbidProfilePicture/g
s/S\.of(context)\.Event_Sign_Check/S.of(context).eventSignCheck/g
s/S\.of(context)\.Fast_Mode/S.of(context).fastMode/g
s/S\.of(context)\.Base_Mode/S.of(context).baseMode/g
s/S\.of(context)\.Privacy_Lock/S.of(context).privacyLock/g
s/S\.of(context)\.Display_Name/S.of(context).displayName/g
s/S\.of(context)\.Lightning_Address/S.of(context).lightningAddress/g
s/S\.of(context)\.input_relay_address/S.of(context).inputRelayAddress/g
s/S\.of(context)\.address_can_t_be_null/S.of(context).addressCantBeNull/g

s/localization\.Active/localization.active/g
s/localization\.All_media_public/localization.allMediaPublic/g
s/localization\.Communities/localization.communities/g
s/localization\.Members/localization.members/g
s/localization\.Please_input/localization.pleaseInput/g
s/localization\.New_Post/localization.newPost/g
s/localization\.Posting_to/localization.postingTo/g
s/localization\.Please_input_user_pubkey/localization.pleaseInputUserPubkey/g
s/localization\.Network_take_effect_tip/localization.networkTakeEffectTip/g
s/localization\.Link_preview/localization.linkPreview/g
s/localization\.Video_preview_in_list/localization.videoPreviewInList/g
s/localization\.Join_Group/localization.joinGroup/g
s/localization\.Create_Group/localization.createGroup/g
s/localization\.Find_Group/localization.findGroup/g
s/localization\.Limit_Note_Height/localization.limitNoteHeight/g
s/localization\.image_Compress/localization.imageCompress/g
s/localization\.Dont_Compress/localization.dontCompress/g
s/localization\.forbidden_image/localization.forbidImage/g
s/localization\.forbidden_video/localization.forbidVideo/g
s/localization\.forbidden_profile_picture/localization.forbidProfilePicture/g
s/localization\.Event_Sign_Check/localization.eventSignCheck/g
s/localization\.Fast_Mode/localization.fastMode/g
s/localization\.Base_Mode/localization.baseMode/g
s/localization\.Privacy_Lock/localization.privacyLock/g
s/localization\.Display_Name/localization.displayName/g
s/localization\.Lightning_Address/localization.lightningAddress/g
s/localization\.input_relay_address/localization.inputRelayAddress/g
s/localization\.address_can_t_be_null/localization.addressCantBeNull/g
EOL

# Apply patterns
echo "Applying common patterns..."
find "$PROJECT_DIR/lib" -name "*.dart" -print0 | xargs -0 sed -i '' -f /tmp/common_patterns.sed

echo "Completed common pattern fixes."