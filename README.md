Module Sync
===========

Usage
-----

This script can be used in two ways. You can run it distinctly from committing and pushing with

```
$ ./sync.rb -m "Commit message" [ --noop ]
```

You can also automate this by activating the git hook:

```
$ ./hook activate
```

This creates a pre-push hook so that in the future, upon pushing to master, sync.rb will commit and push to all managed repositories with the commit message taken from the commit message at HEAD from this repository. This means that, for now, community contributions to this repository can be pushed out to all managed modules by command-line merging pull requests to master.

If you need to change something without pushing out to all the managed repositories, you can deactivate the hook with

```
$ ./hook deactivate
```

Modulesync will clone any repositories it plans to manage or override local changes if the repositories are already cloned. Default configuration comes from config\_defaults.yml. Modules to be managed should have a file .sync.yml in the module root to manage any options that are different from the defaults, such as gems specific to the module. A file can be marked as "unmanaged" in .sync.yml if necessary. A file can also be marked as "deleted" to ensure it is absent from the repository. Modules to manage are listed in managed\_modules.yml.

TODO: Push modules after committing.
