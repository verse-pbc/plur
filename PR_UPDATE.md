# Communities Grid Responsive Layout & Loading Improvements

## Summary
This PR enhances the communities grid to be responsive to different screen sizes and fixes issues with community icons and labels not appearing properly on initial load.

## Implements CHANGELOG Items

### From Internal Changes Section
- ✅ **"Improve communities grid with responsive column count for different screen sizes"**
- ✅ **"Fix loading issue with community icons and labels on initial render"**
- ✅ **"Update deprecated color API usage throughout the app to use withAlpha instead of withOpacity"**

## Technical Changes

### Responsive Grid Layout
- Modified the communities grid to dynamically adjust the number of columns based on screen width:
  - 2 columns for mobile screens (default)
  - 3 columns for medium screens (width > 800px) 
  - 4 columns for large screens (width > 1200px)
- Implemented LayoutBuilder in both community grid widgets to detect available width
- Created _calculateCrossAxisCount method to determine appropriate column count
- Made the grid responsive while maintaining consistent spacing and proportions

### Loading State Improvements
- Fixed issue where community icons and labels appeared blank until scrolling
- Added immediate data fetch in initState to begin loading right away
- Enhanced image loading with faster fade-in animations (100ms)
- Removed ShimmerLoading which may have contributed to flickering
- Improved placeholder appearance with theme-consistent colors
- Fixed community_title_widget.dart placeholder to use theme colors instead of solid black

### Color API Modernization
- Updated deprecated .withOpacity() usage to .withAlpha() for better precision
- Modified group_avatar_widget.dart and community_title_widget.dart to use withAlpha
- Ensured consistent color transparency handling throughout components

## Testing
- Verified changes using the Flutter analyzer tool (no errors or warnings)
- Manually tested on different screen sizes to confirm responsive behavior
- Verified community icons load correctly on first render without requiring scroll interaction
- Ensured theme-consistent placeholder appearance in both light and dark modes

## Benefits
- Better UI experience on larger screens with optimized column count
- Fixed frustrating blank community icons on initial page load
- Improved visual consistency with theme-matching placeholders
- Reduced deprecation warnings by using recommended color APIs
- Cleaner codebase with removal of unnecessary shimmer loading widget
- More efficient image loading with optimized fade-in duration

## Impact 
The changes provide a significantly improved user experience when viewing the communities grid. Users will now see properly formatted grids that take advantage of larger screen real estate, and community icons appear immediately without requiring user interaction to trigger their display. The app also follows Flutter's latest best practices for color handling and responsive layouts, making it more maintainable and forward-compatible.