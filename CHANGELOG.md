##2015-06-24 - 0.4.0

### Summary

This release adds a --remote-branch flag and adds a global key for template
config.

#### Features

- Expose --remote-branch
- Add a global config key

#### Bugfixes

- Fix markdown syntax in README

##2015-03-12 - 0.3.0

### Summary

This release contains a breaking change to some parameters exposed in
modulesync.yml. In particular, it abandons the user of git_user and
git_provider in favor of the parameter git_base to specify the base part of a
git URL to pull from. It also adds support for gerrit by adding a remote_branch
parameter for modulesync.yml that can differ from the local branch, plus a
number of new flags for updating modules.

#### Backwards-incompatible changes

- Remove git_user and git_provider_address as parameters in favor of using
  git_base as a whole

#### Features

- Expose the puppet module name in the ERB templates
- Add support for gerrit by:
  - Adding a --amend flag
  - Adding a remote_branch parameter for modulesync.yml config file that can
    differ from the local branch
  - Adding a script to handle the pre-commit hook for adding a commit id
  - Using git_base to specify an arbitrary git URL instead of an SCP-style one
- Add a --force flag (usually needed with the --amend flag if not using gerrit)
- Add --bump, --tag, --tag-pattern, and --changelog flags

#### Bugfixes

- Stop requiring .gitignore to exist
- Fix non-master branch functionality
- Add workarounds for older git versions

##2014-11-16 - 0.2.0

### Summary

This release adds the --filter flag to filter what modules to sync.
Also fixes the README to document the very important -m flag.

##2014-9-29 - 0.1.0

### Summary

This release adds support for other SSH-based git servers, which means
gitlab is now supported.
