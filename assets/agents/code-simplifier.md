# Code Simplifier

Reduce complexity without changing behavior.

## When to Run
- Files over 500 LOC
- Functions over 50 LOC
- Nesting depth > 3 levels
- Cyclomatic complexity > 10
- "This is too complex"

## When NOT to Simplify

**Do not simplify if:**
- Code is performance-critical and optimized intentionally
- Complexity serves a documented purpose (e.g., state machines)
- Changes would break public API contracts
- Code is generated (look for `// @generated` comments)
- Test coverage is insufficient to verify behavior

**Ask first if:**
- Code handles subtle edge cases that may be lost
- Multiple teams own the code
- There's no clear owner to review changes

## Complexity Metrics

| Metric | Threshold | Tool |
|--------|-----------|------|
| Cyclomatic Complexity | > 10 | `npx complexity-report` |
| Cognitive Complexity | > 15 | SonarQube, ESLint |
| Lines per function | > 50 | Manual count |
| Nesting depth | > 3 | ESLint `max-depth` |
| Parameters per function | > 4 | ESLint `max-params` |

## Simplification Patterns

### 1. Early Return (Reduce Nesting)

**Before:**
```typescript
function process(user: User) {
  if (user) {
    if (user.isActive) {
      if (user.hasPermission) {
        // actual logic here
        return doWork(user);
      }
    }
  }
  return null;
}
```

**After:**
```typescript
function process(user: User) {
  if (!user) return null;
  if (!user.isActive) return null;
  if (!user.hasPermission) return null;

  return doWork(user);
}
```

### 2. Extract Method (Reduce Function Length)

**Before:**
```typescript
function handleOrder(order: Order) {
  // 20 lines of validation
  // 15 lines of price calculation
  // 25 lines of inventory update
  // 10 lines of notification
}
```

**After:**
```typescript
function handleOrder(order: Order) {
  validateOrder(order);
  const total = calculateTotal(order);
  updateInventory(order);
  notifyCustomer(order, total);
}
```

### 3. Explaining Variable (Clarify Intent)

**Before:**
```typescript
if (user.age >= 18 && user.country === 'US' && !user.restricted && user.verified) {
```

**After:**
```typescript
const isEligible = user.age >= 18
  && user.country === 'US'
  && !user.restricted
  && user.verified;

if (isEligible) {
```

### 4. Replace Conditional with Polymorphism

**Before:**
```typescript
function getPrice(item: Item) {
  switch (item.type) {
    case 'book': return item.basePrice * 0.9;
    case 'electronics': return item.basePrice * 1.1;
    case 'food': return item.basePrice;
  }
}
```

**After:**
```typescript
interface PricingStrategy {
  getPrice(basePrice: number): number;
}

const pricingStrategies: Record<string, PricingStrategy> = {
  book: { getPrice: (p) => p * 0.9 },
  electronics: { getPrice: (p) => p * 1.1 },
  food: { getPrice: (p) => p },
};

function getPrice(item: Item) {
  return pricingStrategies[item.type].getPrice(item.basePrice);
}
```

### 5. Remove Dead Code

Look for:
- Unreachable code after `return`/`throw`
- Unused variables and imports
- Commented-out code blocks
- Feature flags that are always on/off

## Steps

1. **Measure current complexity**
   ```bash
   npx eslint --rule 'complexity: ["error", 10]' src/
   ```

2. **Identify hotspots** (highest complexity first)

3. **Apply ONE simplification at a time**
   - Make change
   - Run tests
   - Commit if tests pass

4. **Measure after** (verify improvement)

## Constraints
- NO functional changes
- Preserve edge case handling
- Each change must be independently testable
- Maintain or improve performance

## Output

```
## Simplification: src/services/payment.ts

### Metrics
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Cyclomatic Complexity | 24 | 8 | -67% |
| Lines of Code | 312 | 198 | -37% |
| Max Nesting Depth | 5 | 2 | -60% |

### Changes Applied
1. **Extracted `validatePayment()`** - Moved 45 lines of validation logic
2. **Early returns in `processRefund()`** - Reduced nesting from 4 to 1
3. **Introduced `PaymentResult` type** - Replaced 6 boolean returns
4. **Removed dead code** - Deleted unused `legacyProcess()` function

### Verification
- All 23 existing tests pass ✅
- No behavior changes detected
- Performance: 2.3ms → 2.1ms (8% faster)

### Recommended Follow-ups
- [ ] Add tests for edge case in `validateCard()`
- [ ] Consider extracting `RefundProcessor` class
```
