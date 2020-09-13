downloadStars.sh
================

## Why?

The accuracy of finding starred repository in GitHub from Stars -> Filters is :expressionless:...

So, this script is made to download all starred repositories of a user to local md file. Then, using your favorite search tool/command to find the repository you want from local file :massage:.

## How?

```
Usage:
  ./downloadStars.sh <github_username>
```

A <username>.md will be created in `./stars/` folder with all starred repositories.

## Limitation

This script is calling GitHub API to download starred repositories of a user. However, GitHub API has a [rate limit](https://developer.github.com/v3/#rate-limiting). Usually, it's `60` requests per hour for non-authenticated usage. If you run this script and reach API limit, changing your IP address will make this script work again immediately. My apology, I'm too lazy to implement authenticated requests ¯\\\_(ツ)\_/¯.

---

<a href="https://www.buymeacoffee.com/kevcui" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-orange.png" alt="Buy Me A Coffee" height="60px" width="217px"></a>
