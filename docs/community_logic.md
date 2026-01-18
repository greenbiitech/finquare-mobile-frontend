# FinSquare Community Logic

## Overview
FinSquare is a community-based financial app. This document defines the rules and logic governing community membership.

---

## 1. Default Community Membership

### Core Principle
> **Every user must belong to at least one community at all times.**

### FinSquare Community (Default/Fallback)
- **FinSquare Community** is a special, system-seeded community that exists in the database by default.
- It serves as the fallback community for users who don't belong to any other community.
- Users can only see FinSquare Community if they are a member of it.
- **No Admin** - Everyone in FinSquare Community is just a Member.

### Behavior
| Scenario | Result |
|----------|--------|
| User creates account with no community | User becomes a member of **FinSquare Community** |
| User joins another community | User is **removed** from FinSquare Community |
| User creates their own community | User is **removed** from FinSquare Community |
| User leaves ALL their communities | User **returns** to FinSquare Community |

### Example
> Wilson creates an account on FinSquare. He doesn't create or join any community.
> **Result**: Wilson is automatically a member of FinSquare Community.
>
> Later, Wilson joins "Lagos Tech Cooperative".
> **Result**: Wilson is removed from FinSquare Community. He no longer sees it in the app.
>
> Wilson then leaves "Lagos Tech Cooperative" and has no other communities.
> **Result**: Wilson is automatically placed back into FinSquare Community.

---

## 2. Multiple Community Membership

### Rule
- A user can belong to **multiple communities** simultaneously.
- A user can **create multiple communities**.
- There is no limit to how many communities a user can join or create.

### Example
> Wilson can be a member of:
> - "Lagos Tech Cooperative" (as Admin - he created it)
> - "University Alumni Association" (as Member)
> - "Neighborhood Savings Group" (as Co-Admin - promoted by Admin)
>
> All at the same time.

---

## 3. Active Community

### Concept
When a user belongs to multiple communities, one community is designated as the **Active Community**.

### Behavior
| Aspect | Description |
|--------|-------------|
| **Context** | The Active Community determines what the user sees and can do in the app |
| **Switching** | Users can switch between their communities |
| **Persistence** | The Active Community persists across app sessions (saved when app closes) |
| **Rights** | User's rights/limitations depend on their role **in the Active Community** |

### Role Context Example
> Wilson is:
> - **Admin** in "Lagos Tech Cooperative"
> - **Member** in "University Alumni Association"
>
> When Active Community = "Lagos Tech Cooperative" → Wilson has Admin rights
> When Active Community = "University Alumni Association" → Wilson has Member rights only

---

## 4. Community Roles

There are **3 roles** within a community:

### Admin (Creator)
- The user who **creates** a community is automatically the **Admin**.
- There is only **ONE Admin** per community (the creator).
- Admin **cannot leave** the community - they can only **delete** it.

### Co-Admin (Promoted)
- A Member promoted by the Admin.
- Can be **demoted** back to Member by Admin.
- Multiple Co-Admins allowed.

### Member
- A user who **joins** an existing community.
- Can **leave freely** at any time.

---

## 5. Role Permissions

| Action | Admin | Co-Admin | Member |
|--------|:-----:|:--------:|:------:|
| View community content | ✅ | ✅ | ✅ |
| Participate in dues/esusu/contributions | ✅ | ✅ | ✅ |
| Leave community | ❌ | ✅ | ✅ |
| **Invite members** | ✅ | ✅ | ❌ |
| **Change community logo** | ✅ | ✅ | ❌ |
| **Promote Member to Co-Admin** | ✅ | ❌ | ❌ |
| **Demote Co-Admin to Member** | ✅ | ❌ | ❌ |
| **Remove any member** (including Co-Admin) | ✅ | ❌ | ❌ |
| **Create dues/esusu/contribution** | ✅ | ❌ | ❌ |
| **Create community wallet** | ✅ | ❌ | ❌ |
| **Withdraw from community wallet** | ✅ | ❌ | ❌ |
| **View community wallet balance** | ✅ | ✅ | ❌ |
| **Edit community details** | ✅ | Partial | ❌ |
| **Delete community** | ✅* | ❌ | ❌ |

> *Admin can only delete community if there are **no active** Esusu/Dues/Contributions
>
> *More Co-Admin permissions will be defined as features are built

---

## 6. Leaving & Deletion Rules

### Admin
- ❌ Cannot leave their community
- ❌ Cannot transfer Admin role to anyone else (Admin is permanent)
- ✅ Can delete the community (with conditions)

### Deletion Conditions
Admin can only delete a community if:
- No active Esusu
- No active Dues
- No active Contributions
- (More conditions TBD)

### Co-Admin & Member Leaving
- ✅ Can leave **only if** they have no active participation
- ❌ Cannot leave if they have:
  - Active Dues payment
  - Active Esusu participation
  - Active Contributions
  - Any other ongoing financial obligation

### Removal by Admin
- ✅ Admin can remove Members/Co-Admins
- ❌ Admin **cannot remove** a member who has active Esusu participation
- Members with active financial obligations must complete or settle them first

---

## 7. FinSquare Community (Special Rules)

| Aspect | Regular Community | FinSquare Community |
|--------|-------------------|---------------------|
| Admin | Yes (creator) | **No** |
| Co-Admin | Yes (promoted) | **No** |
| Members | Yes | **Yes (everyone)** |
| Dues/Esusu/Contributions | ✅ Yes | ❌ **No** |
| Group Buying | ✅ Yes | ✅ **Yes** |
| Community wallet | Yes | **No** |
| User can leave | Members/Co-Admins | **No** (auto-managed) |

### Features Available in FinSquare Community
| Feature | Available |
|---------|:---------:|
| Group Buying | ✅ |
| Dues | ❌ |
| Esusu (Rotational Savings) | ❌ |
| Contributions | ❌ |
| Community Wallet | ❌ |

> **Note**: FinSquare Community is a **limited community** for users who haven't joined/created their own community. To access Dues, Esusu, and Contributions, users must join or create a regular community.

---

## 8. Community Invites

There are **two types** of community invites:

### Type 1: Email-Based Invite (Specific)

Admin manually invites specific people using their email addresses.

#### Flow
```
Admin enters emails (e.g., 10 people)
           │
           ▼
Each person receives a unique invite link
           │
           ▼
    ┌──────────────────┐
    │  User taps link  │
    └────────┬─────────┘
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
Has Account?      No Account?
    │                 │
    ▼                 ▼
Auto-join        Email is "reserved"
community        for this community
    │                 │
    ▼                 ▼
App installed?   When user creates account
    │            with this email → Auto-join
    ▼                 │
Yes → Open App        ▼
No → Redirect to   App installed?
     Play Store/      │
     App Store        ▼
                 Yes → Open App
                 No → Redirect to Store
```

#### Key Points
- Each invited email gets a **unique link**
- If email already has account → **immediate join**
- If email has no account → **reserved**, auto-joins when account is created
- Deep linking: Opens app if installed, otherwise redirects to store

---

### Type 2: General Link Invite (Public/Shareable)

A shareable link (like Telegram) that can be posted anywhere.

#### Admin Configuration Options
| Option | Description |
|--------|-------------|
| **Join Type** | `Open` (auto-join) OR `Approval Required` |
| **Expiry** | When the link becomes invalid (or open-ended if not set) |

#### Link Format
The invite link follows this format:
```
https://finsquare.greenbii.com/invite/{TOKEN}
```
Example: `https://finsquare.greenbii.com/invite/CMT-A1B2C3D4E5F6G7H8`

#### Flow
```
Admin creates/configures invite link
    │
    ├── Configures: Open OR Approval Required
    ├── Sets expiry date (optional)
    │
    ▼
Link can be shared anywhere (WhatsApp, social media, etc.)
    │
    ▼
    ┌──────────────────┐
    │  User taps link  │
    └────────┬─────────┘
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
App Installed?    App NOT Installed?
    │                 │
    ▼                 ▼
Open app with     Redirect to Play Store
join modal        (After install, user
    │              taps link again →
    ▼              continue flow)
```

#### Flow When App Opens (User has account)
```
Join Modal Appears
    │
    ├── Shows community name, logo, color
    ├── Shows join type (Open/Approval Required)
    │
    ▼
User taps "Join"
    │
    ▼
    ┌────────────────────┐
    │  Check Join Type   │
    └─────────┬──────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
  OPEN              APPROVAL_REQUIRED
    │                   │
    ▼                   ▼
Auto-join          Create pending request
immediately        Admin gets notified
    │                   │
    ▼                   ▼
Notification:      Notification:
"Welcome to        "Your request has
{community}!"      been submitted"
    │                   │
    ▼                   ▼
Redirect to        Admin reviews →
Dashboard          Approve/Reject
                        │
                        ▼
                   User notified
                   of decision
```

#### Key Points
- Single link for many people
- Only ONE active invite link per community at a time
- Admin chooses: auto-join or approval required
- Link can have expiry date or be open-ended
- Deep linking: Opens app if installed, otherwise redirects to Play Store

---

## Invite Rules & Clarifications

### Email Invite Rules
| Rule | Description |
|------|-------------|
| Invite to other community member | ✅ Allowed (multi-community) |
| Invite someone already in YOUR community | ❌ Not allowed |
| Email reservation expiry | ❌ No expiry (reservation persists until used or revoked) |
| Revoke email invite | ✅ Admin can revoke anytime |

### General Link Configuration
| Option | Description |
|--------|-------------|
| Join Type | `OPEN` (auto-join) OR `APPROVAL_REQUIRED` (needs admin approval) |
| Expiry Date | When the link becomes invalid (optional - can be open-ended) |
| Active Link | ❗ Only ONE active invite link per community at a time |
| Revoke/Update | ✅ Admin can update or deactivate the link anytime |

### Approval Queue
- Dedicated screen for Admin/Co-Admin to see pending approval requests
- Can approve or reject individually
- ✅ Push notifications implemented for new requests

### Already a Member Scenario
When someone who is already a member taps an invite link:
- Show message: "You're already a member of this community"
- If app is installed: Option to switch to that community

### Who Can Manage Invites?
| Role | Can Manage Invites |
|------|:------------------:|
| Admin | ✅ |
| Co-Admin | ✅ |
| Member | ❌ |

---

## 9. Community Wallet

### Overview
Each community can have **one Community Wallet** that serves as the central fund for that community.

### Prerequisites for Creating Community Wallet
| Requirement | Description |
|-------------|-------------|
| **Admin's Personal Wallet** | Admin must have their personal wallet setup first |
| **2 Co-Admin Signatories** | Admin must designate 2 Co-Admins as signatories |

> **Note**: A community can exist without a wallet. Admin doesn't need Co-Admins to create the community, but must have at least 2 Co-Admins to setup the wallet signatories.

### Signatory System
- **Purpose**: Record-keeping and accountability (not approval-based)
- **Count**: Exactly 2 Co-Admins must be designated as signatories
- **Approval**: Signatories do NOT need to approve withdrawals
- **Flexibility**: Signatories can leave the community freely - doesn't affect wallet operations

### Fund Sources
Money flows INTO the Community Wallet from:
- Dues payments
- Esusu contributions
- Other contributions
- (All community financial activities)

### Withdrawals
| Aspect | Rule |
|--------|------|
| **Who can withdraw** | Admin only |
| **Withdrawal limits** | None |
| **Signatory approval** | Not required |
| **Frequency limits** | None |

### Visibility & Access

| Aspect | Admin | Co-Admin | Member |
|--------|:-----:|:--------:|:------:|
| View wallet balance | ✅ | ✅ | ❌ |
| View transaction history | ✅ | ✅ | ❌ |
| Make withdrawals | ✅ | ❌ | ❌ |

> Regular members cannot see the community wallet balance or transaction history at all.

### Key Rules
| Rule | Description |
|------|-------------|
| **One wallet per community** | No multiple wallets - single total balance |
| **Signatory changes** | Not needed - signatories can leave freely |
| **No member visibility** | Wallet is completely hidden from regular members |

### Wallet Creation Flow
```
Admin wants to create Community Wallet
              │
              ▼
    ┌─────────────────────┐
    │ Personal wallet     │
    │ setup?              │
    └──────────┬──────────┘
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
      Yes              No
       │               │
       ▼               ▼
  Continue         Must setup personal
       │           wallet first
       ▼
    ┌─────────────────────┐
    │ Has 2+ Co-Admins?   │
    └──────────┬──────────┘
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
      Yes              No
       │               │
       ▼               ▼
  Select 2          Must promote at
  signatories       least 2 Co-Admins
       │
       ▼
  Wallet Created ✅
```

---

## 10. Push Notifications

### Community-Related Notifications

| Event | Recipient | Title | Description |
|-------|-----------|-------|-------------|
| Community created | Admin (creator) | Community Created! | Your community "{name}" has been created successfully. |
| Member joins via open link | New member | Welcome to {name}! | You're now a member of {community name}. |
| New join request | All Admins & Co-Admins | New Join Request | {user name} wants to join {community name}. |
| Join request approved | Requesting user | Request Approved! | Your request to join {community name} has been approved. |
| Join request rejected | Requesting user | Request Declined | Your request to join {community name} was not approved. |

### Notification Flow Diagram

```
User joins via OPEN link
         │
         ▼
   ┌───────────────┐
   │ User receives │
   │ "Welcome!"    │
   │ notification  │
   └───────────────┘

User requests to join via APPROVAL_REQUIRED link
         │
         ▼
   ┌────────────────────┐
   │ All Admins &       │
   │ Co-Admins receive  │
   │ "New Join Request" │
   └─────────┬──────────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
   APPROVE       REJECT
      │             │
      ▼             ▼
   User gets    User gets
   "Approved"   "Declined"
   notification notification
```

---

## Important Notes

- **Only Admins** can create Esusu, Dues, and Contributions
- Esusu, Dues, and Contributions each have their own separate documentation files

---

## Summary Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      COMMUNITY ROLES                         │
└─────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   ADMIN     │ ◄── Creates community (1 per community)
    │  (Creator)  │     Cannot leave, can only delete
    └──────┬──────┘
           │ promotes/demotes
           ▼
    ┌─────────────┐
    │  CO-ADMIN   │ ◄── Promoted by Admin (multiple allowed)
    │ (Promoted)  │     Can see wallet balance
    └──────┬──────┘     Can leave freely
           │
           ▼
    ┌─────────────┐
    │   MEMBER    │ ◄── Joins community
    │  (Joined)   │     Can leave freely
    └─────────────┘


┌─────────────────────────────────────────────────────────────┐
│                 FINSQUARE COMMUNITY                          │
│                    (Special/Default)                         │
├─────────────────────────────────────────────────────────────┤
│  • No Admin, No Co-Admin                                     │
│  • Everyone is a Member                                      │
│  • Auto-join when user has no other community               │
│  • Auto-leave when user joins/creates another community     │
│  • Cannot be deleted                                         │
└─────────────────────────────────────────────────────────────┘
```

---

*Document Status: Complete. Community logic, invite system, and push notifications fully defined.*

---

## Related Documentation
- `docs/dues_logic.md` - Dues feature logic (TBD)
- `docs/esusu_logic.md` - Esusu (rotational savings) logic (TBD)
- `docs/contributions_logic.md` - Contributions logic (TBD)
- `docs/group_buying_logic.md` - Group Buying logic (TBD)
