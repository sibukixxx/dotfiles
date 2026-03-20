# Frontend Design: デザインパターン集

## Color Usage

```
Primary: Use for main CTAs and key elements (sparingly)
Secondary: Supporting elements, secondary actions
Neutral: Text, backgrounds, borders (majority of UI)
Accent: Highlights, success/error states
```

## Typography Scale

```
Headings: Clear hierarchy (h1 > h2 > h3)
Body: 16px base, 1.5 line-height for readability
Small: 14px for captions, metadata
```

## Spacing System

```
Use consistent increments: 4px, 8px, 16px, 24px, 32px, 48px, 64px
Apply rhythm: same spacing within sections, larger between sections
```

## Task Workflows

### Landing Page / Website

1. **Structure Planning**
   - Define sections: hero, features, CTA, footer
   - Plan responsive breakpoints
   - Identify key interactions

2. **Implementation**
   - Start with mobile layout
   - Build section by section
   - Add micro-interactions last

3. **Quality Check**
   - Test all breakpoints
   - Verify accessibility
   - Optimize images and assets

### React/Vue Component

1. **Component Design**
   - Define props interface clearly
   - Plan variants and states (hover, active, disabled)
   - Consider composition patterns

2. **Implementation**
   - Build base component first
   - Add variants via props
   - Extract reusable sub-components

3. **Quality Check**
   - Test all prop combinations
   - Verify keyboard accessibility
   - Document usage examples

## Anti-Patterns to Avoid

- Over-styling (excessive shadows, gradients, animations)
- Inconsistent spacing and alignment
- Poor color contrast (accessibility failure)
- Hardcoded values instead of design tokens
- Overly complex component hierarchies
- Ignoring mobile/responsive design
