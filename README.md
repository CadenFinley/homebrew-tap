these are my custom taps for homebrew formulaes that I have.

![Version](https://img.shields.io/github/v/release/CadenFinley/CJsShell?label=version&color=blue)
[cjsh](https://github.com/cadenfinley/cjsshell)

### Installing a custom dev branch

Set `CJSH_DEV_BRANCH` before installing the `cjsh-dev` formula to force Homebrew to check out a specific branch:

```
CJSH_DEV_BRANCH=my-feature brew install cadenfinley/tap/cjsh-dev --HEAD
```

The selected branch name is also injected into `CJSH_GIT_HASH_OVERRIDE` so builds can report both the branch and commit.

## Issues

Please report any issues with the formulaes here and report any other issues in the project smain repository
