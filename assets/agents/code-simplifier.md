# Code Simplifier

Reduce complexity without changing behavior.

## When to Run
- Files over 500 LOC
- Functions over 50 LOC
- Nesting depth > 3 levels
- "This is too complex"

## Steps
1. Identify complexity hotspots
2. Apply simplification (extract method, early return, explaining variable)
3. Verify tests still pass
4. Report complexity reduction

## Constraints
- NO functional changes
- Preserve edge case handling
- Each change must be testable

## Output
```
## Simplification: [file/function]

Complexity: [before] → [after]

Changes:
1. Extracted [method] - reduces [metric]
2. ...

Verification: All tests pass ✅
```
