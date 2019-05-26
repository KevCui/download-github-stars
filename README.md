downloadStars.sh
================

## Why?

The accuracy of finding starred repository from Stars -> Filters is :expressionless:...

So, this script is made to download all starred repositories of a certain user to local md file. Then, using your favorite search tool/command to find the repository :massage: from local file.

## How?

```
Usage:
  ./downloadStars.sh <github_username>
```

A <username>.md will be created in `./stars/` folder with all starred repositories.

## Limitation

This script is calling GitHub API to download starred repositories of a user. However, GitHub API has a [rate limit](https://developer.github.com/v3/#rate-limiting). Usually, it's `60` requests per hour for non-authenticated usage. If you run this script and reach API limit, changing your IP address will make this script work again immediately. My apology, I'm too lazy to implement authenticated requests ¯\_(ツ)_/¯.
