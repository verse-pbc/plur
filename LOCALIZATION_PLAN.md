# Localization Refactoring Plan

## Overview

This document outlines the plan for resolving localization issues in the Plur application. The primary issue is that the code uses PascalCase or snake_case for localization keys (e.g., `localization.Cancel`, `localization.Community_Name`), while Flutter expects camelCase keys in ARB files (e.g., `localization.cancel`, `localization.communityName`).

## Current Status

- ARB files have been updated to use camelCase for all keys
- A test case (localization_test.dart) has been created to verify localization is working correctly
- Fixed a duplicate key issue in ARB files by renaming `communityName` to `communityNameHeader` for one instance
- Completed Phase 1 of the plan: Updated all editor component files to use camelCase localization keys
- Reduced the number of errors from 734 to 658 (76 issues fixed)

## Files Already Updated

1. datetime_picker_widget.dart
2. content_lnbc_widget.dart
3. content_relay_widget.dart
4. content_widget.dart
5. editor_mixin.dart
6. custom_emoji_add_dialog.dart
7. confirm_dialog.dart
8. color_pick_dialog.dart
9. group_edit_widget.dart
10. index_drawer_content.dart
11. name_input_step_widget.dart
12. community_guidelines_screen.dart
13. badge_award_widget.dart
14. badge_detail_widget.dart
15. gen_lnbc_widget.dart
16. poll_input_widget.dart
17. zap_goal_input_widget.dart
18. zap_split_input_widget.dart
19. pic_embed_builder.dart

## Approach

We'll systematically update all remaining localization keys in the codebase to use camelCase. To make this process efficient, we'll:

1. **Categorize Files**: Group files by component/feature to ensure related files are updated together
2. **Prioritize**: Focus on high-impact files first (UI screens, commonly used components)
3. **Batch Edits**: Use batch editing for files with multiple occurrences
4. **Incremental Verification**: Run tests periodically to ensure changes are working correctly

## Priority Categories

### High Priority (Critical UI Components)
- Remaining editor components
- Event display components
- Main navigation screens
- Settings screens

### Medium Priority (Secondary UI Components)
- Dialog components
- User profile components
- Group/community components
- Content display widgets

### Low Priority (Utilities and Infrequently Used Features)
- Utility classes
- Debug features
- Admin features

## Step-by-Step Implementation

### Phase 1: Complete Editor Components ✅
- [x] Update gen_lnbc_widget.dart
- [x] Update poll_input_widget.dart
- [x] Update remaining keys in editor_mixin.dart
- [x] Update zap_goal_input_widget.dart
- [x] Update zap_split_input_widget.dart
- [x] Update pic_embed_builder.dart

### Phase 2: Update Event Display Components
- [ ] Update event_main_widget.dart
- [ ] Update event_reactions_widget.dart
- [ ] Update event_poll_widget.dart
- [ ] Update event_zap_goals_widget.dart
- [ ] Update event_load_list_widget.dart

### Phase 3: Update Screen Widgets
- [ ] Update index_widget.dart
- [ ] Update group_detail_widget.dart
- [ ] Update settings_widget.dart
- [ ] Update user_widget.dart
- [ ] Update dm_widget.dart

### Phase 4: Update Dialogs and Secondary Components
- [ ] Update all dialog components
- [ ] Update image/media display components
- [ ] Update form input components

### Phase 5: Update Remaining Files
- [ ] Scan for any remaining localization key issues
- [ ] Update utility classes
- [ ] Update test files

## Implementation Guidelines

For each file:

1. **Search for localization keys**: Use grep or similar tools to find instances of `localization.` or `S.of(context).`
2. **Identify key patterns**: Identify PascalCase (e.g., `Cancel`) or snake_case (e.g., `Input_parse_error`) keys
3. **Convert to camelCase**: Follow standard camelCase conversion rules:
   - PascalCase → camelCase: `Cancel` → `cancel`
   - snake_case → camelCase: `Input_parse_error` → `inputParseError`
4. **Special cases**: Watch for reserved keywords and adjust accordingly (e.g., `continue` → `continueButton`)
5. **Run analyze**: After updating each batch, run `flutter analyze` to verify improvements

## Batch Processing Script (Optional)

For files with many localization keys, consider using a script to automate the conversion. A pseudocode example:

```
for file in files_to_update:
  for each match of "localization.X_Y" or "localization.XY":
    convert X_Y to xY (snake_case to camelCase)
    convert XY to xY (PascalCase to camelCase)
    update file with new key
```

## Testing Strategy

1. **After Each Phase**: 
   - Run `flutter analyze` to check for remaining issues
   - Run the localization test to verify key access

2. **After All Changes**:
   - Run the full test suite
   - Manually verify key UI screens

3. **Final Verification**:
   - Build and run the app in multiple locales
   - Verify that all text displays correctly

## Fallback Strategy

If any issues arise, or certain key conversions are problematic:
1. Consider keeping the original key in the ARB file but updating the code
2. Create a mapping layer between old and new keys if necessary
3. Document any exceptions to the standard pattern

## Timeline

Based on the total number of remaining issues (approximately 699) and rate of fixing:
- Estimated time: 3-4 days of focused work
- Breakdown: ~175 issues per day
- Each phase: ~1 day

## Risks and Considerations

- **Regression**: Changing localization keys could break existing functionality
- **Missed References**: Some keys might be referenced dynamically
- **Generated Files**: Auto-generated files might need special handling
- **Test Coverage**: Limited test coverage might miss issues

## Completion Criteria

The task will be considered complete when:
1. `flutter analyze` reports no undefined getter errors related to localization
2. All localization tests pass
3. The application builds and runs successfully
4. UI text displays correctly in at least 2-3 sample locales