#!/usr/bin/ruby

# RightScript: Tune PostgreSQL Server
#
# Description: Tunes/optimizes PostgreSQL Server
#
# Author: Chris Fordham <chris.fordham@rightscale.com>

# Inputs:
#PG_INSTALL_PGTUNE
#PG_DRY_TUNE_RUN

# Copyright (c) 2007-2008 by RightScale Inc., all rights reserved worldwide

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# == Resources ==
# 18.3.1. Connection Settings
# http://www.postgresql.org/docs/9.0/static/runtime-config-connection.html

# 17.4.1. Shared Memory and Semaphores
#http://www.postgresql.org/docs/9.0/static/kernel-resources.html#SYSVIPC

# == Viewing the current settings ==
#Look in postgresql.conf. This works if you follow good practice, but it's not definitive! 
#show all, show <setting> will show you the current value of the setting. Watch out for session specific changes 
#select * from pg_settings will label session specific changes as locally modified

# Note: This script makes no changes to pgsql's logging configuration.

PGDATA = `echo -n /etc/postgresql/*/main`
#pgdata=( /etc/postgresql/*/main )    # sh

# install pgtune
puts 'Installing pgtune'
system 'mkdir -p /usr/local; cd /tmp; wget -q http://pgfoundry.org/frs/download.php/2449/pgtune-0.9.3.tar.gz;tar zxvf ./pgtune-0.9.3.tar.gz; mv ./pgtune-0.9.3 /usr/local/; pwd'

# run pgtune
puts 'Running pgtune.'
system "cd /usr/local/pgtune-0.9.3; ./pgtune -i #{PGDATA}/postgresql.conf -o #{PGDATA}/postgresql.conf.pgtune"

# show diff
puts "diff: "
system "diff #{PGDATA}/postgresql.conf #{PGDATA}/postgresql.conf.pgtune"

#
# Shared/common functions
#
set() {
  echo 'w00'
}

#
# PostgreSQL Tuning/Optimizations
# postgresql.conf
# located in $PGDATA/postgresql.conf,
#

# max_connections
# http://www.postgresql.org/docs/9.0/static/runtime-config-connection.html#GUC-MAX-CONNECTIONS (SEMMNS >= max_connections; SEMMNI=ceil((max_connections + autovacuum_max_workers + 4) / 16))
#max_connections sets exactly that: the maximum number of client connections allowed. This is very important to some of the below parameters (particularly work_mem) because there are some memory #resources that are or can be allocated on a per-client basis, so the maximum number of clients suggests the maximum possible memory use. Generally, PostgreSQL on good hardware can support a few #hundred connections. If you want to have thousands instead, you should consider using connection pooling software to reduce the connection overhead. 

# shared_buffers
#The shared_buffers configuration parameter determines how much memory is dedicated to PostgreSQL use for caching data. One reason the defaults are low because on some platforms (like older Solaris versions and SGI) having large values #requires invasive action like recompiling the kernel. Even on a modern Linux system, the stock kernel will likely not allow setting shared_buffers to over 32MB without adjusting kernel settings first. 

If you have a system with 1GB or more of RAM, a reasonable starting value for shared_buffers is 1/4 of the memory in your system. If you have less ram you'll have to account more carefully for how much RAM the OS is taking up, closer to 15% is more typical there. There are some workloads where even larger settings for shared_buffers are effective, but given the way PostgreSQL also relies on the operating system cache it's unlikely you'll find using more than 40% of RAM to work better than a smaller amount. 

Note that on Windows (and on PostgreSQL versions before 8.1), large values for shared_buffers aren't as effective, and you may find better results keeping it relatively low and using the OS cache more instead. On Windows the useful range is 64MB to 512MB, and for earlier than 8.1 versions the effective upper limit is near shared_buffers=50000 (just under 400MB--older versions before 8.2 don't allow using MB values for their settings, you specify this parameter in 8K blocks). 

It's likely you will have to increase the amount of memory your operating system allows you to allocate at once to set the value for shared_buffers this high. On UNIX-like systems, if you set it above what's supported, you'll get a message like this: 
IpcMemoryCreate: shmget(key=5432001, size=415776768, 03600) failed: Invalid argument 

This error usually means that PostgreSQL's request for a shared memory 
segment exceeded your kernel's SHMMAX parameter. You can either 
reduce the request size or reconfigure the kernel with larger SHMMAX. 
To reduce the request size (currently 415776768 bytes), reduce 
PostgreSQL's shared_buffers parameter (currently 50000) and/or 
its max_connections parameter (currently 12).

See Managing Kernel Resources for details on how to correct this. 

Changing this setting requires restarting the database. Also, this is a hard allocation of memory; the whole thing gets allocated out of virtual memory when the database starts. 
effective_cache_size

effective_cache_size should be set to an estimate of how much memory is available for disk caching by the operating system and within the database itself, after taking into account what's used by the OS itself and other applications. This is a guideline for how memory you expect to be available in the OS and PostgreSQL buffer caches, not an allocation! This value is used only by the PostgreSQL query planner to figure out whether plans it's considering would be expected to fit in RAM or not. If it's set too low, indexes may not be used for executing queries the way you'd expect. The setting for shared_buffers is not taken into account here--only the effective cache_size_value is, so it should include memory dedicated to the database too. 

Setting effective_cache_size to 1/2 of total memory would be a normal conservative setting, and 3/4 of memory is a more aggressive but still reasonable amount. You might find a better estimate by looking at your operating system's statistics. On UNIX-like systems, add the free+cached numbers from free or top to get an estimate. On Windows see the "System Cache" size in the Windows Task Manager's Performance tab. Changing this setting does not require restarting the database (HUP is enough). 
checkpoint_segments checkpoint_completion_target

PostgreSQL writes new transactions to the database in file called WAL segments that are 16MB in size. Every time checkpoint_segments worth of them have been written, by default 3, a checkpoint occurs. Checkpoints can be resource intensive, and on a modern system doing one every 48MB will be a serious performance bottleneck. Setting checkpoint_segments to a much larger value improves that. Unless you're running on a very small configuration, you'll almost certainly be better setting this to at least 10, which also allows usefully increasing the completion target. 

For more write-heavy systems, values from 32 (checkpoint every 512MB) to 256 (every 4GB) are popular nowadays. Very large settings use a lot more disk and will cause your database to take longer to recover, so make sure you're comfortable with both those things before large increases. Normally the large settings (>64/1GB) are only used for bulk loading. Note that whatever you choose for the segments, you'll still get a checkpoint at least every 5 minutes unless you also increase checkpoint_timeout (which isn't necessary on most system). 
PostgreSQL 8.3 and newer 

Starting with PostgreSQL 8.3, the checkpoint writes are spread out a bit while the system starts working toward the next checkpoint. You can spread those writes out further, lowering the average write overhead, by increasing the checkpoint_completion_target parameter to its useful maximum of 0.9 (aim to finish by the time 90% of the next checkpoint is here) rather than the default of 0.5 (aim to finish when the next one is 50% done). A setting of 0 gives something similar to the behavior of the earlier versions. The main reason the default isn't just 0.9 is that you need a larger checkpoint_segments value than the default for broader spreading to work well. For lots more information on checkpoint tuning, see Checkpoints and the Background Writer (where you'll also learn why tuning the background writer parameters, particularly those in 8.2 and below, is challenging to do usefully). 
autovacuum max_fsm_pages, max_fsm_relations

The autovacuum process takes care of several maintenance chores inside your database that you really need. Generally, if you think you need to turn regular vacuuming off because it's taking too much time or resources, that means you're doing it wrong. The answer to almost all vacuuming problems is to vacuum more often, not less, so that each individual vacuum operation has less to clean up. 

However, it's acceptable to disable autovacuum for short periods of time, for instance when bulk loading large amounts of data. 
PostgreSQL 8.4 

The FSM was rewritten for PostgreSQL 8.4, so earlier advice is no longer applicable. The max_fsm_pages and max_fsm_relations settings are gone, as the new FSM is self-adapting (more info). autovacuum is enabled by default and should remain so, as vacuum much less invasive in 8.4 than before thanks to visibility maps. 
PostgreSQL 8.3 and earlier 

As of 8.3, autovacuum is turned on by default, and you should keep it that way. In 8.1 and 8.2 you will have to turn it on yourself. Note that in those earlier versions, you may need to tweak its settings a bit to make it aggressive enough; it may not do enough work by default if you have a larger database or do lots of updates. 

You may also need to increase the value of max_fsm_pages and max_fsm_relations as needed. The Free Space Map is used to track where there are dead tuples (rows) that may be reclaimed. You will only get effective nonblocking VACUUM queries if the dead tuples can be listed in the Free Space Map. As a result, if you do not plan to run VACUUM frequently, and if you expect a lot of updates, you should ensure these values are usefully large (and remember, these values are cluster wide, not database wide). It should be easy enough to set max_fsm_relations high enough; the problem that will more typically occur is when max_fsm_pages is not set high enough. Once the Free Space Map is full, VACUUM will be unable to track further dead pages. In a busy database, this needs to be set much higher than 1000... also, remember that changing these settings requires a restart of the database, so it is wise to to err on the side of setting comfortable margins for these settings. 

If you run VACUUM VERBOSE on your database, it'll tell you how many pages and relations are in use (and, under 8.3, what the current limits are). For example, 
INFO:  free space map contains 5293 pages in 214 relations
DETAIL:  A total of 8528 page slots are in use (including overhead).
8528 page slots are required to track all free space.
Current limits are:  204800 page slots, 1000 relations, using 1265 kB.

If you find that your settings are already too low, you will likely need to do aggressive vacuuming of your system, and possibly reindexing and vacuum full maybe needed as well. If you're getting close to the limits for page slots, typical practice is to just double the current values, with perhaps a smaller percentage increase once you've gotten much higher (in the millions range). For the max relations settings, note that this setting includes all the databases in your cluster. 

One other situation to be aware of is that of a database approaching autovacuum_freeze_max_age. When a database approaches this point, it will begin to vacuum every table in the database that has not been vacuumed before. On some systems this may not result in much activity, but for systems where there are a lot of tables that are not modified often, this can be a more common occurrence (especially if the system has gone through a dump/restore, say for upgrading). The significance of all of this is that, even on a system with well set fsm settings, once your system begins vacuuming all of the additional tables, your old fsm setting may no longer be appropriate. 



default_statistics_target

The database software collects statistics about each of the tables in your database to decide how to execute queries against it. In earlier versions of PostgreSQL, the default setting of 10 doesn't collect very much information, and if you're not getting good execution query plans particularly on larger (or more varied) tables you should increase default_statistics_target then ANALYZE the database again (or wait for autovacuum to do it for you). 
PostgreSQL 8.4 and later 

The starting default_statistics_target value was raised from 10 to 100 in PostgreSQL 8.4. Increases beyond 100 may still be useful, but this increase makes for greatly improved statistics estimation in the default configuration. The maximum value for the parameter was also increased from 1000 to 10,000 in 8.4. 
work_mem maintainance_work_mem

If you do a lot of complex sorts, and have a lot of memory, then increasing the work_mem parameter allows PostgreSQL to do larger in-memory sorts which, unsurprisingly, will be faster than disk-based equivalents. 

This size is applied to each and every sort done by each user, and complex queries can use multiple working memory sort buffers. Set it to 50MB, and have 30 users submitting queries, and you are soon using 1.5GB of real memory. Furthermore, if a query involves doing merge sorts of 8 tables, that requires 8 times work_mem. You need to consider what you set max_connections to in order to size this parameter correctly. This is a setting where data warehouse systems, where users are submitting very large queries, can readily make use of many gigabytes of memory. 

maintenance_work_mem is used for operations like vacuum. Using extremely large values here doesn't help very much, and because you essentially need to reserve that memory for when vacuum kicks in, which takes it away from more useful purposes. Something in the 256MB range has anecdotally been a reasonable large setting here. 
PostgreSQL 8.3 and later 

In 8.3 you can use log_temp_files to figure out if sorts are using disk instead of fitting in memory. In earlier versions you might instead just monitoring the size of them by looking at how much space is being used in the various $PGDATA/base/<db oid>/pgsql_tmp files. You can see sorts to disk happen in EXPLAIN ANALYZE plans as well. For example, if you see a line like "Sort Method: external merge Disk: 7526kB" in there, you'd know a work_mem of at least 8MB would really improve how fast that query executed, by sorting in RAM instead of swapping to disk. 
wal_sync_method wal_buffers

After every transaction, PostgreSQL forces a commit to disk out to its write-ahead log. This can be done a couple of ways, and on some platforms the other options are considerably faster than the conservative default. open_sync is the most common non-default setting switched to, on platforms that support it but default to one of the fsync methods. See Tuning PostgreSQL WAL Synchronization for a lot of background on this topic. Note that open_sync writing is buggy on some platforms (such as Linux), and you should (as always) doing plenty of tests under a heavy write load to make sure that you haven't made your system less stable with this change. Reliable Writes contains more information on this topic. 

Linux kernels starting with version 2.6.33 will cause earlier versions of PostgreSQL to default to wal_sync_method=open_datasync; before that kernel release the default picked was always fdatasync. This can cause a significant performance decrease when combined with small writes and/or small values for wal_buffers. 

Increasing wal_buffers from its tiny default of a small number of kilobytes is helpful for write-heavy systems. Benchmarking generally suggests that just increasing to 1MB is enough for some large systems, and given the amount of RAM in modern servers allocating a full WAL segment (16MB, the useful upper-limit here) is reasonable. Changing wal_buffers requires a database restart. 
PostgreSQL 9.1 and later 

Starting with PostgreSQL 9.1 wal_buffers defaults to being 1/32 of the size of shared_buffers, with an upper limit of 16MB (reached when shared_buffers=512MB). 

PostgreSQL 9.1 also changes the logic for selecting the default wal_sync_method such that on newer Linux kernels, it will still select fdatasync as its method--the same as on older Linux versions. 

# constraint_exclusion
# http://www.postgresql.org/docs/current/static/runtime-config-query.html#GUC-CONSTRAINT-EXCLUSION
#* PostgreSQL 8.4 and later 
#In 8.4, constraint_exclusion now defaults to a new choice: partition. This will only enable constraint exclusion for partitioned tables which is the right thing to do in nearly all cases. 
#* PostgreSQL 8.3 and earlier 
#If you plan to use table partitioning, you need to turn on constraint exclusion. Since it does add overhead to query planning, it is recommended you leave this off outside of this scenario. 

# max_prepared_transactions
# http://www.postgresql.org/docs/current/static/runtime-config-resource.html#GUC-MAX-PREPARED-TRANSACTIONS
#This setting is used for managing 2 phase commit. If you do not use two phase commit (and if you don't know what it is, you don't use it), then you can set this value to 0. That will save a little bit of shared memory. For database systems #with a large number (at least hundreds) of concurrent connections, be aware that this setting also affects the number of available lock-slots in pg_locks, so you may want to leave it at the default setting. There is a formula for how much #memory gets allocated in the docs and in the default postgresql.conf. 
#
#Changing max_prepared_transactions requires a server restart. 




# synchronous_commit
# http://www.postgresql.org/docs/current/static/runtime-config-wal.html#GUC-SYNCHRONOUS-COMMIT
#PostgreSQL can only safely use a write cache if it has a battery backup. See WAL reliability for an essential introduction to this topic. No, really; go read that right now, its vital to understand that if you want your database to work #right.
#
#You may be limited to approximately 100 transaction commits per second per client in situations where you dont have such a durable write cache (and perhaps only 500/second even with lots of clients). 
#* PostgreSQL 8.3 and later 
#Asynchronous commit was introduced in PostgreSQL 8.3. For situations where a small amount of data loss is acceptable in return for a large boost in how many updates you can do to the database per second, consider switching synchronous commit #off. This is particularly useful in the situation where you do not have a battery-backed write cache on your disk controller, because you could potentially get thousands of commits per second instead of just a few hundred. 
#
#For earlier versions of PostgreSQL, you may find people recommending that you set fsync=off to speed up writes on busy systems. This is dangerous--a power loss could result in your database corrupted and not able to start again. Synchronous #commit doesn't introduce the risk of corruption, which is really bad, just some risk of data loss. 


# random_page_cost
# http://www.postgresql.org/docs/current/static/runtime-config-query.html#GUC-RANDOM-PAGE-COST
# default: 4
#This setting suggests to the optimizer how long it will take your disks to seek to a random disk page, as a multiple of how long a sequential read (with a cost of 1.0) takes. If you have particularly fast disks, as commonly found with RAID #arrays of SCSI disks, it may be appropriate to lower random_page_cost, which will encourage the query optimizer to use random access index scans. Some feel that 4.0 is always too large on current hardware, it's not unusual for administrators #to standardize on always setting this between 2.0 and 3.0 instead. In some cases that behavior is a holdover from earlier PostgreSQL versions where having random_page_cost too high was more likely to screw up plan optimization than it is now #(and setting at or below 2.0 was regularlly necessary). Since these cost estimates are just that--estimates--it shouldn't hurt to try lower values. 
#
#But this not where you should start to search for plan problems. Note that random_page_cost is pretty far down this list (at the end in fact). If you are getting bad plans, this shouldn't be the first thing you look at, even though lowering #this value may be effective. Instead, you should start by making sure autovacuum is working properly, that you are collecting enough statistics, and that you have correctly sized the memory parameters for your server--all the things gone over #above. After you've done all those much more important things, if you're still getting bad plans then you should see if lowering random_page_cost is still useful.