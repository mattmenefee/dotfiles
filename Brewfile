# Install command-line tools using Homebrew
# Usage: `brew bundle Brewfile`

# Make sure we’re using the latest Homebrew
update

# Upgrade any already-installed formulae
upgrade

# Install GNU core utilities (those that come with OS X are outdated)
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
install coreutils
#sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install frequently used tools
install ack
install apple-gcc42
install direnv
install elasticsearch
install ffmpeg
install gitsh
install gource
install graphviz
install hub
install imagemagick
install macvim
install phantomjs
install python
install qt
install rbenv-gem-rehash
install redis
install ruby-build
install ssh-copy-id
install the_silver_searcher
install unrar

# Install more recent versions of some OS X tools
install vim --override-system-vi
install homebrew/dupes/grep
install homebrew/dupes/screen

# Install other useful binaries
install ack
install git
install imagemagick --with-webp
install node # This installs `npm` too using the recommended installation method
install p7zip

# Remove outdated versions from the cellar
cleanup

# Make sure everything is installed properly
doctor
