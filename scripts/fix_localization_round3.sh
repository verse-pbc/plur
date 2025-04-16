#!/bin/bash

# Third round of localization fixes focusing on remaining keys

# Directory containing the code
PROJECT_DIR="/Users/rabble/code/verse/plur"
cd "$PROJECT_DIR" || exit 1

echo "Starting third round of localization fixes..."

# Find and fix common patterns all at once using a big sed command file
cat > /tmp/sed_commands_round3.txt << 'EOL'
s/S\.of(context)\.Join_Group/S.of(context).joinGroup/g
s/S\.of(context)\.copy_current_Url/S.of(context).copyCurrentUrl/g
s/S\.of(context)\.copy_init_Url/S.of(context).copyInitUrl/g
s/S\.of(context)\.Open_in_browser/S.of(context).openInBrowser/g
s/S\.of(context)\.WebRTC_Permission/S.of(context).webRTCPermission/g
s/S\.of(context)\.Sign_fail/S.of(context).signFail/g
s/S\.of(context)\.input_Comment/S.of(context).inputComment/g
s/S\.of(context)\.Number_parse_error/S.of(context).numberParseError/g
s/S\.of(context)\.Zap_number_not_enough/S.of(context).zapNumberNotEnough/g
s/S\.of(context)\.File_is_too_big_for_NIP_95/S.of(context).fileIsTooBigForNIP95/g
s/S\.of(context)\.What_s_happening/S.of(context).whatSHappening/g
s/S\.of(context)\.add_to_known_list/S.of(context).addToKnownList/g
s/S\.of(context)\.send_fail/S.of(context).sendFail/g
s/S\.of(context)\.Input_account_private_key/S.of(context).inputAccountPrivateKey/g
s/S\.of(context)\.Add_account_and_login/S.of(context).addAccountAndLogin/g
s/S\.of(context)\.Please_do_not_disclose_or_share_the_key_to_anyone/S.of(context).pleaseDoNotDiscloseOrShareTheKeyToAnyone/g
s/S\.of(context)\.Nostrmo_developers_will_never_require_a_key_from_you/S.of(context).nostrmoDevelopersWillNeverRequireAKeyFromYou/g
s/S\.of(context)\.Please_keep_the_key_properly_for_account_recovery/S.of(context).pleaseKeepTheKeyProperlyForAccountRecovery/g
s/S\.of(context)\.Backup_and_Safety_tips/S.of(context).backupAndSafetyTips/g
s/S\.of(context)\.The_key_is_a_random_string_that_resembles/S.of(context).theKeyIsARandomStringThatResembles/g
s/S\.of(context)\.Copy_Key/S.of(context).copyKey/g
s/S\.of(context)\.Copy_and_Continue/S.of(context).copyAndContinue/g
s/S\.of(context)\.Copy_Hex_Key/S.of(context).copyHexKey/g
s/S\.of(context)\.Please_check_the_tips/S.of(context).pleaseCheckTheTips/g
s/S\.of(context)\.thread_mode/S.of(context).threadMode/g
s/S\.of(context)\.Max_Sub_Notes/S.of(context).maxSubNotes/g
s/S\.of(context)\.Full_Mode/S.of(context).fullMode/g
s/S\.of(context)\.Trace_Mode/S.of(context).traceMode/g
s/S\.of(context)\.Please_input_the_max_sub_notes_number/S.of(context).pleaseInputTheMaxSubNotesNumber/g

s/localization\.Join_Group/localization.joinGroup/g
s/localization\.copy_current_Url/localization.copyCurrentUrl/g
s/localization\.copy_init_Url/localization.copyInitUrl/g
s/localization\.Open_in_browser/localization.openInBrowser/g
s/localization\.WebRTC_Permission/localization.webRTCPermission/g
s/localization\.Sign_fail/localization.signFail/g
s/localization\.input_Comment/localization.inputComment/g
s/localization\.Number_parse_error/localization.numberParseError/g
s/localization\.Zap_number_not_enough/localization.zapNumberNotEnough/g
s/localization\.File_is_too_big_for_NIP_95/localization.fileIsTooBigForNIP95/g
s/localization\.What_s_happening/localization.whatSHappening/g
s/localization\.add_to_known_list/localization.addToKnownList/g
s/localization\.send_fail/localization.sendFail/g
s/localization\.Input_account_private_key/localization.inputAccountPrivateKey/g
s/localization\.Add_account_and_login/localization.addAccountAndLogin/g
s/localization\.Please_do_not_disclose_or_share_the_key_to_anyone/localization.pleaseDoNotDiscloseOrShareTheKeyToAnyone/g
s/localization\.Nostrmo_developers_will_never_require_a_key_from_you/localization.nostrmoDevelopersWillNeverRequireAKeyFromYou/g
s/localization\.Please_keep_the_key_properly_for_account_recovery/localization.pleaseKeepTheKeyProperlyForAccountRecovery/g
s/localization\.Backup_and_Safety_tips/localization.backupAndSafetyTips/g
s/localization\.The_key_is_a_random_string_that_resembles/localization.theKeyIsARandomStringThatResembles/g
s/localization\.Copy_Key/localization.copyKey/g
s/localization\.Copy_and_Continue/localization.copyAndContinue/g
s/localization\.Copy_Hex_Key/localization.copyHexKey/g
s/localization\.Please_check_the_tips/localization.pleaseCheckTheTips/g
s/localization\.thread_mode/localization.threadMode/g
s/localization\.Max_Sub_Notes/localization.maxSubNotes/g
s/localization\.Full_Mode/localization.fullMode/g
s/localization\.Trace_Mode/localization.traceMode/g
s/localization\.Please_input_the_max_sub_notes_number/localization.pleaseInputTheMaxSubNotesNumber/g
EOL

# Apply all changes at once to all Dart files
echo "Applying all replacements at once..."
find "$PROJECT_DIR/lib" -name "*.dart" -print0 | xargs -0 sed -i '' -f /tmp/sed_commands_round3.txt

echo "Completed third round of localization fixes. Please run Flutter analyze to verify the changes."