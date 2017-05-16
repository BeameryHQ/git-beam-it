# Beam-it: Bulk clone Github Repositories

This bash script will bulk clone Github repositories for a specific user/organisation or team.

The script will automatically configure itself by asking the user to enter some required information in order to be able to communicate with the Github API.

> The script has no external dependencies except for [jq](https://stedolan.github.io/jq/) which is only required to parse the team list.

![beam-it](https://dl.dropboxusercontent.com/u/5258344/Blog/git-beam-it%20public.gif)

When running the script for the first time, the user will be prompted to enter his Github username and API personal access token. For more information on API personal access tokens, check this [Github tutorial](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)

## Repositories Refresh

When cloning, if the repository already exists then the script will perfrom a `git pull` assuming that the remote is `origin` and will update the local `master branch

## Installation

You can use the script `git-beam-it.sh` by exporting that into your .`bash_profile`, `.bashrc` or `.zshrc` and then make sure that it is executable with `chmod +x git-beam-it.sh`. However, the recommended way to use it is by registering it as a git plugin.

The main requirement for git plugins is that the name of the shell script should be `git-name` where `name` is the command you want to run after typing git. Our script, `beam-it` is already configured accordingly.

Now, you only need to put the script in `/usr/local/bin` or somewhere similar in your `$PATH` and thats it !

#### One-liner Installations

Installation with `curl`:

```bash
curl -L -O https://raw.githubusercontent.com/SeedJobs/git-beam-it/master/git-beam-it && sudo mv git-beam-it /usr/local/bin/ && sudo chmod +x /usr/local/bin/git-beam-it
```

Installation with `wget`:

```bash
sudo wget -P /usr/local/bin https://raw.githubusercontent.com/SeedJobs/git-beam-it/master/git-beam-it && sudo chmod +x /usr/local/bin/git-beam-it
```

> Note: After first setup, you might need to source your .bash_profile, .bashrc or .zshrc in order for the variables export to take effect and not to be prompted again

```bash
Usage: beamit <options>

Options:
-h             help            show help
-i             interactive     interactive clone mode. The user will be prompted before cloning each repo
-d             directory       specify a directory to clone all the repositories into **without a trailing slash** e.g. `/temp`
-p             pulbic          clone only public repositories (note that this does not work for teams)
-v             private         clone only private repositories (note that this does not work for teams)
-r             regex           filter repositories based on this regex
-t <teamId>    team            clone only repositories belonging to this specific team id
-o <orgName>   organisation    clone only repositories belonging to this specific organisation name
```

If the paramteres `-t` and `-o` have been left empty, then the script will fetch the list of ogranisations and teams for that specific user, the user will then be prompted to enter the organisation name or team id or just skip to fetch all repositories.

![beam-it setup](https://dl.dropboxusercontent.com/u/5258344/Blog/git-beam-it%20setup.gif)

### Examples:

```bash
# Clone interactively all the private repositories for the user
git beam-it -v -i

# Clone interactively all the public repos that match the regex .*SeedJobs.* (any repo that contain SeedJobs)
git beam-it -i -r .*SeedJobs.*

# Clone all the public repositores for organisation SeedJobs
git beam-it -p -o SeedJobs
```
![beam-it team](https://dl.dropboxusercontent.com/u/5258344/Blog/git-beam-it%20team.gif)

> beam-it prompts the user to select from his list of teams if no team id was defined

![beam-it regex](https://dl.dropboxusercontent.com/u/5258344/Blog/git-beam-it%20regex.gif)

> beam-it can filter repos by a passed regex and will exclude those that do not match
