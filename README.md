Module Sync
===========

Usage
-----

```
$ ./sync.rb -m "Commit message" [ --noop ]
```

Modulesync will clone any repositories it plans to manage or override local changes if the repositories are already cloned. Default configuration comes from config\_defaults.yml. Modules to be managed should have a file .sync.yml in the module root to manage any options that are different from the defaults, such as gems specific to the module. A file can be marked as "unmanaged" in .sync.yml if necessary. Modules to manage are listed in managed\_modules.yml.

TODO: Push modules after committing.
