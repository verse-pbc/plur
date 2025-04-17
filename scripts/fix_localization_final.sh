#!/bin/bash

# Final round of localization fixes focusing on remaining keys

# Directory containing the code
PROJECT_DIR="/Users/rabble/code/verse/plur"
cd "$PROJECT_DIR" || exit 1

echo "Starting final round of localization fixes..."

# Create a sed script with our replacements
cat > /tmp/final_patterns.sed << 'EOL'
s/S\.of(context)\.followSet_name_edit/S.of(context).followSetNameEdit/g
s/S\.of(context)\.Communities/S.of(context).communities/g
s/S\.of(context)\.Create_Group/S.of(context).createGroup/g
s/S\.of(context)\.Join_Group/S.of(context).joinGroup/g
s/S\.of(context)\.Find_Group/S.of(context).findGroup/g
s/S\.of(context)\.Search_for_public_groups/S.of(context).searchForPublicGroups/g
s/S\.of(context)\.Discover_Groups/S.of(context).discoverGroups/g
s/S\.of(context)\.Members/S.of(context).members/g
s/S\.of(context)\.Active/S.of(context).active/g
s/S\.of(context)\.input_can_not_be_null/S.of(context).inputCanNotBeNull/g
s/S\.of(context)\.leaveGroup_Question/S.of(context).leaveGroupQuestion/g
s/S\.of(context)\.leaveGroup_Confirmation/S.of(context).leaveGroupConfirmation/g
s/S\.of(context)\.Open_User_page/S.of(context).openUserPage/g
s/S\.of(context)\.Please_input/S.of(context).pleaseInput/g
s/S\.of(context)\.add_Account/S.of(context).addAccount/g
s/S\.of(context)\.read_Only/S.of(context).readOnly/g
s/S\.of(context)\.nostromo_developers_will_never_require_a_key_from_you/S.of(context).nostrmoDevelopersWillNeverRequireAKeyFromYou/g
s/S\.of(context)\.This_is_the_key_to_your_account/S.of(context).thisIsTheKeyToYourAccount/g
s/S\.of(context)\.I_understand_I_shouldnt_share_this_key/S.of(context).iUnderstandIShouldntShareThisKey/g
s/S\.of(context)\.theKeyIsARandomStringThatResembles_/S.of(context).theKeyIsARandomStringThatResembles/g
s/S\.of(context)\.copy_Key/S.of(context).copyKey/g
s/S\.of(context)\.copy_Hex_Key/S.of(context).copyHexKey/g
s/S\.of(context)\.copy_and_Continue/S.of(context).copyAndContinue/g
s/S\.of(context)\.Delete_Account/S.of(context).deleteAccount/g
s/S\.of(context)\.Delete_Account_Tips/S.of(context).deleteAccountTips/g

s/localization\.followSet_name_edit/localization.followSetNameEdit/g
s/localization\.Communities/localization.communities/g
s/localization\.Create_Group/localization.createGroup/g
s/localization\.Join_Group/localization.joinGroup/g
s/localization\.Find_Group/localization.findGroup/g
s/localization\.Search_for_public_groups/localization.searchForPublicGroups/g
s/localization\.Discover_Groups/localization.discoverGroups/g
s/localization\.Members/localization.members/g
s/localization\.Active/localization.active/g
s/localization\.input_can_not_be_null/localization.inputCanNotBeNull/g
s/localization\.leaveGroup_Question/localization.leaveGroupQuestion/g
s/localization\.leaveGroup_Confirmation/localization.leaveGroupConfirmation/g
s/localization\.Open_User_page/localization.openUserPage/g
s/localization\.Please_input/localization.pleaseInput/g
s/localization\.add_Account/localization.addAccount/g
s/localization\.read_Only/localization.readOnly/g
s/localization\.nostromo_developers_will_never_require_a_key_from_you/localization.nostrmoDevelopersWillNeverRequireAKeyFromYou/g
s/localization\.This_is_the_key_to_your_account/localization.thisIsTheKeyToYourAccount/g
s/localization\.I_understand_I_shouldnt_share_this_key/localization.iUnderstandIShouldntShareThisKey/g
s/localization\.theKeyIsARandomStringThatResembles_/localization.theKeyIsARandomStringThatResembles/g
s/localization\.copy_Key/localization.copyKey/g
s/localization\.copy_Hex_Key/localization.copyHexKey/g
s/localization\.copy_and_Continue/localization.copyAndContinue/g
s/localization\.Delete_Account/localization.deleteAccount/g
s/localization\.Delete_Account_Tips/localization.deleteAccountTips/g
EOL

# Apply all changes at once to all Dart files
echo "Applying all replacements at once..."
find "$PROJECT_DIR/lib" -name "*.dart" -print0 | xargs -0 sed -i '' -f /tmp/final_patterns.sed

echo "Completed final round of localization fixes. Please run Flutter analyze to verify the changes."