#!/bin/bash

#######################
#
# Set up .mydotfiles on a new computer
#
########################

######################## 
# BASIC CONFIGS
DOTFILES_REPO="git@github.com:kahdo/dotfiles.git"
DOTFILES_REPOFOLDER="$HOME/.mydotfiles"
######################## 
# What command do you want
CONFIGCMD="configit"
# and the shorthand for it...
CONFIGCMDSHORTHAND="c"
########################

######################## 
# How is this script identified in .bashrc and other places
CONFIG_IDENTIFIER="dotfiles-bootstrap"
# This is the name of the file that will be sourced from .bashrc after we bootstrap.
# you can code your shit under this file, this way leaving .bashrc as simple/standard as possible.
# this file will be stored in $HOME, all will possibly come from the dotfiles repository as well.
SRCFILE=".mybashrc"
########################

BASHRC="$HOME/.bashrc"
SOURCEFILE="$HOME/$SRCFILE"

# Useful functions
config_strip_bootstrapcode() {
    echo "Stripping config bootstrap code from \"$1\"..."

    SEDPROGRAM="/### $CONFIG_IDENTIFIER BEGIN ###/,/### $CONFIG_IDENTIFIER END ###/ d"
   
    TMPFILE=`tempfile`

    # Apply
    sed -e "$SEDPROGRAM" $1 > $TMPFILE

    # Exchange files
    mv $TMPFILE $1
}


config_insert_bootstrapcode() {
    [ -z $1 ] && {
        echo "error: function needs parameters"
        return 128
    }

    echo "Inserting config bootstrap code into \"$1\"..."


    # set up aliases
    unalias $CONFIGCMD &> /dev/null
    alias $CONFIGCMD="git --git-dir=$DOTFILES_REPOFOLDER --work-tree=$HOME"
    alias $CONFIGCMDSHORTHAND="$CONFIGCMD"

    # write the variables to bashrc.
    echo "### $CONFIG_IDENTIFIER BEGIN ###" >> $1
    alias $CONFIGCMD >> $1
    alias $CONFIGCMDSHORTHAND >> $1
    echo "### set up git completion for the aliases above:" >> $1
    echo "source /usr/share/bash-completion/completions/git" >> $1
    echo "__git_complete $CONFIGCMD _git" >> $1
    echo "__git_complete $CONFIGCMDSHORTHAND _git" >> $1
    echo "# this is our stuff's entry point, code your shit there..." >> $1
    echo "[ -a $SOURCEFILE ] && source $SOURCEFILE" >> $1
    echo "### $CONFIG_IDENTIFIER END ###" >> $1
}


function banner() {
    echo "#################################"
    echo "# $1"
    echo "#################################"
}


are_dotfiles_installed() {
    [ -d $DOTFILES_REPOFOLDER ]
}


already_installed_exit() {
    echo ""
    banner "There is data at [$DOTFILES_REPOFOLDER]. Aborting..."
    return 0
}


function __CONFIGCMD() {
    git --git-dir=$DOTFILES_REPOFOLDER --work-tree=$HOME $*;
}

do_it() {
    clear
    echo ""
    echo "#############################"
    echo "# Installer for .mydotfiles #"
    echo "#############################"
    echo ""
    echo "If you answer yes, I am going to:"
    echo ""
    echo " 1- Clone (bare) [$DOTFILES_REPO] into [$DOTFILES_REPOFOLDER], essentially turning your home into a repository."
    echo " 2- Edit $BASHRC to set up a special git command to operate on that repository."
    echo ""
    echo -n "Do it? (\"y\" or \"n\"): "
    read DOIT
    [ $DOIT != "y" ] && {
        echo "Aborting..."
        exit 1
    }
    echo ""

    # Clone repo
    banner "Cloning git repository..."
    git clone --bare $DOTFILES_REPO $DOTFILES_REPOFOLDER 
    
   [ $? -gt 0 ] && {
        echo "could not checkout git repository, aborting."
        return 1
    } || {

        # Set up repo so that it won't show untracked files.
        __CONFIGCMD config --local status.showUntrackedFiles no
 
        # Set up bashrc with our stuff.
        banner "Setting up $BASHRC with our bootstrap code..."
        config_strip_bootstrapcode $BASHRC
        config_insert_bootstrapcode $BASHRC

        echo "All done!"
    }
}

#Go!
are_dotfiles_installed && already_installed_exit || do_it
