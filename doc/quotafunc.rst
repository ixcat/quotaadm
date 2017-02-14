
Quota Functional Details & Grace Period Interaction
---------------------------------------------------

Generally speaking, quota implementations using the 4.4BSD based
model for quota checking (including the Linux implementation,
which is a modified port of the same):

  - load values in an existing quota database upon enabling of quota
  - check user operations against this quota database as they occur,
    saving back changes to the quota database when necessary.

Quota databases are built and mained using a separate offline
quotacheck(8) tool, and initially populate user limits and grace
timeout values to zero. Subsequent maintenance scans update the
current usage values but do not alter other values, such as usage
limits and computed grace timeout times.

Since the quota system allows for both grace period soft quota
limits and hard limits, two main policies can be configured:

  - Soft Quota Only
  - Soft Quota and Hard Quota
  - Hard Quota Only

Unfortunately, in most implementations, setting filesystem grace
timeout to '0' results in either using a system default grace time,
which is typically 1 week (Traditional 4.4BSD-based, including early
Linux), or a near immediate grace period timeout (current Linux).
Therefore, this implies there is no clear option to simply disable
grace time enforcement permanently to facillitate a filesystem-wide
nonenforcing or notification-only policy for soft quotas.

However, some workarounds exist:

  - Setting an arbitrarily high grace timeout such that the timeout
    will likely never be reached. 

    This carries the risk that the grace period is actually reached
    despite best efforts, resulting in undesired enforcment of the
    grace setting. However, it might still be useful in some cases,
    particularly in conjunction with the Linux-specific per-user
    grace timeout settings available in current Linux flavors, which
    allows for a 'selective strictness' in grace enforcement at the
    cost of additional administrative overhead in tracking per-user
    grace period timeout values.

  - Reapplying quota values faster than the grace timeout.

    This works because:

    - Setting quotas resets grace times in quota databses to zero.

    - The grace timeout time is computed and stored into the quota
      database only at the occurrence of the first operation above
      the quota threshold.

    - The grace timeout time is the sum of the time of the
      the threshold crossing and the length of the grace period.
      
    Therefore, any computed grace timeout times will always occur
    after the point at which the quota settings were last applied.

  - Disabling, rebuilding and reenabling quotas faster than the
    grace timeout.

    This works because:

    - Quotacheck runs can be kluedged to set grace times in 
      quota databses to zero.

    - The grace timeout time is computed and stored into the quota
      database only at the occurrence of the first operation above
      the quota threshold.

    - The grace timeout time is the sum of the time of the
      the threshold crossing and the length of the grace period.
      
    Therefore, any computed grace timeout times will always occur
    after the point at which the next new quota database is put
    into use.

    This implies that quotas be regularly rebuilt to prevent grace
    period enforcement, and allows some potential for race conditions
    in actual current usage values if filesystems are operated in
    read/write mode during the rebuild and user operations occur
    while the quotas are being rebuilt.  However, the actual process
    can be easily implemented via a one-shot weekly cron job so
    long that that the rebuild takes sufficiently long enough to
    exceed any scheduling jitter of the weekly job scheduling system.
    For example, with a filesystem grace of precicely one week, a
    10-minute quota rebuild time should be sufficiently long enough
    to prevent any grace period from triggering for operations
    occurring after the quota is reenabled.

    Setting up such a weekly job also ensures that, despite the
    user-data race condition flaw described above, that the databases
    are, generally speaking, up to date and accurate without
    additional administrator overhead.

