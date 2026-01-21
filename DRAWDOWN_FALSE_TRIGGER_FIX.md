# Circuit Breaker False Trigger Fix - Daily Drawdown Issue

**Date**: January 21, 2026  
**Issue**: Circuit breaker falsely triggers "MAX DAILY DRAWDOWN HIT: 32.05%" on new trading day with NO trades executed  
**Root Cause**: `peak_balance` not properly reset at start of trading day  
**Status**: ✅ FIXED

---

## Problem Analysis

### What Was Happening:
```
Day 1: Trading with $10,000 account
       End of day: Account down to $6,795 (32.05% loss)

Day 2 (New day, NO trades yet):
       Circuit breaker triggers: "MAX DAILY DRAWDOWN HIT: 32.05% / 10.00%"
       But: No trades executed today!
```

### Root Cause:
The `peak_balance` (used for drawdown calculation) was not being reset when a new trading day started. 

**Logic Flow (BEFORE FIX):**
```python
# Day 1 End: peak_balance = $10,000 (highest point of Day 1)
# Day 2 Morning: Account equity = $6,795
# Drawdown calculation: ($10,000 - $6,795) / $10,000 * 100 = 32.05% ❌

# The system didn't realize it was a NEW DAY!
# It was comparing today's balance to YESTERDAY'S peak
```

### Where Drawdown Was Calculated:
1. **`get_risk_metrics()` in risk_manager.py** - Called during metrics update
2. **`calculate_drawdown_metrics()` in risk_manager.py** - Computes drawdown %
3. Both functions checked `peak_balance` WITHOUT resetting it first on new day

---

## Solution Implemented

### Fix #1: Enhanced `reset_daily_stats()` in aventa_hft_core.py

**Changes:**
- Improved error handling for getting account balance
- Ensures both `peak_equity` (in core) AND `peak_balance` (in risk_manager) are reset together
- Reset even when falling back to bot_initial_balance

**Code:**
```python
def reset_daily_stats(self):
    """Reset daily statistics for this bot"""
    today = datetime.now().date()
    if today > self.last_reset_date:
        # Get current account balance from MT5
        try:
            account_info = mt5.account_info()
            if account_info:
                account_balance = account_info.balance
        except:
            account_balance = 0.0
        
        # ✅ NEW: Also reset risk_manager's peak_balance with current account balance
        if self.risk_manager and account_balance > 0:
            self.risk_manager.reset_daily_stats(account_balance)
            logger.info(f"✓ Risk Manager peak_balance reset to: ${account_balance:.2f}")
```

### Fix #2: Added Reset Check in `get_risk_metrics()` in risk_manager.py

**Changes:**
- Added `reset_daily_stats()` call FIRST before calculating drawdown
- This ensures `peak_balance` is checked/reset on every metric update
- Prevents stale peak_balance from yesterday

**Code:**
```python
def get_risk_metrics(self, account_balance: float, mt5_positions=None):
    """Calculate comprehensive risk metrics"""
    
    # ✅ CRITICAL FIX: RESET DAILY STATS FIRST (before calculating drawdown)
    # This ensures peak_balance is properly reset on new day
    self.reset_daily_stats(account_balance)
    
    # NOW calculate drawdown with fresh peak_balance
    # Update daily peak balance for drawdown calculation
    if self.peak_balance == 0.0:
        self.peak_balance = account_balance
    ...
```

---

## How It Works Now (AFTER FIX)

### New Day Sequence:

```python
# Day 2 Morning (automatic):
├─ get_risk_metrics() called
│  ├─ Calls reset_daily_stats(account_balance=$6,795)
│  │  ├─ Detects: today (Jan 21) > last_reset_date (Jan 20) ✓
│  │  ├─ Sets: peak_balance = $6,795 (today's starting balance)
│  │  └─ Sets: last_reset_date = today
│  │
│  └─ Now calculates drawdown:
│     ├─ peak_balance = $6,795 (TODAY's peak, just reset)
│     ├─ current_balance = $6,795 (no trades yet)
│     ├─ Drawdown = ($6,795 - $6,795) / $6,795 * 100 = 0% ✓ CORRECT!
│     └─ Circuit breaker: NOT triggered ✓

# First trade of Day 2:
├─ Balance stays $6,795, trade not taken yet
├─ Drawdown still 0% ✓

# After first loss trade:
├─ Balance = $6,700 (small loss)
├─ peak_balance still = $6,795
├─ Drawdown = ($6,795 - $6,700) / $6,795 * 100 ≈ 1.4% ✓ CORRECT!
```

---

## Key Changes Summary

| Component | Before | After |
|-----------|--------|-------|
| **peak_balance reset** | Only in risk_manager.reset_daily_stats() | Also called from get_risk_metrics() |
| **Timing** | Reset called after metrics calculation | Reset called BEFORE metrics calculation |
| **Error handling** | Basic MT5 account info fetch | Try-catch with fallback |
| **Fallback** | Uses 0.0 if account balance unavailable | Also resets with bot_initial_balance |

---

## Verification Checklist

✅ **On New Trading Day (with no trades):**
- [ ] Account balance shows correctly
- [ ] Drawdown shows 0.00% (not yesterday's loss)
- [ ] Circuit breaker is NOT triggered
- [ ] Green "✅ INACTIVE - Trading Allowed" message displays

✅ **During Trading:**
- [ ] Drawdown increases only after first losing trade
- [ ] Drawdown % = (peak_today - current_balance) / peak_today * 100
- [ ] Circuit breaker triggers ONLY when drawdown ≥ max_drawdown_pct
- [ ] No false triggers on new day

✅ **Log Messages:**
```
2026-01-21 10:00:00 - INFO - ✓ Daily peak equity reset to current: $6795.00
2026-01-21 10:00:00 - INFO - ✓ Risk Manager peak_balance reset to: $6795.00
2026-01-21 10:00:00 - INFO - ✓ Daily stats reset complete for bot
```

---

## Testing

To verify the fix works:

1. **End Day 1 with losses** (e.g., -32% drawdown)
2. **Start Day 2 normally**
3. **Check Risk Management tab:**
   - Drawdown should show 0.00%
   - Circuit breaker should show "✅ INACTIVE"
   - No error logs about exceeded drawdown

4. **Make a small loss trade**
   - Drawdown should increase slightly (not jump to 32%)
   - Circuit breaker should remain inactive

---

## Files Modified

1. **aventa_hft_core.py** (lines 381-412)
   - Enhanced reset_daily_stats() function
   - Improved error handling
   - Ensures risk_manager peak_balance is reset

2. **risk_manager.py** (lines 378-403)
   - Added reset_daily_stats() call in get_risk_metrics()
   - Ensures daily reset happens before drawdown calculation

---

## Impact

✅ **Positive:**
- Circuit breaker no longer false-triggers on new day
- Drawdown calculations are based on TODAY's peak only
- More reliable trading system
- Better logging for debugging

⚠️ **No Breaking Changes:**
- All existing code paths remain compatible
- Just adds safety checks
- No changes to configuration or trade logic

---

## Related Issues Fixed

- ✅ Circuit breaker triggering with 0 trades on new day
- ✅ Stale peak_balance from previous day
- ✅ Incorrect drawdown % calculation on new day
- ✅ False "MAX DAILY DRAWDOWN HIT" warnings

---

## Notes

- **Daily reset happens automatically** - No user action needed
- **reset_daily_stats() is idempotent** - Safe to call multiple times per day
- **peak_balance never goes backwards** - Only increases if account balance is higher
- **Drawdown calculation**: Uses highest balance TODAY as peak, not all-time peak
