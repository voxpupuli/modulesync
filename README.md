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

Within the templates, values can be accessed in the `@configs` hash, which is
merged from the values under the keys `:global` and the current file name.

The list of modules to manage is in managed\_modules.yml in the configuration
directory. This lists just the names of the modules to be managed.

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

Available parameters for modulesync.yml

* `git_base`: The default URL to git clone from (Default: `git@github.com:`)
* `namespace`: Namespace of the projects to manage (Default: `puppetlabs`)
* `branch`: Branch to push to (Default: `master`)
* `remote_branch`: Remote branch to push to (Default: Same value as branch)
* `hooks`: A hash of scripts (`pre_push` or `pre_commit`) relative to the project root to be run before commiting or pushing the module. Hooks receive the qualified path to the root of the module as an argument.
* `module_conf_file`: The name of the module's local sync file (Default: `.sync.yml`)
* `hook_file`: The path to the hook file that should be written when you run the `msync hook activate` command
* `project_root`: The root of the ModuleSync project directory. (Default: `.`)
* `defaults_file`: The path to the file where configuration defaults are stored. (Default: `#{project_root}/config_defaults.yml`)
* `modules_dir`: The path to the directory where the modules should be cloned. (Default: `#{project_root}/modules`)
* `moduleroot_dir`: The path to the directory where the module templates are stored (Default: `#{project_root}/moduleroot`)
* `managed_modules_file`: The path to the list of managed modules (Default: `#{project_root}/managed_modules.yml`)
* `global_defaults_key`: The key under which global variables should be stored in the `defaults_file` and `module_conf_file`. (Default: `:global`)

##### Examples

###### Github

```
---
namespace: MySuperOrganization
branch: modulesyncbranch
```

###### Gitlab

```
---
git_base: 'user@gitlab.example.com:'
namespace: MySuperOrganization
branch: modulesyncbranch
```

###### Gerrit

```
---
namespace: stackforge
git_base:  ssh://jdoe@review.openstack.org:29418/
branch: msync_foo
remote_branch: refs/publish/master/msync_foo
hooks:
  pre_commit: hooks/openstack-commit-msg-hook.sh
  pre_push: hooks/my-pre-push-script.sh
```

#### Filtering Repositories

If you only want to sync some of the repositories in your managed_modules.yml, use the -f flag to filter by a regex:

```
msync update -f augeas -m "Commit message"
msync update -f puppet-a..o "Commit message"
```

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

#### Using `pre_commit` or `pre_push` scripts
ModuleSync can run a script on your module before it runs `git commit` or `git push`. The hook script can be any file relative to the `project_root`. This can be configured on a project-wide basis in `modulesync.yml` or on a module basis in `managed_modules.yml`:

##### In `managed_modules.yml`:
```
---
  puppetlabs-stdlib:
    hooks:
      pre_push: hooks/pre_push_script.sh
      pre_commit: hooks/pre_commit_script.sh
```

##### In `modulesync.yml`:
```
---
  hooks:
    pre_commit: hooks/openstack-commit-msg-hook.sh
    pre_push: hooks/my-pre-push-script.sh
```

The Templates
-------------

See the [modulesync\_configs](https://github.com/puppetlabs/modulesync_configs)
repository for an explanation of the templates that Puppet Labs uses on its
modules.
