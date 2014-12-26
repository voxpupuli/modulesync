ModuleSync
===========

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
Gemfile, .travis.yml, .gitignore, or spec\_helper.rb. If a file needs to
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
modules](https://github.com/puppetlabs/modulesync\_configs), can be used as an
example for your own configuration. The configuration directory contains a
directory called moduleroot which mirrors the structure of a module. The files
in the moduleroot could be flat files or ERB templates. The templates are
rendered using values from a file called config\_defaults.yml in the root (not
moduleroot) of the configuration directory. The default values can be
overridden or extended by adding a file called .sync.yml to the module itself.
This allows us to, for example, have a set of "required" gems that are added
to all Gemfiles, and a set of "optional" gems that a single module might add.

The list of modules to manage is in managed\_modules.yml in the configuration
directory. This lists just the GitHub names of the modules to be managed.

ModuleSync can be called from the command line with parameters to change the
branch you're working on or the remote to clone from and push to. You can also
define these parameters in a file named modulesync.yml in the configuration
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
state of the files locally. Run `msync update` from the root of the
configuration directory (not moduleroot), or use -c <relative path> to point
it to the location of the configuration directory.

#### Dry-run

Do a dry-run to see what files will be changed, added and removed. This clones
the modules to `modules/<namespace>-<modulename>` in the current working, or if
the modules are already cloned, does an effective `git fetch origin; git
checkout master; git reset --hard origin/master` on the modules. Don't run
modulesync if the current working directory contains a modules/ directory with
changes you want to keep. The dry-run makes local changes there, but does not
commit or push changes. It is still destructive in that it overwrites local
changes.

```
msync update --noop 
```

#### Damage mode

Make changes for real and push them back to master. This operates on the
pre-cloned modules from the dry-run or clones them fresh if the modules aren't
found.

```
msync update -m "Commit message"
```

#### Automating Updates

You can install a pre-push git hook to automatically clone, update, and push
modules upon pushing changes to the configuration directory. This does not
include a noop mode.

```
msync hook activate
```

If you have activated the hook but want to make changes to the configuration
directory (such as changes to managed_modules.yml or modulesync.yml) without
touching the modules, you can deactivate the hook.

```
msync hook deactivate
```

### Using Forks and Non-master branches

The default functionality is to run ModuleSync on the puppetlabs modules, but
you can use this on your own organization's modules. This functionality also
applies if you want to work on a fork of the puppetlabs modules or work on a
non-master branch of any organization's modules. ModuleSync does not support
cloning from one remote and pushing to another, you are expected to fork
manually. It does not yet support automating pull requests (coming soon).

#### Dry-run

If you dry-run before doing the live update, you need to specify what namespace
to clone from because the live update will not re-clone if the modules are
already cloned. The namespace should be your fork, not the upstream module. The
format should be the SSH or HTTP prefix of the full URL minus the module name
itself.

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

```
---
namespace: mygithubusername
branch: modulesyncbranch
```

Then you can run ModuleSync without extra arguments:

```
msync update --noop
msync update -m "Commit message"
```

#### Filtering Repositories

If you only want to sync some of the repositories in your managed_modules.yml, use the -f flag to filter by a regex:

```
msync update -f augeas -m "Commit message"
msync update -f puppet-a..o "Commit message"
```
#### Automating updates

If you install a git hook, you need to tell it what remote and branch to push
to. This may not work properly if you already have the modules cloned from a
different remote. The hook will also look in modulesync.yml for default
arguments.

```
msync hook activate -n puppetlabs -b sync_branch
```

The Templates
-------------

See the [modulesync\_configs](https://github.com/puppetlabs/modulesync_configs)
repository for an explanation of the templates that Puppet Labs uses on its
modules.
