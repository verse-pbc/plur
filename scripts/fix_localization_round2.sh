#!/bin/bash

# Second round of localization fixes focusing on remaining keys

# Directory containing the code
PROJECT_DIR="/Users/rabble/code/verse/plur"
cd "$PROJECT_DIR" || exit 1

echo "Starting second round of localization fixes..."

# Find and fix common patterns all at once using a big sed command file
cat > /tmp/sed_commands_round2.txt << 'EOL'
s/S\.of(context)\.Join_Group/S.of(context).joinGroup/g
s/S\.of(context)\.key_has_been_copy/S.of(context).keyHasBeenCopy/g
s/S\.of(context)\.Sync_Upload/S.of(context).syncUpload/g
s/S\.of(context)\.Upload_num/S.of(context).uploadNum/g
s/S\.of(context)\.send_interval/S.of(context).sendInterval/g
s/S\.of(context)\.Select_relay_to_upload/S.of(context).selectRelayToUpload/g
s/S\.of(context)\.Please_select_relays/S.of(context).pleaseSelectRelays/g
s/S\.of(context)\.copy_success/S.of(context).copySuccess/g
s/S\.of(context)\.add_this_relay_to_local/S.of(context).addThisRelayToLocal/g
s/S\.of(context)\.notes_updated/S.of(context).notesUpdated/g
s/S\.of(context)\.Pleaseauthenticate_to_use_app/S.of(context).pleaseAuthenticateToUseApp/g
s/S\.of(context)\.Account_Manager/S.of(context).accountManager/g
s/S\.of(context)\.Add_Account/S.of(context).addAccount/g
s/S\.of(context)\.Read_Only/S.of(context).readOnly/g
s/S\.of(context)\.Word_can_t_be_null/S.of(context).wordCantBeNull/g
s/S\.of(context)\.Input_dirtyword/S.of(context).inputDirtyword/g
s/S\.of(context)\.Popular_Users/S.of(context).popularUsers/g
s/S\.of(context)\.Show_more_replies/S.of(context).showMoreReplies/g
s/S\.of(context)\.Web_Utils/S.of(context).webUtils/g
s/S\.of(context)\.Age_verification_message/S.of(context).ageVerificationMessage/g
s/S\.of(context)\.Age_verification_question/S.of(context).ageVerificationQuestion/g
s/S\.of(context)\.Login_With_NIP07_Extension/S.of(context).loginWithNIP07Extension/g
s/S\.of(context)\.Login_With_Android_Signer/S.of(context).loginWithAndroidSigner/g
s/S\.of(context)\.Accept_terms_of_service/S.of(context).acceptTermsOfService/g
s/S\.of(context)\.DMs/S.of(context).dms/g
s/S\.of(context)\.Your_Groups/S.of(context).yourGroups/g
s/S\.of(context)\.Wrong_Private_Key_format/S.of(context).wrongPrivateKeyFormat/g
s/S\.of(context)\.There_should_be_an_universe_here/S.of(context).thereShouldBeAnUniverseHere/g

s/localization\.Join_Group/localization.joinGroup/g
s/localization\.key_has_been_copy/localization.keyHasBeenCopy/g
s/localization\.Sync_Upload/localization.syncUpload/g
s/localization\.Upload_num/localization.uploadNum/g
s/localization\.send_interval/localization.sendInterval/g
s/localization\.Select_relay_to_upload/localization.selectRelayToUpload/g
s/localization\.Please_select_relays/localization.pleaseSelectRelays/g
s/localization\.copy_success/localization.copySuccess/g
s/localization\.add_this_relay_to_local/localization.addThisRelayToLocal/g
s/localization\.notes_updated/localization.notesUpdated/g
s/localization\.Pleaseauthenticate_to_use_app/localization.pleaseAuthenticateToUseApp/g
s/localization\.Account_Manager/localization.accountManager/g
s/localization\.Add_Account/localization.addAccount/g
s/localization\.Read_Only/localization.readOnly/g
s/localization\.Word_can_t_be_null/localization.wordCantBeNull/g
s/localization\.Input_dirtyword/localization.inputDirtyword/g
s/localization\.Popular_Users/localization.popularUsers/g
s/localization\.Show_more_replies/localization.showMoreReplies/g
s/localization\.Web_Utils/localization.webUtils/g
s/localization\.Age_verification_message/localization.ageVerificationMessage/g
s/localization\.Age_verification_question/localization.ageVerificationQuestion/g
s/localization\.Login_With_NIP07_Extension/localization.loginWithNIP07Extension/g
s/localization\.Login_With_Android_Signer/localization.loginWithAndroidSigner/g
s/localization\.Accept_terms_of_service/localization.acceptTermsOfService/g
s/localization\.DMs/localization.dms/g
s/localization\.Your_Groups/localization.yourGroups/g
s/localization\.Wrong_Private_Key_format/localization.wrongPrivateKeyFormat/g
s/localization\.There_should_be_an_universe_here/localization.thereShouldBeAnUniverseHere/g
EOL

# Apply all changes at once to all Dart files
echo "Applying all replacements at once..."
find "$PROJECT_DIR/lib" -name "*.dart" -print0 | xargs -0 sed -i '' -f /tmp/sed_commands_round2.txt

echo "Completed second round of localization fixes. Please run Flutter analyze to verify the changes."