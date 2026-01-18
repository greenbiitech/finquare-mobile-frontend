# FinSquare Wallet Architecture

## Problem Statement

The previous codebase had critical wallet issues:
- Balance not syncing across screens (Home vs Wallet)
- Required app restart to see updated balance
- No accountability/audit trail
- Balance discrepancies between local and 9PSB

## How Top Fintechs Solve This

### 1. OPay / PalmPay / Kuda Approach
- **Single Source of Truth**: Balance lives in ONE place in the app state
- **Real-time sync**: WebSocket or polling for balance updates
- **Pull-to-refresh**: User can manually trigger fresh balance fetch
- **Optimistic UI**: Show immediate feedback, reconcile with server

### 2. Paystack / Flutterwave Approach
- **Server is always authoritative**: Never trust local balance for transactions
- **Transaction-based balance**: Balance = sum of all transactions
- **Webhook-driven updates**: Server pushes updates, client refreshes

---

## Our Architecture Principles

### Principle 1: Single Source of Truth
```
┌─────────────────────────────────────────────────────────┐
│                    WalletProvider                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │  balance: "1,234.56"                             │   │
│  │  accountNumber: "1100913823"                     │   │
│  │  accountName: "JOHN DOE"                         │   │
│  │  lastUpdated: DateTime                           │   │
│  │  isLoading: bool                                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
     Home Page      Wallet Page     Any Screen
     (reads)         (reads)         (reads)
```

**Rule**: All screens READ from WalletProvider. NO screen stores its own balance.

### Principle 2: Balance Updates Flow
```
                    ┌──────────────┐
                    │   9PSB API   │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   Backend    │
                    │  /wallet/    │
                    │   balance    │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ WalletProvider│
                    │  (updates)   │
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
     Home Page        Wallet Page      Other Screens
   (auto-updates)   (auto-updates)   (auto-updates)
```

### Principle 3: When to Fetch Balance

| Event | Action |
|-------|--------|
| App launch | Fetch fresh balance |
| Login success | Fetch fresh balance |
| Navigate to Wallet tab | Fetch fresh balance |
| Pull-to-refresh | Fetch fresh balance |
| After any transaction | Fetch fresh balance |
| Push notification (wallet credit) | Fetch fresh balance |
| Every 60 seconds (background) | Fetch fresh balance (optional) |

### Principle 4: Transaction Accountability
```
Every wallet movement MUST have:
├── Transaction ID (unique)
├── Reference (from 9PSB)
├── Amount
├── Type (CREDIT/DEBIT)
├── Timestamp
├── Before Balance
├── After Balance
└── Source (webhook/transfer/etc)
```

---

## Implementation Plan

### Phase 1: Centralized Wallet State (Priority: HIGH)

**Goal**: Single WalletProvider that all screens use

1. Create `WalletState` class:
   ```dart
   class WalletState {
     final String balance;
     final String accountNumber;
     final String accountName;
     final String walletId;
     final bool isLoading;
     final String? error;
     final DateTime? lastUpdated;
   }
   ```

2. Create `WalletNotifier` (Riverpod):
   ```dart
   class WalletNotifier extends StateNotifier<WalletState> {
     Future<void> fetchBalance();
     Future<void> refreshBalance();
     void clearWallet(); // on logout
   }
   ```

3. Update ALL screens to use this provider:
   - Home page: `ref.watch(walletProvider).balance`
   - Wallet page: `ref.watch(walletProvider).balance`
   - Any future screen: same provider

### Phase 2: Auto-Refresh Triggers

1. **On login**:
   ```dart
   // After successful login
   ref.read(walletProvider.notifier).fetchBalance();
   ```

2. **On wallet tab focus**:
   ```dart
   // In wallet page initState or onResume
   ref.read(walletProvider.notifier).refreshBalance();
   ```

3. **On push notification**:
   ```dart
   // When receiving WALLET_CREDIT notification
   ref.read(walletProvider.notifier).refreshBalance();
   ```

4. **Pull-to-refresh**:
   ```dart
   RefreshIndicator(
     onRefresh: () => ref.read(walletProvider.notifier).refreshBalance(),
     child: ...
   )
   ```

### Phase 3: Optimistic UI (Future)

For transactions initiated BY the user:
1. Show immediate balance change (optimistic)
2. Call API
3. On success: fetch real balance to reconcile
4. On failure: revert optimistic change, show error

### Phase 4: Real-time Updates (Future)

Options:
- **WebSocket**: Server pushes balance updates
- **Firebase FCM data messages**: Trigger refresh on notification
- **Polling**: Fetch every 60s when app is active

---

## File Structure

```
lib/
├── features/
│   └── wallet/
│       ├── data/
│       │   └── wallet_repository.dart    # API calls
│       ├── domain/
│       │   └── wallet_state.dart         # State class
│       └── presentation/
│           ├── providers/
│           │   └── wallet_provider.dart  # Centralized state
│           ├── pages/
│           │   ├── wallet_page.dart
│           │   └── top_up_page.dart
│           └── widgets/
│               └── balance_display.dart  # Reusable widget
```

---

## Anti-Patterns to Avoid

### ❌ DON'T: Store balance in multiple places
```dart
// BAD - balance in auth state
final balance = authState.user?.mainWallet?.balance;

// BAD - balance in local variable
String _balance = "0.00";
```

### ✅ DO: Single source of truth
```dart
// GOOD - always from wallet provider
final walletState = ref.watch(walletProvider);
final balance = walletState.balance;
```

### ❌ DON'T: Fetch balance only on page load
```dart
// BAD - only fetches once
@override
void initState() {
  _fetchBalance();
}
```

### ✅ DO: Fetch on multiple triggers
```dart
// GOOD - multiple refresh triggers
// 1. initState
// 2. onResume (coming back to app)
// 3. pull-to-refresh
// 4. after transaction
// 5. on push notification
```

---

## Success Criteria

- [ ] Balance shows same value on ALL screens
- [ ] Balance updates within 2 seconds of change
- [ ] No app restart needed to see new balance
- [ ] Pull-to-refresh works on wallet screen
- [ ] Push notification triggers balance refresh
- [ ] Transaction history matches balance changes
- [ ] 9PSB balance = Local balance (always synced)

---

## Critical Design Decision: 9PSB is the Source of Truth

### The Problem We Had
```
User sees: ₦1,000 (from local DB)
9PSB has: ₦1,100 (actual balance)
Result: User is confused, balance doesn't match transactions
```

### The Rule
```
┌─────────────────────────────────────────────────────────┐
│  9PSB is ALWAYS the authoritative source of truth       │
│  Our database is just a CACHE for quick display         │
└─────────────────────────────────────────────────────────┘
```

### Balance Fetch Flow
```
1. User opens app
   │
2. Show CACHED balance from local DB (instant)
   │
3. Fetch REAL balance from 9PSB (background)
   │
4. If different → Update local DB → Update UI
   │
5. Log any discrepancy for audit
```

### Backend Implementation (Already Done)
```typescript
// In wallet.service.ts - getWalletBalance()
// 1. Fetch from 9PSB
const psbResponse = await this.psbWaasService.getWalletDetails(accountNumber);
const psbBalance = psbResponse.data?.availableBalance;

// 2. Sync local DB with 9PSB
if (wallet.balance !== psbBalance) {
  await this.prisma.wallet.update({ balance: psbBalance });
  // This ensures DB always matches 9PSB
}

// 3. Return 9PSB balance (the truth)
return { balance: psbBalance };
```

---

## Balance Display UX: Animation on First Load

### First Time User Experience
```
┌─────────────────────────────────────────────────────────┐
│  Step 1: Show ₦0.00 (placeholder)                       │
│  Step 2: Fetch balance from server                      │
│  Step 3: Animate from ₦0.00 → ₦1,234.56                │
└─────────────────────────────────────────────────────────┘
```

### Subsequent Views (Returning User)
```
┌─────────────────────────────────────────────────────────┐
│  Step 1: Show CACHED balance instantly (₦1,234.56)     │
│  Step 2: Fetch fresh balance SILENTLY (no loader)       │
│  Step 3: If changed, animate to new value               │
│          If same, no visual change                      │
└─────────────────────────────────────────────────────────┘
```

### Implementation Strategy
```dart
class WalletState {
  final String balance;           // Current display balance
  final String? cachedBalance;    // Last known balance (from storage)
  final bool isFirstLoad;         // True if no cached balance exists
  final bool isFetching;          // True while fetching (internal only)
  final DateTime? lastUpdated;
}
```

### Animation Rules
| Scenario | Behavior |
|----------|----------|
| First load, no cache | Show "0.00" → Fetch → Animate to real value |
| Has cache, same value | Show cached → Fetch silently → No change |
| Has cache, different value | Show cached → Fetch silently → Animate to new |
| Pull-to-refresh | Show current → Show subtle loader → Update |
| Error fetching | Keep showing cached, show toast error |

### Code Example
```dart
// In balance display widget
AnimatedBalanceText(
  value: walletState.balance,
  duration: walletState.isFirstLoad
    ? Duration(milliseconds: 800)  // Slow animation for first load
    : Duration(milliseconds: 300), // Quick for updates
)
```

---

## Local Storage Strategy

### What We Cache
```dart
// Stored in SharedPreferences or Hive
{
  "balance": "1234.56",
  "accountNumber": "1100913823",
  "accountName": "JOHN DOE",
  "walletId": "uuid",
  "lastUpdated": "2024-01-16T10:30:00Z"
}
```

### Cache Rules
1. **On successful fetch**: Save to local storage
2. **On app launch**: Load from local storage first
3. **On logout**: Clear local storage
4. **Stale after**: Consider cache stale after 5 minutes (fetch fresh)

---

## Next Steps

1. [ ] Create WalletProvider with centralized state
2. [ ] Add local storage caching (SharedPreferences)
3. [ ] Create AnimatedBalanceText widget
4. [ ] Update Home page to use WalletProvider
5. [ ] Update Wallet page to use WalletProvider
6. [ ] Add pull-to-refresh on wallet page
7. [ ] Add refresh trigger on push notification
8. [ ] Add refresh trigger on app resume
9. [ ] Test balance sync across all screens
10. [ ] Test animation on first load vs subsequent loads
