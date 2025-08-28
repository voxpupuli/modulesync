# Changelog

All notable changes to this project will be documented in this file.

## [4.0.0](https://github.com/voxpupuli/modulesync/tree/4.0.0) (2025-08-28)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.5.0...4.0.0)

**Breaking changes:**

- Require Ruby 3.2+ [\#317](https://github.com/voxpupuli/modulesync/pull/317) ([bastelfreak](https://github.com/bastelfreak))
- Drop ruby older than 3.2.0 [\#312](https://github.com/voxpupuli/modulesync/pull/312) ([traylenator](https://github.com/traylenator))

**Implemented enhancements:**

- Allow YAML aliases in configuration [\#311](https://github.com/voxpupuli/modulesync/pull/311) ([traylenator](https://github.com/traylenator))


## [3.5.0](https://github.com/voxpupuli/modulesync/tree/3.5.0) (2025-07-23)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.4.2...3.5.0)

**Merged pull requests:**

- thor: require 1.4 or newer [\#309](https://github.com/voxpupuli/modulesync/pull/309) ([kenyon](https://github.com/kenyon))
- README: change example config to voxpupuli [\#308](https://github.com/voxpupuli/modulesync/pull/308) ([trefzer](https://github.com/trefzer))

## [3.4.2](https://github.com/voxpupuli/modulesync/tree/3.4.2) (2025-06-27)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.4.1...3.4.2)

**Merged pull requests:**

- cleanup github release action; switch to rubygems trusted publishers [\#306](https://github.com/voxpupuli/modulesync/pull/306) ([bastelfreak](https://github.com/bastelfreak))

## [3.4.1](https://github.com/voxpupuli/modulesync/tree/3.4.1) (2025-05-21)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.4.0...3.4.1)

**Fixed bugs:**

- thor: Allow 1.2 to stay compatible with ancient facter [\#303](https://github.com/voxpupuli/modulesync/pull/303) ([bastelfreak](https://github.com/bastelfreak))

## [3.4.0](https://github.com/voxpupuli/modulesync/tree/3.4.0) (2025-05-21)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.3.0...3.4.0)

**Merged pull requests:**

- Disable coverage reports [\#300](https://github.com/voxpupuli/modulesync/pull/300) ([bastelfreak](https://github.com/bastelfreak))
- voxpupuli-rubocop: Update 3.0.0-\>3.1.0 [\#299](https://github.com/voxpupuli/modulesync/pull/299) ([bastelfreak](https://github.com/bastelfreak))
- voxpupuli-rubocop: Update 2.8.0-\>3.0.0 [\#297](https://github.com/voxpupuli/modulesync/pull/297) ([bastelfreak](https://github.com/bastelfreak))
- Allow thor 1.3.2 and newer [\#293](https://github.com/voxpupuli/modulesync/pull/293) ([dependabot[bot]](https://github.com/apps/dependabot))

## [3.3.0](https://github.com/voxpupuli/modulesync/tree/3.3.0) (2025-02-26)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.2.0...3.3.0)

**Implemented enhancements:**

- Add Ruby 3.4 to CI [\#295](https://github.com/voxpupuli/modulesync/pull/295) ([kenyon](https://github.com/kenyon))
- gemspec: allow puppet-blacksmith 8.x [\#294](https://github.com/voxpupuli/modulesync/pull/294) ([kenyon](https://github.com/kenyon))
- CI: Build gems with strict and verbose mode [\#292](https://github.com/voxpupuli/modulesync/pull/292) ([bastelfreak](https://github.com/bastelfreak))
- Add Ruby 3.3 to CI [\#291](https://github.com/voxpupuli/modulesync/pull/291) ([bastelfreak](https://github.com/bastelfreak))
- Add a flag to `msync execute` on the default branch [\#288](https://github.com/voxpupuli/modulesync/pull/288) ([smortex](https://github.com/smortex))
- Update octokit requirement from \>= 4, \< 9 to \>= 4, \< 10 [\#287](https://github.com/voxpupuli/modulesync/pull/287) ([dependabot[bot]](https://github.com/apps/dependabot))
- update to voxpupuli-rubocop 2.7.0; adjust path to unit files & rubocop: autofix & regen todo file [\#281](https://github.com/voxpupuli/modulesync/pull/281) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- pin thor to 1.3.0 [\#282](https://github.com/voxpupuli/modulesync/pull/282) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- Update voxpupuli-rubocop requirement from ~\> 2.7.0 to ~\> 2.8.0 [\#290](https://github.com/voxpupuli/modulesync/pull/290) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update gitlab requirement from ~\> 4.0 to \>= 4, \< 6 [\#289](https://github.com/voxpupuli/modulesync/pull/289) ([dependabot[bot]](https://github.com/apps/dependabot))
- rubocop: Fix Style/FrozenStringLiteralComment [\#285](https://github.com/voxpupuli/modulesync/pull/285) ([bastelfreak](https://github.com/bastelfreak))

## [3.2.0](https://github.com/voxpupuli/modulesync/tree/3.2.0) (2023-10-31)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.1.0...3.2.0)

**Implemented enhancements:**

- Update octokit requirement from \>= 4, \< 8 to \>= 4, \< 9 [\#278](https://github.com/voxpupuli/modulesync/pull/278) ([dependabot[bot]](https://github.com/apps/dependabot))

**Merged pull requests:**

- Clean up redundant statement [\#276](https://github.com/voxpupuli/modulesync/pull/276) ([ekohl](https://github.com/ekohl))

## [3.1.0](https://github.com/voxpupuli/modulesync/tree/3.1.0) (2023-08-02)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/3.0.0...3.1.0)

Release 3.0.0 was broken. It was tagged as 3.0.0 but accidentally released as 2.7.0. The only breaking change was dropping support for EoL ruby versions.

**Merged pull requests:**

- rubocop: autofix [\#273](https://github.com/voxpupuli/modulesync/pull/273) ([bastelfreak](https://github.com/bastelfreak))
- Update octokit requirement from \>= 4, \< 7 to \>= 4, \< 8 [\#272](https://github.com/voxpupuli/modulesync/pull/272) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update voxpupuli-rubocop requirement from ~\> 1.3 to ~\> 2.0 [\#271](https://github.com/voxpupuli/modulesync/pull/271) ([dependabot[bot]](https://github.com/apps/dependabot))

## [3.0.0](https://github.com/voxpupuli/modulesync/tree/3.0.0) (2023-06-16)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.6.0...3.0.0)

**Breaking changes:**

- Drop EoL Ruby 2.5/2.6 support [\#270](https://github.com/voxpupuli/modulesync/pull/270) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- Update puppet-blacksmith requirement from \>= 3.0, \< 7 to \>= 3.0, \< 8 [\#268](https://github.com/voxpupuli/modulesync/pull/268) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update octokit requirement from ~\> 4.0 to \>= 4, \< 7 [\#263](https://github.com/voxpupuli/modulesync/pull/263) ([dependabot[bot]](https://github.com/apps/dependabot))

## [2.6.0](https://github.com/voxpupuli/modulesync/tree/2.6.0) (2023-04-14)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.5.0...2.6.0)

**Implemented enhancements:**

- Add Ruby 3.2 support [\#266](https://github.com/voxpupuli/modulesync/pull/266) ([bastelfreak](https://github.com/bastelfreak))
- Update to latest RuboCop 1.28.2 [\#265](https://github.com/voxpupuli/modulesync/pull/265) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- Fix compatibility with latest `ruby-git` [\#260](https://github.com/voxpupuli/modulesync/pull/260) ([alexjfisher](https://github.com/alexjfisher))

**Closed issues:**

- msync update --noop is broken with git 1.17.x [\#259](https://github.com/voxpupuli/modulesync/issues/259)

**Merged pull requests:**

- Add CI best practices [\#264](https://github.com/voxpupuli/modulesync/pull/264) ([bastelfreak](https://github.com/bastelfreak))
- dependabot: check for github actions and gems [\#261](https://github.com/voxpupuli/modulesync/pull/261) ([bastelfreak](https://github.com/bastelfreak))

## [2.5.0](https://github.com/voxpupuli/modulesync/tree/2.5.0) (2022-10-14)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.4.0...2.5.0)

**Implemented enhancements:**

- Copy file permissions from template to target [\#257](https://github.com/voxpupuli/modulesync/pull/257) ([ekohl](https://github.com/ekohl))

## [2.4.0](https://github.com/voxpupuli/modulesync/tree/2.4.0) (2022-09-27)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.3.1...2.4.0)

**Implemented enhancements:**

- Expose namespace in metadata [\#254](https://github.com/voxpupuli/modulesync/pull/254) ([ekohl](https://github.com/ekohl))

**Merged pull requests:**

- Fix Rubocop and add additional rubocop plugins [\#255](https://github.com/voxpupuli/modulesync/pull/255) ([ekohl](https://github.com/ekohl))

## [2.3.1](https://github.com/voxpupuli/modulesync/tree/2.3.1) (2022-05-05)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.3.0...2.3.1)

**Fixed bugs:**

- Handle Ruby 3.1 ERB trim\_mode deprecation [\#252](https://github.com/voxpupuli/modulesync/pull/252) ([ekohl](https://github.com/ekohl))

## [2.3.0](https://github.com/voxpupuli/modulesync/tree/2.3.0) (2022-03-07)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.2.0...2.3.0)

**Implemented enhancements:**

- CLI: Show relevant help when using --help option on a subcommand [\#248](https://github.com/voxpupuli/modulesync/pull/248) ([neomilium](https://github.com/neomilium))
- New CLI commands [\#244](https://github.com/voxpupuli/modulesync/pull/244) ([neomilium](https://github.com/neomilium))

**Fixed bugs:**

- Existing MR makes msync fail \(which leaves changes in target branch\) [\#195](https://github.com/voxpupuli/modulesync/issues/195)
- Target branch `.sync.yml` not taken into account on branch update \(--force\) [\#192](https://github.com/voxpupuli/modulesync/issues/192)
- Fix error when git upstream branch is deleted [\#240](https://github.com/voxpupuli/modulesync/pull/240) ([neomilium](https://github.com/neomilium))

**Closed issues:**

- Linter is missing in CI [\#237](https://github.com/voxpupuli/modulesync/issues/237)
- Behavior tests are missing in CI [\#236](https://github.com/voxpupuli/modulesync/issues/236)

**Merged pull requests:**

- Properly ensure the parent directory exists [\#247](https://github.com/voxpupuli/modulesync/pull/247) ([ekohl](https://github.com/ekohl))
- Add Ruby 3.1 to CI matrix [\#245](https://github.com/voxpupuli/modulesync/pull/245) ([bastelfreak](https://github.com/bastelfreak))
- Fix rubocop offences and add linter to CI [\#243](https://github.com/voxpupuli/modulesync/pull/243) ([neomilium](https://github.com/neomilium))
- Support `.sync.yml` changes between two runs [\#242](https://github.com/voxpupuli/modulesync/pull/242) ([neomilium](https://github.com/neomilium))
- Fix gitlab merge request submission [\#241](https://github.com/voxpupuli/modulesync/pull/241) ([neomilium](https://github.com/neomilium))
- Add behavior tests to CI [\#239](https://github.com/voxpupuli/modulesync/pull/239) ([neomilium](https://github.com/neomilium))
- Rework PR/MR feature [\#219](https://github.com/voxpupuli/modulesync/pull/219) ([neomilium](https://github.com/neomilium))
- Refactor code for maintainabilty [\#206](https://github.com/voxpupuli/modulesync/pull/206) ([neomilium](https://github.com/neomilium))

## [2.2.0](https://github.com/voxpupuli/modulesync/tree/2.2.0) (2021-07-24)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.1.1...2.2.0)

**Implemented enhancements:**

- Implement codecov/update README.md [\#234](https://github.com/voxpupuli/modulesync/pull/234) ([bastelfreak](https://github.com/bastelfreak))
- Checkout default\_branch and not hardcoded `master` [\#233](https://github.com/voxpupuli/modulesync/pull/233) ([alexjfisher](https://github.com/alexjfisher))

**Fixed bugs:**

- Fix condition for triggering the release workflow [\#232](https://github.com/voxpupuli/modulesync/pull/232) ([smortex](https://github.com/smortex))

**Merged pull requests:**

- Move cucumber from Gemfile to gemspec [\#230](https://github.com/voxpupuli/modulesync/pull/230) ([bastelfreak](https://github.com/bastelfreak))
- switch to https link in gemspec [\#228](https://github.com/voxpupuli/modulesync/pull/228) ([bastelfreak](https://github.com/bastelfreak))
- dont install octokit via Gemfile [\#227](https://github.com/voxpupuli/modulesync/pull/227) ([bastelfreak](https://github.com/bastelfreak))
- Allow latest aruba dependency [\#226](https://github.com/voxpupuli/modulesync/pull/226) ([bastelfreak](https://github.com/bastelfreak))

## [2.1.1](https://github.com/voxpupuli/modulesync/tree/2.1.1) (2021-06-15)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.1.0...2.1.1)

The 2.1.0 release didn't make it to github packages. 2.1.1 is a new release with identical code.

## [2.1.0](https://github.com/voxpupuli/modulesync/tree/2.1.0) (2021-06-15)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.0.2...2.1.0)

**Merged pull requests:**

- publish to github packages + test on ruby 3 [\#222](https://github.com/voxpupuli/modulesync/pull/222) ([bastelfreak](https://github.com/bastelfreak))
- Rework exception handling [\#217](https://github.com/voxpupuli/modulesync/pull/217) ([neomilium](https://github.com/neomilium))
- Split generic and specific code [\#215](https://github.com/voxpupuli/modulesync/pull/215) ([neomilium](https://github.com/neomilium))
- Refactor repository related code [\#214](https://github.com/voxpupuli/modulesync/pull/214) ([neomilium](https://github.com/neomilium))
- Tests: Add tests for bump feature [\#213](https://github.com/voxpupuli/modulesync/pull/213) ([neomilium](https://github.com/neomilium))
- Refactor puppet modules properties [\#212](https://github.com/voxpupuli/modulesync/pull/212) ([neomilium](https://github.com/neomilium))
- Switch from Travis CI to GitHub Actions [\#205](https://github.com/voxpupuli/modulesync/pull/205) ([neomilium](https://github.com/neomilium))

## [2.0.2](https://github.com/voxpupuli/modulesync/tree/2.0.2) (2021-04-03)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.0.1...2.0.2)

**Fixed bugs:**

- Fix language-dependent Git output handling [\#200](https://github.com/voxpupuli/modulesync/pull/200) ([neomilium](https://github.com/neomilium))

**Closed issues:**

- PR/MR feature should honor the repository default branch name as target branch [\#207](https://github.com/voxpupuli/modulesync/issues/207)
- Add linting \(rubocop\) to Travis CI configuration [\#153](https://github.com/voxpupuli/modulesync/issues/153)
- Language sensitive GIT handling [\#85](https://github.com/voxpupuli/modulesync/issues/85)

**Merged pull requests:**

- Fix spelling of PR CLI option \(kebab-case\) [\#209](https://github.com/voxpupuli/modulesync/pull/209) ([bittner](https://github.com/bittner))
- Correctly state which config file to update [\#208](https://github.com/voxpupuli/modulesync/pull/208) ([bittner](https://github.com/bittner))
- Fix exit status code on failures [\#204](https://github.com/voxpupuli/modulesync/pull/204) ([neomilium](https://github.com/neomilium))
- Remove monkey patches [\#203](https://github.com/voxpupuli/modulesync/pull/203) ([neomilium](https://github.com/neomilium))
- Improve tests capabilities by using local/fake remote repositories [\#202](https://github.com/voxpupuli/modulesync/pull/202) ([neomilium](https://github.com/neomilium))
- Minor modernization and cosmetic fix [\#201](https://github.com/voxpupuli/modulesync/pull/201) ([neomilium](https://github.com/neomilium))

## [2.0.1](https://github.com/voxpupuli/modulesync/tree/2.0.1) (2020-10-06)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/2.0.0...2.0.1)

**Fixed bugs:**

- Use remote\_branch for PRs when specified [\#194](https://github.com/voxpupuli/modulesync/pull/194) ([raphink](https://github.com/raphink))

**Merged pull requests:**

- Allow newer puppet-blacksmith versions [\#197](https://github.com/voxpupuli/modulesync/pull/197) ([bastelfreak](https://github.com/bastelfreak))

## [2.0.0](https://github.com/voxpupuli/modulesync/tree/2.0.0) (2020-08-18)

[Full Changelog](https://github.com/voxpupuli/modulesync/compare/1.3.0...2.0.0)

**Breaking changes:**

- Drop support for Ruby 2.4 and older [\#191](https://github.com/voxpupuli/modulesync/pull/191) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- Symbolize keys in managed\_modules except for module names [\#185](https://github.com/voxpupuli/modulesync/pull/185) ([raphink](https://github.com/raphink))

**Fixed bugs:**

- GitLab MR: undefined method `\[\]' for nil:NilClass \(NoMethodError\) [\#187](https://github.com/voxpupuli/modulesync/issues/187)
- msync fails with nilClass error [\#172](https://github.com/voxpupuli/modulesync/issues/172)
- Fix NoMethodError for --pr option \(caused by `module_options = nil`\) / introduce --noop [\#188](https://github.com/voxpupuli/modulesync/pull/188) ([bittner](https://github.com/bittner))
- Allow empty module options in self.pr\(\) [\#186](https://github.com/voxpupuli/modulesync/pull/186) ([raphink](https://github.com/raphink))

## [1.3.0](https://github.com/voxpupuli/modulesync/tree/1.3.0) (2020-07-03)

* Expose --managed_modules_conf [#184](https://github.com/voxpupuli/modulesync/pull/184)
* Allow absolute path for config files [#183](https://github.com/voxpupuli/modulesync/pull/183)
* Add pr_target_branch option [#182](https://github.com/voxpupuli/modulesync/pull/182)
* Allow to specify namespace in module_options [#181](https://github.com/voxpupuli/modulesync/pull/181)
* Allow to override PR parameters per module [#178](https://github.com/voxpupuli/modulesync/pull/178)
* Include the gitlab library (if we interact with gitlab), not github [#179](https://github.com/voxpupuli/modulesync/pull/179)

## 2020-07-03 - 1.2.0

* Add support for GitLab merge requests (MRs) [#175](https://github.com/voxpupuli/modulesync/pull/175)

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


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
