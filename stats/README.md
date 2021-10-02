## Description
Get varied stats from git or whereever

To use this just clone the repo.

## Deploys
The deploys call will show the deploys that are being made per month. It writes them to a csv in the stats/data directory.
The script expects deploys to be signified by a semver tag. Ex: v2.2.5

### Usage

```
cd some/git/repo
ruby dir/to/stats_repo/deploys.rb
```

## Project LOC
Get the lines of code in multiple projects in a monolith. Projects is a bit of a misnomer. This is split between ruby, coffeescript, typescript and javascript.

### Usage

Running this is a bit hardcore. It goes through the git history and checks out the code at different periods. It can be a little unstable. It only works from the master branch.

```
cd some/git/repo
git checkout master
ruby dir/to/stats_repo/project_loc.rb
```

## Knowledge Breakdown

Given a directory, this script will git-blame all the inner files and find the breakdown of who last touched a file.

### Usage
```
ce some/git/repo
ruby dir/to/stats_repo/knowledge_breakdown.rb app/lib/directory/
```
