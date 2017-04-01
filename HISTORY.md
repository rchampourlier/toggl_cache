# History

## 2017-03-25 - 0.2.0

Synchronizing deleted records and old changes.

Approach #1: calculate aggregates over periods and perform a full sync over the period if there is a diff.

- Pros: more efficient, smarter, also provides a synchronization correctness control.
- Cons: harder to implement.

Approach #2: brute-force, i.e. simply clear the content for a given period and perform a full sync.

- Pros: simpler to implement.
- Cons: synchronization is currently to long.

Trying approach #2. Optimizing synchronization:

- [X] processing fetched records once a page has been fetched, not at the end.
- [ ] perform requests in parallel.

The approach #2 is not applicable. Reviewing Toggl API's documentation, the rate limit is about 1 request per second, so parallelizing does not seem to be an option.

NB: performing a full synchronization leading to about 40K reports takes about 0.65 hour.

The approach #1 has been implemented. The algorithm first checks each full year. If a difference is detected, it checks each month of the year. For each month with a difference, a sync is done by clearing the cache for the month and fetching the reports.

The implementation has been done in `TogglCache.sync_check_and_fix`.

## 2017-03-18 - 0.1.1

- Changed default period of import to one week from now, instead of one day.

## 2017-03-08 - 0.1.0

- Initial version
