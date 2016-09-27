export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# 2016-09-26: Load the SSH keys into the keychain.
ssh-add -A 2>/dev/null;
