#!/bin/zsh

#cd ~/.dotfiles/zsh_custom_plugins
#for plugin_dir in *
#do
#  mkdir -p ~/.dotfiles/oh-my-zsh/custom/plugins
#  if [ ! -e ~/.dotfiles/oh-my-zsh/custom/plugins/$plugin_dir ]; then
#    ln -s ~/.dotfiles/zsh_custom_plugins/$plugin_dir ~/.dotfiles/oh-my-zsh/custom/plugins/$plugin_dir
#  fi
#done

# Vundle install
cd ~/.homesick/repos/dotfiles/
vim +BundleInstall +qall
