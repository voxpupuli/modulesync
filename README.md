Module Sync
===========

Usage
-----

```
$ ./sync.rb -m "Commit message" [ --noop ]
```

You need to have all the repositories that you are going to managed already cloned and in the same directory as modulesync. Default configuration comes from config\_defaults.yml. Modules to be managed should have a file .sync.yml in the module root to manage any options that are different from the defaults, such as gems specific to the module. A file can be marked as "unmanaged" in .sync.yml if necessary. Modules to manage are listed in managed\_modules.yml.

TODO: Push modules after committing.
