# History

## 2017-03-25 - 0.2.0

Synchronizing deleted records and old changes.

Approach #1: calculate aggregates over periods and perform a full sync over the period if there is a diff.

- Pros: more efficient, smarter.
- Cons: harder to implement.

Approach #2: brute-force, i.e. simply clear the content for a given period and perform a full sync.

- Pros: simpler to implement.
- Cons: synchronization is currently to long.

Trying approach #2. Optimizing synchronization:

- [X] processing fetched records once a page has been fetched, not at the end.
- [ ] perform requests in parallel.

## 2017-03-18 - 0.1.1

- Changed default period of import to one week from now, instead of one day.

## 2017-03-08 - 0.1.0

- Initial version
