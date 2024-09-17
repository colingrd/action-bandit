# Bandit Reviewdog Action

[![Test](https://github.com/brunohaf/action-bandit-pvd/workflows/Test/badge.svg)](https://github.com/brunohaf/action-bandit-pvd/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/brunohaf/action-bandit-pvd/workflows/reviewdog/badge.svg)](https://github.com/brunohaf/action-bandit-pvd/actions?query=workflow%3Areviewdog)
[![depup](https://github.com/brunohaf/action-bandit-pvd/workflows/depup/badge.svg)](https://github.com/brunohaf/action-bandit-pvd/actions?query=workflow%3Adepup)
[![release](https://github.com/brunohaf/action-bandit-pvd/workflows/release/badge.svg)](https://github.com/brunohaf/action-bandit-pvd/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/brunohaf/action-bandit-pvd?logo=github&sort=semver)](https://github.com/brunohaf/action-bandit-pvd/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

![github-pr-review demo](https://user-images.githubusercontent.com/3797062/73162963-4b8e2b00-4132-11ea-9a3f-f9c6f624c79f.png)
![github-pr-check demo](https://user-images.githubusercontent.com/3797062/73163032-70829e00-4132-11ea-8481-f213a37db354.png)

This action runs [Bandit](https://github.com/PyCQA/bandit), a security linter for Python code, and integrates with [reviewdog](https://github.com/reviewdog/reviewdog) to provide inline comments on pull requests. It is built using action composition for release automation.

If you want to create your own reviewdog action from scratch without using this
template, please check and copy release automation flow.
It's important to manage release workflow and sync reviewdog version for all
reviewdog actions.

This repo contains a sample action to run [misspell](https://github.com/client9/misspell).

## Input

```yaml
inputs:
  github_token:
    description: "GITHUB_TOKEN"
    default: "${{ github.token }}"
  workdir:
    description: "Working directory relative to the root directory."
    default: "."
  bandit_config:
    description: "Path to Bandit configuration file."
    default: "pyproject.toml"
  bandit_flags:
    description: "Additional flags for Bandit."
    default: ""
  verbose:
    description: "Enable verbose mode."
    default: "false"
  ### Flags for reviewdog ###
  tool_name:
    description: "Tool name to use for reviewdog reporter."
    default: "bandit"
  level:
    description: "Report level for reviewdog [info,warning,error]."
    default: "error"
  reporter:
    description: "Reporter for reviewdog [github-check,github-pr-review,github-pr-check]."
    default: "github-check"
  filter_mode:
    description: "Filtering mode for reviewdog [added,diff_context,file,nofilter]."
    default: "added"
  fail_on_error:
    description: "Exit code for reviewdog when errors are found [true,false]."
    default: "false"
  reviewdog_flags:
    description: "Additional reviewdog flags."
    default: ""
```

## Usage

```yaml
name: Run Bandit
on: [pull_request]
jobs:
  bandit:
    name: Bandit Security Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: brunohaf/action-bandit-pvd@v1
        with:
          github_token: ${{ secrets.github_token }}
          # Change reviewdog reporter if needed [github-check,github-pr-review,github-pr-check]
          reporter: github-pr-review
          # Change reporter level if needed
          # GitHub Status Check won't become a failure with warning level
          level: warning
```

## Development

### Release

#### [haya14busa/action-bumpr](https://github.com/haya14busa/action-bumpr)

This action updates major/minor release tags on a tag push. For example, it updates the v1 and v1.2 tags when v1.2.3 is released.

#### [haya14busa/action-update-semver](https://github.com/haya14busa/action-update-semver)

This action updates major/minor release tags on a tag push. e.g. Update v1 and v1.2 tag when released v1.2.3.
ref: https://help.github.com/en/articles/about-actions#versioning-your-action

### Lint - reviewdog integration

This reviewdog action itself is integrated with reviewdog to run lints
which is useful for [action composition] based actions.

[action composition]: https://docs.github.com/en/actions/creating-actions/creating-a-composite-action

![reviewdog integration](https://user-images.githubusercontent.com/3797062/72735107-7fbb9600-3bde-11ea-8087-12af76e7ee6f.png)

Supported linters:

- [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)
- [reviewdog/action-shfmt](https://github.com/reviewdog/action-shfmt)
- [reviewdog/action-actionlint](https://github.com/reviewdog/action-actionlint)
- [reviewdog/action-misspell](https://github.com/reviewdog/action-misspell)
- [reviewdog/action-alex](https://github.com/reviewdog/action-alex)

### Dependencies Update Automation

This repository uses [reviewdog/action-depup](https://github.com/reviewdog/action-depup) to update
reviewdog version.

![reviewdog depup demo](https://user-images.githubusercontent.com/3797062/73154254-170e7500-411a-11ea-8211-912e9de7c936.png)
