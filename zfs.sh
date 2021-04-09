# Creates a "send" snapshot of all filesystems
zfs snapshot -r double-pool-8TB@send

# Sends all snapshots recursively. -R also preserves attributes (same as -p).
# Receives snapshot on another pool. -F forces rewriting the pool destroying all data. -d omits the pool name in receiving path. -u prevents FS from mounting.
zfs send -Rv double-pool-8TB@send | zfs recv -Fdvu double-pool-1TB

# Since sending was with preserved attributes, mountpoint was also sent. Change it, and it ill be inherited by all children.
zfs set mountpoint=/mnt/double-pool-1TB double-pool-1TB

# Mount it and check that everything is good.
zfs mount -a

# Destroy the temporary snapshots
zfs destroy -rv double-pool-1TB@send
zfs destroy -rv double-pool-8TB@send

## To check the results
-nv # to dry-run any operation
zfs list -t all # lists all filesystems, including snapshots
zfs get all double-pool-1TB # show all attributes of the filesystem
diff -qr /mnt/double-pool-8TB/ /mnt/double-pool-1TB/ > ./diff.tmp # compares all files in directories, to find if anything is missing (very slow)

