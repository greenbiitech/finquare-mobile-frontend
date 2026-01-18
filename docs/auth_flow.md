# FinSquare Authentication Flow

## Overview
This document defines the complete authentication flow for FinSquare, including signup, verification, passkey setup, and login flows.

---

## 1. User States

Every user has the following state flags that determine their app flow:

| Flag | Type | Description |
|------|------|-------------|
| `isVerified` | boolean | OTP verified (user exists in DB) |
| `hasPasskey` | boolean | User has created a 5-digit passkey |
| `hasPickedMembership` | boolean | User has completed membership selection |

### State Progression
```
New User → isVerified=false (not in DB yet)
    ↓ (verify OTP)
isVerified=true, hasPasskey=false, hasPickedMembership=false
    ↓ (create passkey)
isVerified=true, hasPasskey=true, hasPickedMembership=false
    ↓ (pick membership)
isVerified=true, hasPasskey=true, hasPickedMembership=true → FULL ACCESS
```

---

## 2. Signup Flow

### Step 1: Registration (Not in DB yet)
User provides:
- Full Name (first + last)
- Email
- Phone Number
- Password

**Backend Action:**
- Validate email/phone uniqueness (check against Users table)
- Generate 6-digit OTP
- Store in temporary `OtpVerification` table:
  - email, phoneNumber, fullName, password (hashed)
  - otp, expiresAt (15 minutes)
- Send SAME OTP to both email (ZeptoMail) and SMS (Termii)

### Step 2: OTP Verification
User enters 6-digit OTP received via email/SMS.

**Backend Action:**
- Verify OTP matches and not expired
- Create user in `Users` table:
  - isVerified = true
  - hasPasskey = false
  - hasPickedMembership = false
- Delete OTP record
- Return JWT token + user object

### Step 3: Create Passkey (Required)
User creates 5-digit passkey and confirms it.

**Backend Action:**
- Hash passkey with bcrypt
- Store in user.passkey
- Set hasPasskey = true
- Return updated user

### Step 4: Pick Membership (Required)
User chooses:
- **"Individual"** → Auto-join FinSquare Community → Home
- **"Community"** → Community registration flow

**Backend Action (Individual):**
- Add user to FinSquare Community as MEMBER
- Set hasPickedMembership = true
- Return updated user + community

**Backend Action (Community):**
- User completes community creation flow
- On success: set hasPickedMembership = true
- If user exits before completion: hasPickedMembership remains false

---

## 3. Login Flows

### Flow A: First-Time Login (No Passkey)
**Condition:** `hasPasskey = false`

```
User enters: Email/Phone + Password
    ↓
Validate credentials
    ↓
Return JWT + user (hasPasskey=false)
    ↓
App redirects to: "Create Passkey" screen
    ↓
After passkey creation → Check hasPickedMembership
    ↓
If false → "Pick Membership" screen
If true → Home
```

### Flow B: Returning User (Has Passkey)
**Condition:** `hasPasskey = true`

```
App checks: Has stored userId/token?
    ↓
YES → Show "Welcome Back" screen (Passkey entry)
NO → Show Login screen (Email/Phone + Password)
    ↓
If Login screen used:
    → Validate credentials
    → Return JWT + user
    → Show "Welcome Back" screen (Passkey entry)
    ↓
User enters 5-digit passkey
    ↓
Validate passkey against stored hash
    ↓
Success → Check hasPickedMembership
    ↓
If false → "Pick Membership" screen
If true → Home
```

### Flow C: "Not You? Log out"
From "Welcome Back" screen, user can log out to switch accounts.

```
User taps "Log out"
    ↓
Clear stored token/userId
    ↓
Show Login screen (Email/Phone + Password)
```

---

## 4. Password Reset Flow

### Step 1: Request Reset
User provides: Email OR Phone

**Backend Action:**
- Find user by email/phone
- Generate 6-digit OTP
- Create `PasswordReset` record:
  - token (UUID), otp, expiresAt (15 minutes), verified = false
- Send OTP to email AND SMS
- Return reset token (not OTP)

### Step 2: Verify OTP
User enters 6-digit OTP.

**Backend Action:**
- Validate token + OTP combination
- Check not expired
- Set verified = true
- Return success

### Step 3: Enter New Password
User enters new password + confirmation.

**Backend Action:**
- Verify reset record exists and verified = true
- Hash new password
- Update user.password
- Delete PasswordReset record
- Return success

### Step 4: Success → Login
User taps "Login" button → Navigate to Login screen.

---

## 5. API Endpoints

### Auth Module
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/signup` | Register (creates OTP, not user) |
| POST | `/api/v1/auth/verify-otp` | Verify OTP, create user |
| POST | `/api/v1/auth/resend-otp` | Resend signup OTP |
| POST | `/api/v1/auth/login` | Login with email/phone + password |
| POST | `/api/v1/auth/login-passkey` | Login with userId + passkey |
| POST | `/api/v1/auth/create-passkey` | Create 5-digit passkey |
| POST | `/api/v1/auth/request-reset` | Request password reset |
| POST | `/api/v1/auth/verify-reset-otp` | Verify reset OTP |
| POST | `/api/v1/auth/reset-password` | Set new password |
| POST | `/api/v1/auth/resend-reset-otp` | Resend reset OTP |

---

## 6. Response Structures

### Login Response (Email/Phone + Password)
```json
{
  "success": true,
  "data": {
    "token": "jwt-token-here",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "phoneNumber": "+2348012345678",
      "fullName": "John Doe",
      "firstName": "John",
      "lastName": "Doe",
      "isVerified": true,
      "hasPasskey": true,
      "hasPickedMembership": false
    }
  }
}
```

### Login Response (Passkey)
```json
{
  "success": true,
  "data": {
    "token": "jwt-token-here",
    "user": { ... },
    "activeCommunity": {
      "id": "uuid",
      "name": "FinSquare Community",
      "role": "MEMBER"
    }
  }
}
```

---

## 7. Client-Side Storage

Using `flutter_secure_storage`:

| Key | Value | When Stored |
|-----|-------|-------------|
| `accessToken` | JWT token | After any successful login |
| `userId` | User UUID | After any successful login |
| `hasPasskey` | "true"/"false" | After login response |
| `hasPickedMembership` | "true"/"false" | After login response |

### App Startup Logic
```
App launches
    ↓
Check: accessToken exists?
    ↓
NO → Show Onboarding/Login
YES → Check: hasPasskey?
    ↓
NO → Validate token with backend → "Create Passkey"
YES → Show "Welcome Back" (Passkey entry)
```

---

## 8. OTP Specifications

| Aspect | Value |
|--------|-------|
| Length | 6 digits |
| Expiry | 15 minutes |
| Delivery | Email (ZeptoMail) + SMS (Termii) simultaneously |
| Same OTP | Yes, same code sent to both channels |

---

## 9. Passkey Specifications

| Aspect | Value |
|--------|-------|
| Length | 5 digits |
| Hashing | bcrypt (10 rounds) |
| Purpose | Quick login after initial password login |
| Biometric | Placeholder for future (not implemented) |

---

## 10. Security Considerations

- Passwords hashed with bcrypt (10 rounds)
- Passkeys hashed with bcrypt (10 rounds)
- JWT tokens for API authentication
- OTP expires after 15 minutes
- Rate limiting on OTP endpoints (TBD)
- Account lockout after failed attempts (TBD)

---

## 11. Flow Diagrams

### Complete Signup Flow
```
┌─────────────────────────────────────────────────────────────┐
│                      SIGNUP FLOW                             │
└─────────────────────────────────────────────────────────────┘

    ┌─────────────────┐
    │  Signup Screen  │
    │  (Name, Email,  │
    │  Phone, Pass)   │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │  POST /signup   │
    │  Store in OTP   │
    │  table (temp)   │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │  Send OTP via   │
    │  Email + SMS    │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Verify Account  │
    │ Screen (6-digit)│
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ POST /verify-otp│
    │ Create User     │
    │ Return JWT      │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Create Passkey  │
    │ Screen (5-digit)│
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Confirm Passkey │
    │     Screen      │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ POST /passkey   │
    │ hasPasskey=true │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Pick Membership │
    │     Screen      │
    └────────┬────────┘
             │
     ┌───────┴───────┐
     │               │
     ▼               ▼
Individual      Community
     │               │
     ▼               ▼
Auto-join       Register
FinSquare       Community
Community       Flow
     │               │
     └───────┬───────┘
             │
             ▼
    ┌─────────────────┐
    │      HOME       │
    └─────────────────┘
```

### Returning User Flow
```
┌─────────────────────────────────────────────────────────────┐
│                   RETURNING USER FLOW                        │
└─────────────────────────────────────────────────────────────┘

    ┌─────────────────┐
    │   App Launch    │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Has stored      │
    │ token/userId?   │
    └────────┬────────┘
             │
     ┌───────┴───────┐
     │               │
     ▼               ▼
    YES              NO
     │               │
     ▼               ▼
hasPasskey?     Login Screen
     │          (Email + Pass)
     │               │
     ▼               ▼
    YES         POST /login
     │               │
     ▼               │
"Welcome Back"  ◄────┘
(Enter Passkey)
     │
     ▼
POST /login-passkey
     │
     ▼
hasPickedMembership?
     │
 ┌───┴───┐
 │       │
 ▼       ▼
NO      YES
 │       │
 ▼       ▼
Pick    HOME
Membership
```

---

*Document Status: Complete. Ready for implementation.*
