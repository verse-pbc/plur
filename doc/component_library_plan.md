# Plur Component Library Plan

## Overview
This document outlines the plan to create an internal component library for the Plur app. The library will serve as a living style guide showcasing all standardized UI components, typography styles, and design patterns used throughout the application.

## Objectives
1. **Consistency**: Ensure UI consistency across all screens and features
2. **Documentation**: Provide a visual reference for developers and designers
3. **Development Speed**: Accelerate development by reusing standardized components
4. **Quality Assurance**: Test components in isolation to ensure they work correctly
5. **Design System**: Establish a foundation for the app's design system

## Access Location
- Add new menu item "Component Library" under Settings in the sidebar menu
- Route path: `/settings/components` or `/component-library`
- Only visible in development/debug mode initially

## Component Categories

### 1. Typography
Display all text styles with examples:
- **Headings**: H1-H6 with SF Pro Rounded Bold (46pt, 32pt, 24pt, 20pt, 18pt, 16pt)
- **Body Text**: Regular (17pt), Small (14pt), Caption (12pt)
- **Specialized Text**: Button labels, input text, placeholder text
- **Line Heights**: 120% for titles, 140% for body text
- **Color Variations**: Primary, Secondary, Accent, Error, Success
- **Font Weights**: Regular (400), Medium (500), Semibold (600), Bold (700)

### 2. Colors
Visual palette display:
- **Primary Colors**: Brand purple (#7445FE), Accent teal (#009994)
- **Text Colors**: 
  - Light mode: Primary (#4B3997), Secondary (#837AA0)
  - Dark mode: Primary (#B6A0E1), Secondary (#93A5B7), White
- **Background Colors**: 
  - Light/Dark variants for main background, surface, cards
  - Special backgrounds: Login (#150F23), Input (#11171F)
- **State Colors**: Error, Success, Warning, Info
- **Opacity Levels**: Examples at 100%, 70%, 50%, 30%, 15%

### 3. Buttons
All button types with states:

#### Primary Button (Filled)
- Normal, Hover, Active, Disabled, Loading
- Sizes: Large (18pt, 18px padding), Regular (16pt, 16px padding), Small (14pt, 12px padding)
- Example: "Create a Profile" button

#### Secondary Button (Outlined)
- Normal, Hover, Active, Disabled
- Same size variations as primary
- Example: "Login with Nostr" button

#### Text Button
- Normal, Hover, Active, Disabled
- Used for less prominent actions
- Example: Cancel, Skip actions

#### Icon Button
- With and without background
- Circular and square variants
- Example: Close (X) button in login sheet

### 4. Form Elements

#### Text Inputs
- Default state
- Hover state (border color change)
- Focus state (border color change)
- Error state (red border)
- Disabled state
- With/without icons
- Password visibility toggle
- Multi-line text areas

#### Select/Dropdown
- Closed state
- Open state with options
- Multi-select variant
- Search-enabled variant

#### Radio Buttons
- Unselected, Selected, Disabled states
- With labels
- In groups

#### Checkboxes
- Unchecked, Checked, Indeterminate, Disabled states
- With labels
- In lists

#### Toggle Switches
- Off/On states
- Disabled state
- With labels

### 5. Cards & Containers
- Basic card with padding and shadows
- Responsive card layouts
- Card with header/footer
- Nested cards
- List item containers

### 6. Navigation Components
- Tab bars (desktop and mobile variants)
- Sidebar menu items
- Bottom navigation (mobile)
- Breadcrumbs
- Pagination controls

### 7. Feedback Components
- Toast notifications
- Alert banners
- Progress indicators (circular, linear)
- Loading states
- Empty states
- Error states

### 8. Modals & Sheets
- Modal dialogs
- Bottom sheets (like login sheet)
- Side panels
- Popover menus
- Tooltips

### 9. Responsive Breakpoints
Show how components adapt at different screen sizes:
- Mobile: < 600px
- Tablet: 600px - 899px
- Desktop: ≥ 900px

## Implementation Structure

### 1. Component Library Screen Structure
```
/lib/router/component_library/
├── component_library_widget.dart          # Main screen
├── sections/
│   ├── typography_section.dart
│   ├── colors_section.dart
│   ├── buttons_section.dart
│   ├── forms_section.dart
│   ├── cards_section.dart
│   ├── navigation_section.dart
│   ├── feedback_section.dart
│   ├── modals_section.dart
│   └── responsive_section.dart
└── components/
    ├── section_header.dart
    ├── component_example.dart
    └── code_snippet.dart
```

### 2. Shared Component Structure
Organize reusable components:
```
/lib/component/shared/
├── buttons/
│   ├── primary_button.dart
│   ├── secondary_button.dart
│   └── text_button.dart
├── inputs/
│   ├── text_input.dart
│   ├── select_dropdown.dart
│   └── checkbox.dart
├── typography/
│   ├── heading.dart
│   └── body_text.dart
└── layout/
    ├── card.dart
    └── container.dart
```

### 3. Theme Extensions
Enhance the current theme system:
- Create comprehensive TextTheme definitions
- Standardize component themes (ButtonTheme, InputTheme, etc.)
- Define consistent spacing/padding values
- Create elevation/shadow standards

## Features

### 1. Interactive Examples
- Live component states (hover, focus, active)
- Editable properties (change text, toggle states)
- Copy code snippets
- Dark/Light mode toggle

### 2. Documentation
- Usage guidelines for each component
- Accessibility notes
- Platform-specific behaviors
- Best practices

### 3. Search & Filter
- Search components by name
- Filter by category
- Filter by platform (mobile/desktop)

### 4. Code Generation
- Copy component code with a single click
- Show implementation examples
- Include required imports

## Implementation Phases

### Phase 1: Foundation (Week 1)
1. Create basic component library screen structure
2. Add routing and menu item
3. Implement section navigation
4. Create example component wrapper

### Phase 2: Core Components (Week 2)
1. Typography section with all text styles
2. Colors section with palette display
3. Primary and secondary buttons
4. Basic text input

### Phase 3: Form Elements (Week 3)
1. Complete input variations
2. Select/dropdown components
3. Radio buttons and checkboxes
4. Form validation states

### Phase 4: Layout & Navigation (Week 4)
1. Card components
2. Navigation elements
3. Responsive examples
4. Modal/sheet examples

### Phase 5: Polish & Documentation (Week 5)
1. Add interactive features
2. Code snippet generation
3. Search functionality
4. Usage documentation

## Success Metrics
1. All existing components are documented
2. New components follow established patterns
3. Reduced inconsistencies in UI
4. Faster component development
5. Improved onboarding for new developers

## Future Enhancements
1. Figma plugin to sync designs
2. Automated visual regression testing
3. Component usage analytics
4. Version history for components
5. A/B testing variants
6. Integration with design tools

## Technical Considerations
1. Performance: Lazy load sections to improve initial load
2. Accessibility: Ensure all examples are accessible
3. Testing: Unit tests for all shared components
4. Documentation: Inline documentation for all props
5. Versioning: Track component changes over time

## Conclusion
The component library will serve as the single source of truth for UI components in the Plur app. It will improve consistency, speed up development, and provide a better foundation for scaling the application's UI.