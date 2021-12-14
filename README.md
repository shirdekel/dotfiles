# dotfiles

## Install homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Install chezmoi

```sh
brew install chezmoi
```

## Log into Bitwarden 

Personal secrets are stored in Bitwarden and you'll need the Bitwarden CLI
installed. Login with:

```sh
bw login <bitwarden-email>
```

Unlock vault:

```sh
bw unlock
```

Set the `BW_SESSION` environment variable, as instructed.