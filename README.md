ModuleSync
===========

[![License](https://img.shields.io/github/license/voxpupuli/modulesync.svg)](https://github.com/voxpupuli/modulesync/blob/master/LICENSE)
[![Test](https://github.com/voxpupuli/modulesync/actions/workflows/ci.yml/badge.svg)](https://github.com/voxpupuli/modulesync/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/voxpupuli/modulesync/branch/master/graph/badge.svg?token=Mypkl78hvK)](https://codecov.io/gh/voxpupuli/modulesync)
[![Release](https://github.com/voxpupuli/modulesync/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/modulesync/actions/workflows/release.yml)
[![RubyGem Version](https://img.shields.io/gem/v/modulesync.svg)](https://rubygems.org/gems/modulesync)
[![RubyGem Downloads](https://img.shields.io/gem/dt/modulesync.svg)](https://rubygems.org/gems/modulesync)
[![Donated by Puppet Inc](https://img.shields.io/badge/donated%20by-Puppet%20Inc-fb7047.svg)](#transfer-notice)

Table of Contents
-----------------

1. [Usage TLDR](#usage-tldr)
2. [Overview](#overview)
3. [How it works](#how-it-works)
4. [Installing](#installing)
5. [Workflow](#workflow)
6. [The Templates](#the-templates)

Usage TLDR
----------

```
gem install modulesync
msync --help
```

Overview
--------

ModuleSync was written as a simple script with ERB templates to help the
Puppet Labs module engineers manage the zoo of Puppet modules on GitHub, and
has now been restructured and generalized to be used within other
organizations. Puppet modules within an organization tend to have a number of
meta-files that are identical or very similar between modules, such as the
`Gemfile`, `.travis.yml`, `.gitignore`, or `spec_helper.rb`. If a file needs to
change in one module, it likely needs to change in the same way in every other
module that the organization manages.

One approach to this problem is to use sed in a bash for loop on the modules to
make a single change across every module. This approach falls short if there is
a single file that is purposefully different than the others, but still needs
to be managed. Moreover, this approach does not help if two files are
structured differently but need to be changed with the same meaning; for
instance, if the .travis.yml of one module uses a list of environments to
include, and another uses a matrix of includes with a list of excludes, adding
a test environment to both modules will require entirely different approaches.

ModuleSync provides the advantage of defining a standard template for each
file to follow, so it becomes clear what a file is supposed to look like. Two
files with the same semantics should also have the same syntax. A difference
between two files should have clear reasons, and old cruft should not be left
in files of one module as the files of another module march forward.

Another advantage of ModuleSync is the ability to run in no-op mode, which
makes local changes and shows the diffs, but does not make permanent changes in
the remote repository.

How It Works
------------

ModuleSync is a gem that uses the GitHub workflow to clone, update, and push module
repositories. It expects to be activated from a directory containing
configuration for modulesync and the modules, or you can pass it the location
of this configuration directory. [The configuration for the Puppet Labs
modules](https://github.com/puppetlabs/modulesync_configs), can be used as an
example for your own configuration. The configuration directory contains a
directory called moduleroot which mirrors the structure of a module. The files
in the moduleroot are ERB templates, and MUST be named after the target file,
with `.erb.` appended. The templates are
rendered using values from a file called `config_defaults.yml` in the root (not
moduleroot) of the configuration directory. The default values can be
overridden or extended by adding a file called `.sync.yml` to the module itself.
This allows us to, for example, have a set of "required" gems that are added
to all Gemfiles, and a set of "optional" gems that a single module might add.

Within the templates, values can be accessed in the `@configs` hash, which is
merged from the values under the keys `:global` and the target file name (no
`.erb` suffix).

The list of modules to manage is in `managed_modules.yml` in the configuration
directory. This lists just the names of the modules to be managed.

ModuleSync can be called from the command line with parameters to change the
branch you're working on or the remote to clone from and push to. You can also
define these parameters in a file named `modulesync.yml` in the configuration
directory.

Installing
----------

```
gem install modulesync
```

For developers:

```
gem build modulesync.gemspec
gem install modulesync-*.gem
```

Workflow
--------

### Default mode

With no additional arguments, ModuleSync clones modules from the puppetlabs
github organization and pushes to the master branch.

#### Make changes

Make changes to a file in the moduleroot. For sanity's sake you should commit
and push these changes, but in this mode the update will be rendered from the
state of the files locally.

#### Dry-run

Do a dry-run to see what files will be changed, added and removed. This clones
the modules to `modules/<namespace>-<modulename>` in the current working
directory, or if the modules are already cloned, does an effective `git fetch
origin; git checkout master; git reset --hard origin/master` on the modules.
Don't run modulesync if the current working directory contains a modules/
directory with changes you want to keep. The dry-run makes local changes there,
but does not commit or push changes. It is still destructive in that it
overwrites local changes.

```
msync update --noop
```

#### Offline support

The --offline flag was added to allow a user to disable git support within
msync. One reason for this is because the user wants to control git commands
external to msync.  Note, when using this command, msync assumes you have
create the folder structure and git repositories correctly. If not, msync will
fail to update correctly.

```
msync update --offline
```

#### Damage mode

Make changes for real and push them back to master. This operates on the
pre-cloned modules from the dry-run or clones them fresh if the modules aren't
found.

```
msync update -m "Commit message"
```

Amend the commit if changes are needed.

```
msync update --amend
```

For most workflows you will need to force-push an amended commit. Not required
for gerrit.

```
msync update --amend --force
```

#### Automating Updates

You can install a pre-push git hook to automatically clone, update, and push
modules upon pushing changes to the configuration directory. This does not
include a noop mode.

```
msync hook activate
```

If you have activated the hook but want to make changes to the configuration
directory (such as changes to `managed_modules.yml` or `modulesync.yml`) without
touching the modules, you can deactivate the hook.

```
msync hook deactivate
```

#### Submitting PRs/MRs to GitHub or GitLab

You can have modulesync submit Pull Requests on GitHub or Merge Requests on
GitLab automatically with the `--pr` CLI option.

```
msync update --pr
```

In order for GitHub PRs or GitLab MRs to work, you must either provide
the `GITHUB_TOKEN` or `GITLAB_TOKEN` environment variables,
or set them per repository in `managed_modules.yml`, using the `github` or
`gitlab` keys respectively.

For GitHub Enterprise and self-hosted GitLab instances you also need to set the
`GITHUB_BASE_URL` or `GITLAB_BASE_URL` environment variables, or specify the
`base_url` parameter in `modulesync.yml`:

```yaml
---
repo1:
  github:
    token: 'EXAMPLE_TOKEN'
    base_url: 'https://api.github.com/'

repo2:
  gitlab:
    token: 'EXAMPLE_TOKEN'
    base_url: 'https://git.example.com/api/v4'
```

Then:

* Set the PR/MR title with `--pr-title` or in `modulesync.yml` with the
  `pr_title` attribute.
* Assign labels to the PR/MR with `--pr-labels` or in `modulesync.yml` with
  the `pr_labels` attribute. **NOTE:** `pr_labels` should be a list. When
  using the `--pr-labels` CLI option, you should use a comma separated list.
* Set the target branch with `--pr-target-branch` or in `modulesync.yml` with
  the `pr_target_branch` attribute.

More details for GitHub:

* Octokit [`api_endpoint`](https://github.com/octokit/octokit.rb#interacting-with-the-githubcom-apis-in-github-enterprise)

### Using Forks and Non-master branches

The default functionality is to run ModuleSync on the puppetlabs modules, but
you can use this on your own organization's modules. This functionality also
applies if you want to work on a fork of the puppetlabs modules or work on a
non-master branch of any organization's modules. ModuleSync does not support
cloning from one remote and pushing to another, you are expected to fork
manually. It does not support automating pull requests.

#### Dry-run

If you dry-run before doing the live update, you need to specify what namespace
to clone from because the live update will not re-clone if the modules are
already cloned. The namespace should be your fork, not the upstream module (if
working on a fork).

```
msync update -n puppetlabs --noop
```

#### Damage mode

You don't technically need to specify the namespace if the modules are already
cloned from the dry-run, but it doesn't hurt. You do need to specify the
namespace if the modules are not pre-cloned. You need to specify a branch to
push to if you are not pushing to master.

```
msync update -n puppetlabs -b sync_branch -m "Commit message"
```

#### Configuring ModuleSync defaults

If you're not using the puppetlabs modules or only ever pushing to a fork of
them, then specifying the namespace and branch every time you use ModuleSync
probably seems excessive. You can create a file called modulesync.yml in the
configuration directory that provides these arguments automatically. This file
has a form such as:

```yaml
---
namespace: mygithubusername
branch: modulesyncbranch
```

Then you can run ModuleSync without extra arguments:

```
msync update --noop
msync update -m "Commit message"
```

Available parameters for modulesync.yml

* `git_base` : The default URL to git clone from (Default: 'git@github.com:')
* `namespace` : Namespace of the projects to manage (Default: 'puppetlabs').
  This value can be overridden in the module name (e.g. 'namespace/mod') or by
  using the `namespace` key for the module in `managed_modules.yml`.
* `branch` : Branch to push to (Default: 'master')
* `remote_branch` : Remote branch to push to (Default: Same value as branch)
* `message` : Commit message to apply to updated modules.
* `pre_commit_script` : A script to be run before commiting (e.g. 'contrib/myfooscript.sh')
* `pr_title` : The title to use when submitting PRs/MRs to GitHub or GitLab.
* `pr_labels` : A list of labels to assign PRs/MRs created on GitHub or GitLab.

##### Example

###### GitHub

```yaml
---
namespace: MySuperOrganization
branch: modulesyncbranch
pr_title: "Updates to module template files via modulesync"
pr_labels:
  - TOOLING
  - MAINTENANCE
  - MODULESYNC
```

###### GitLab

```yaml
---
git_base: 'user@gitlab.example.com:'
namespace: MySuperOrganization
branch: modulesyncbranch
```

###### Gerrit

```yaml
---
namespace: stackforge
git_base:  ssh://jdoe@review.openstack.org:29418/
branch: msync_foo
remote_branch: refs/publish/master/msync_foo
pre_commit_script: openstack-commit-msg-hook.sh
```

#### Filtering Repositories

If you only want to sync some of the repositories in your managed_modules.yml, use the `-f` flag to filter by a regex:

```
msync update -f augeas -m "Commit message"    # acts only on the augeas module
msync update -f puppet-a..o "Commit message"
```

If you want to skip syncing some of the repositories in your managed_modules.yml, use the `-x` flag to filter by a regex:

```
msync update -x augeas -m "Commit message"    # acts on all modules except the augeas module
msync update -x puppet-a..o "Commit message"
```

If no `-f` is specified, all repository are processed, if no `-x` is specified no repository is skipped. If a repository matches both `-f` and `-x` it is skipped.

#### Pushing to a different remote branch

If you want to push the modified branch to a different remote branch, you can use the -r flag:

```
msync update -r master_new -m "Commit message"
```

#### Automating updates

If you install a git hook, you need to tell it what remote and branch to push
to. This may not work properly if you already have the modules cloned from a
different remote. The hook will also look in modulesync.yml for default
arguments.

```
msync hook activate -n puppetlabs -b sync_branch
```

#### Updating metadata.json

Modulesync can optionally bump the minor version in `metadata.json` for each
modified modules if you add the `--bump` flag to the command line:

```
msync update -m "Commit message" --bump
```

#### Tagging repositories

If you wish to tag the modified repositories with the newly bumped version,
you can do so by using the `--tag` flag:

```
msync update -m "Commit message" --bump --tag
```

#### Setting the tag pattern

You can also set the format of the tag to be used (`printf`-formatted)
by setting the `tag_pattern` option:

```
msync update -m "Commit message" --bump --tag --tag_pattern 'v%s'
```

The default for the tag pattern is `%s`.

#### Updating the CHANGELOG

When bumping the version in `metadata.json`, modulesync can let you
updating `CHANGELOG.md` in each modified repository.

This is one by using the `--changelog` flag:

```
msync update -m "Commit message" --bump --changelog
```

This flag will cause the `CHANGELOG.md` file to be updated with the
current date, bumped (minor) version, and commit message.

If `CHANGELOG.md` is absent in the repository, nothing will happen.


#### Working with templates

As mentioned, files in the moduleroot directory must be ERB templates (they must have an .erb extension, or they will be ignored). These files have direct access to @configs hash, which gets values from config_defaults.yml file and from the module being processed:

```erb
<%= @configs[:git_base] %>
<%= @configs[:namespace] %>
<%= @configs[:puppet_module] %>
```

Alternatively some meta data is passed to the template. This will allow you to add custom Ruby extensions inside the
template, reading other files from the module, to make the template system more adaptive.

```erb
module: <%= @metadata[:module_name] %>
target: <%= @metadata[:target_file] %>
workdir: <%= @metadata[:workdir] %>
```

Will result in something like:

```
module: puppet-test
target: modules/github-org/puppet-test/test
workdir: modules/github-org/puppet-test
```

The Templates
-------------

See [Puppet's modulesync\_configs](https://github.com/puppetlabs/modulesync_configs) and [Vox Pupuli's modulesync\_config](https://github.com/voxpupuli/modulesync_config)
repositories for different templates currently in use.

## Transfer Notice

This plugin was originally authored by [Puppet Inc](http://puppet.com).
The maintainer preferred that Vox Pupuli take ownership of the module for future improvement and maintenance.
Existing pull requests and issues were transferred over, please fork and continue to contribute at https://github.com/voxpupuli/modulesync.

Previously: https://github.com/puppetlabs/modulesync

## License

This gem is licensed under the Apache-2 license.

## Release information

To make a new release, please do:
* update the version in the gemspec file
* Install gems with `bundle install --with release --path .vendor`
* generate the changelog with `bundle exec rake changelog`
* Check if the new version matches the closed issues/PRs in the changelog
* Create a PR with it
* After it got merged, push a tag. GitHub actions will do the actual release to rubygems and GitHub Packages
