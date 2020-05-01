# Changelog

## 2020-05-01 - 1.1.0

This release provides metadata in the ERB template scope which makes it easy to read files from inside the module. A possible application is reading metadata.json and generating CI configs based on that.

* Add metadata to ERB template scope - [#168](https://github.com/voxpupuli/modulesync/pull/168)
* Skip issuing a PR if one already exists for -b option - [#171](https://github.com/voxpupuli/modulesync/pull/171)
* Correct the type on the pr-labels option to prevent a deprecation warning - [#173](https://github.com/voxpupuli/modulesync/pull/173)

## 2019-09-19 - 1.0.0

This is the first stable release! 🎉

* Use namespace in directory structure when cloning repositories - [#152](https://github.com/voxpupuli/modulesync/pull/152)
* Fix minor typo in help output - [#165](https://github.com/voxpupuli/modulesync/pull/165)
* Small improvements and fixes - [#166](https://github.com/voxpupuli/modulesync/pull/166)
* Fix overwriting of :global values - [#169](https://github.com/voxpupuli/modulesync/pull/169)

## 2018-12-27 - 0.10.0

This is another awesome release!

* Add support to submit PRs to GitHub when changes are pushed - [#147](https://github.com/voxpupuli/modulesync/pull/147)
* Fix "flat files" still mentioned in README - [#151](https://github.com/voxpupuli/modulesync/pull/151)

## 2018-02-15 - 0.9.0

## Summary

This is an awesome release - Now honors the repo default branch[#142](https://github.com/voxpupuli/modulesync/pull/142)

### Bugfixes

  * Monkey patch ls_files until ruby-git/ruby-git#320 is resolved
  * Reraise exception rather than exit so we can rescue a derived StandardError when using skip_broken option

### Enhancements

  * Add new option to produce a failure exit code on warnings
  * Remove hard coding of managed_modules.yml which means that options passed to ModuleSync.update can override the filename

## 2017-11-03 - 0.8.2

### Summary

This release fixes:
  * Bug that caused .gitignore file handle to be left open - [#131](https://github.com/voxpupuli/modulesync/pull/131).
  * Fixed switch_branch to use current_branch instead of master - [#130](https://github.com/voxpupuli/modulesync/pull/130).
  * Fixed bug where failed runs wouldn't return correct exit code - [#125](https://github.com/voxpupuli/modulesync/pull/125).
  * Fix typo in README link to Voxpupuli modulesync_config [#123](https://github.com/voxpupuli/modulesync/pull/123).

## 2017-05-08 - 0.8.1

### Summary

This release fixes a nasty bug with CLI vs configuration file option handling: Before [#117](https://github.com/voxpupuli/modulesync/pull/117) it was not possible to override options set in `modulesync.yml` on the command line, which could cause confusion in many cases. Now the configuration file is only used to populate the default values of the options specified in the README, and setting them on the command line will properly use those new values.

## 2017-05-05 - 0.8.0

### Summary

This release now prefers `.erb` suffixes on template files. To convert your moduleroot directory, run this command in your configs repo:

        find moduleroot/ -type f -exec git mv {} {}.erb \;

Note that any `.erb`-suffixed configuration keys in `config_defaults.yml`, and `.sync.yml` need to be removed by hand. (This was unreleased functionality, will not affect most users.)

#### Refactoring

- Prefer `.erb` suffixes on template files, issue deprecation warning for templates without the extension
- Require Ruby 2.0 or higher

#### Bugfixes

- Fix dependency on `git` gem for diff functionality
- Fix error from `git` gem when diff contained line ending changes

## 2017-02-13 - 0.7.2

Fixes an issue releasing 0.7.1, no functional changes.

## 2017-02-13 - 0.7.1

Fixes an issue releasing 0.7.0, no functional changes.

## 2017-02-13 - 0.7.0

### Summary

This is the first release from Vox Pupuli, which has taken over maintenance of
modulesync.

#### Features
- New `msync update` arguments:
    - `--git-base` to override `git_base`, e.g. for read-only git clones
    - `-s` to skip the current module and continue on error
    - `-x` for a negative filter (blacklist) of modules not to update
- Add `-a` argument to `msync hook` to pass additional arguments
- Add `:git_base` and `:namespace` data to `@configs` hash
- Allow `managed_modules.yml` to list modules with a different namespace
- Entire directories can be listed with `unmanaged: true`

#### Refactoring
- Replace CLI optionparser with thor

#### Bugfixes
- Fix git 1.8.0 compatibility, detecting when no files are changed
- Fix `delete: true` feature, now deletes files correctly
- Fix handling of `:global` config entries, not interpreted as a path
- Fix push without force to remote branch when no files have changed (#102)
- Output template name when ERB rendering fails
- Remove extraneous whitespace in `--noop` output

## 2015-08-13 - 0.6.1

### Summary

This is a bugfix release to fix an issue caused by the --project-root flag.

#### Bugfixes

- Fix bug in git pull function (#55)

##2015-08-11 - 0.6.0

### Summary

This release adds two new flags to help modulesync better integrate with CI tools.

#### Features

- Add --project-root flag
- Create --offline flag to disable git functionality

#### Bugfixes

- Fix :remote option for repo

#### Maintenance

- Added tests

## 2015-06-30 - 0.5.0

### Summary

This release adds the ability to sync a non-bare local git repo.

#### Features

- Allow one to sync non-bare local git repository

## 2015-06-24 - 0.4.0

### Summary

This release adds a --remote-branch flag and adds a global key for template
config.

#### Features

- Expose --remote-branch
- Add a global config key

#### Bugfixes

- Fix markdown syntax in README

## 2015-03-12 - 0.3.0

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

## 2014-11-16 - 0.2.0

### Summary

This release adds the --filter flag to filter what modules to sync.
Also fixes the README to document the very important -m flag.

## 2014-9-29 - 0.1.0

### Summary

This release adds support for other SSH-based git servers, which means
gitlab is now supported.
