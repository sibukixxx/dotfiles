# User Stories Guide

## Table of Contents
1. [Format](#format)
2. [INVEST Criteria](#invest-criteria)
3. [Acceptance Criteria](#acceptance-criteria)
4. [Examples by Domain](#examples-by-domain)

## Format

### Standard Template
```
As a [persona/user type],
I want [goal/action],
So that [benefit/value].
```

### With Acceptance Criteria
```
As a [persona],
I want [goal],
So that [benefit].

Acceptance Criteria:
- Given [context], when [action], then [outcome]
- Given [context], when [action], then [outcome]
```

## INVEST Criteria

Good user stories are:

| Criteria | Description |
|----------|-------------|
| **I**ndependent | Can be developed separately |
| **N**egotiable | Details can be discussed |
| **V**aluable | Provides value to users |
| **E**stimable | Can be estimated |
| **S**mall | Fits in one sprint |
| **T**estable | Has clear acceptance criteria |

## Acceptance Criteria

### Given-When-Then Format
```
Given I am a logged-in user
When I click the "Export" button
Then a CSV file downloads containing my data
```

### Checklist Format
```
Acceptance Criteria:
[ ] User can select date range
[ ] Export includes all visible columns
[ ] File name includes timestamp
[ ] Works in Chrome, Firefox, Safari
```

## Examples by Domain

### E-commerce
```
As a shopper,
I want to save items to a wishlist,
So that I can purchase them later.

Acceptance Criteria:
- Given I am viewing a product, when I click "Add to Wishlist",
  then the item appears in my wishlist
- Given I have items in my wishlist, when I view my wishlist,
  then I see item name, price, and availability
- Given an item is out of stock, when it becomes available,
  then I receive a notification
```

### SaaS
```
As an admin,
I want to set role-based permissions,
So that team members only access appropriate features.

Acceptance Criteria:
- Given I am an admin, when I create a role,
  then I can select from available permissions
- Given a user has a role, when they log in,
  then they only see permitted features
- Given permissions change, when user refreshes,
  then new permissions apply immediately
```

### API
```
As a developer,
I want to authenticate via API key,
So that I can integrate the service programmatically.

Acceptance Criteria:
- Given a valid API key, when I make a request,
  then I receive a 200 response
- Given an invalid API key, when I make a request,
  then I receive a 401 response with error message
- Given rate limit exceeded, when I make a request,
  then I receive 429 with retry-after header
```

### Mobile App
```
As a mobile user,
I want to receive push notifications for order updates,
So that I stay informed without opening the app.

Acceptance Criteria:
- Given I have notifications enabled, when my order ships,
  then I receive a push notification
- Given I tap the notification, when the app opens,
  then I see the order details
- Given I have notifications disabled, when my order ships,
  then I receive no notification but see in-app badge
```
