#!/bin/bash

# Fifth round of localization fixes focusing on remaining keys

# Directory containing the code
PROJECT_DIR="/Users/rabble/code/verse/plur"
cd "$PROJECT_DIR" || exit 1

echo "Starting fifth round of localization fixes..."

# Create a sed script with our replacements
cat > /tmp/round5_patterns.sed << 'EOL'
s/S\.of(context)\.Join_Group/S.of(context).joinGroup/g
s/S\.of(context)\.Buy_me_a_coffee/S.of(context).buyMeACoffee/g
s/S\.of(context)\.input_dirtyword/S.of(context).inputDirtyword/g
s/S\.of(context)\.pleaseInput_user_pubkey/S.of(context).pleaseInputUserPubkey/g
s/S\.of(context)\.Follow_set/S.of(context).followSet/g
s/S\.of(context)\.input_follow_set_name/S.of(context).inputFollowSetName/g
s/S\.of(context)\.edit_name/S.of(context).editName/g
s/S\.of(context)\.Follow_set_name_edit/S.of(context).followSetNameEdit/g
s/S\.of(context)\.invite_people_to_join/S.of(context).invitePeopleToJoin/g
s/S\.of(context)\.Create_Group/S.of(context).createGroup/g
s/S\.of(context)\.Find_Group/S.of(context).findGroup/g
s/S\.of(context)\.Search_for_public_groups/S.of(context).searchForPublicGroups/g
s/S\.of(context)\.Create_your_community/S.of(context).createYourCommunity/g
s/S\.of(context)\.name_your_community/S.of(context).nameYourCommunity/g
s/S\.of(context)\.community_name/S.of(context).communityName/g
s/S\.of(context)\.Discover_Groups/S.of(context).discoverGroups/g
s/S\.of(context)\.Active/S.of(context).active/g
s/S\.of(context)\.Start_or_join_a_community/S.of(context).startOrJoinACommunity/g
s/S\.of(context)\.Connect_with_others/S.of(context).connectWithOthers/g
s/S\.of(context)\.Have_invite_link/S.of(context).haveInviteLink/g
s/S\.of(context)\.leave_Group/S.of(context).leaveGroup/g
s/S\.of(context)\.leave_Group_Question/S.of(context).leaveGroupQuestion/g
s/S\.of(context)\.leave_Group_Confirmation/S.of(context).leaveGroupConfirmation/g
s/S\.of(context)\.admin_Panel/S.of(context).adminPanel/g
s/S\.of(context)\.Open_group/S.of(context).openGroup/g
s/S\.of(context)\.Closed_group/S.of(context).closedGroup/g
s/S\.of(context)\.Thread_Mode/S.of(context).threadMode/g
s/S\.of(context)\.Posts_And_Replies/S.of(context).postsAndReplies/g
s/S\.of(context)\.Please_authenticate_to_turn_off_the_privacy_lock/S.of(context).pleaseAuthenticateToTurnOffThePrivacyLock/g
s/S\.of(context)\.Please_authenticate_to_turn_on_the_privacy_lock/S.of(context).pleaseAuthenticateToTurnOnThePrivacyLock/g
s/S\.of(context)\.Please_authenticate_to_use_app/S.of(context).pleaseAuthenticateToUseApp/g

s/localization\.Join_Group/localization.joinGroup/g
s/localization\.Buy_me_a_coffee/localization.buyMeACoffee/g
s/localization\.input_dirtyword/localization.inputDirtyword/g
s/localization\.pleaseInput_user_pubkey/localization.pleaseInputUserPubkey/g
s/localization\.Follow_set/localization.followSet/g
s/localization\.input_follow_set_name/localization.inputFollowSetName/g
s/localization\.edit_name/localization.editName/g
s/localization\.Follow_set_name_edit/localization.followSetNameEdit/g
s/localization\.invite_people_to_join/localization.invitePeopleToJoin/g
s/localization\.Create_Group/localization.createGroup/g
s/localization\.Find_Group/localization.findGroup/g
s/localization\.Search_for_public_groups/localization.searchForPublicGroups/g
s/localization\.Create_your_community/localization.createYourCommunity/g
s/localization\.name_your_community/localization.nameYourCommunity/g
s/localization\.community_name/localization.communityName/g
s/localization\.Discover_Groups/localization.discoverGroups/g
s/localization\.Active/localization.active/g
s/localization\.Start_or_join_a_community/localization.startOrJoinACommunity/g
s/localization\.Connect_with_others/localization.connectWithOthers/g
s/localization\.Have_invite_link/localization.haveInviteLink/g
s/localization\.leave_Group/localization.leaveGroup/g
s/localization\.leave_Group_Question/localization.leaveGroupQuestion/g
s/localization\.leave_Group_Confirmation/localization.leaveGroupConfirmation/g
s/localization\.admin_Panel/localization.adminPanel/g
s/localization\.Open_group/localization.openGroup/g
s/localization\.Closed_group/localization.closedGroup/g
s/localization\.Thread_Mode/localization.threadMode/g
s/localization\.Posts_And_Replies/localization.postsAndReplies/g
s/localization\.Please_authenticate_to_turn_off_the_privacy_lock/localization.pleaseAuthenticateToTurnOffThePrivacyLock/g
s/localization\.Please_authenticate_to_turn_on_the_privacy_lock/localization.pleaseAuthenticateToTurnOnThePrivacyLock/g
s/localization\.Please_authenticate_to_use_app/localization.pleaseAuthenticateToUseApp/g

EOL

# Apply all changes at once to all Dart files
echo "Applying all replacements at once..."
find "$PROJECT_DIR/lib" -name "*.dart" -print0 | xargs -0 sed -i '' -f /tmp/round5_patterns.sed

echo "Completed fifth round of localization fixes. Please run Flutter analyze to verify the changes."