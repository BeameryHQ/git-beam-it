# Beam-it: Bulk clone Github Repositories

This bash script will bulk clone Github repositories for a specific user/organisation or team.

The script will automatically configure itself by asking the user to enter some required information in order to be able to communicate with the Github API.

> The script has no external dependencies except for [jq](https://stedolan.github.io/jq/) which is only required to parse the team list.

When running the script for the first time, the user will be prompted to enter his Github username and API personal access token. For more information on API personal access tokens, check this [Github tutorial](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)

## Repositories Refresh

When cloning, if the repository already exists then the script will perfrom a `git pull` assuming that the remote is `origin` and will update the local `master` branch

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
Usage: git beam-it <options>
```

#### Options

| Argument                  | Name             | Description                                                                                                                           | Default |
|---------------------------|------------------|---------------------------------------------------------------------------------------------------------------------------------------|---------|
| `-h`                      | **help**         | show help                                                                                                                             |         |
| `-i`                      | **interactive**   | interactive clone mode. The user will be prompted before cloning each repo                                                            | false   |
| `-d`                      | **directory**    | specify a directory to clone all the repositories into **without a trailing slash** e.g. `/temp`                                      | `.`     |
| `-p`                      | **type**         | specify the types of repos supported by Github you wish to clone down. Supported types: `all`, `owner`, `public`, `private`, `member` | `all`   |
| `-s`                      | **ssh**          | clone github repos over ssh and not https (this will use the SSH keys if uploaded to Github and will prevent the password prompt)     | false   |
| `-r`                      | **regex**        | filter repositories based on this regex                                                                                               |         |
| `-t`            | **team**         | clone only repositories belonging to this specific team id                                                                            |         |
| `-o` | **organisation** | clone only repositories belonging to this specific organisation name

If the paramteres `-t` and `-o` have been left empty, then the script will fetch the list of ogranisations and teams for that specific user, the user will then be prompted to enter the organisation name or team id or just skip to fetch all repositories.

### Examples:

```bash
# Clone interactively all the private repositories for the user
git beam-it -p private -i

# Clone interactively all the public repos that match the regex .*SeedJobs.* (any repo that contain SeedJobs)
git beam-it -i -r .*SeedJobs.*

# Clone all the public repositores for organisation SeedJobs
git beam-it -p public -o SeedJobs

# Clone all team repos .. first show a prompt of the list of teams and do the clone over SSH into a temp directory at home
git beam-it -d ~/temp -s -t
```

> the paramteres `-t` and `-o` are mutually exclusive .. make sure you only execute the command for a specific team or organisation.

> beam-it prompts the user to select from his list of teams if no team id was defined

### Known Issues

 - Due to limitations in Github API, users cannot specify the type of repos to clone down for teams. This means that all the team repos (public, private) will be cloned down
 - At the moment, there is no way to exclude forks from being cloned down as well :()

