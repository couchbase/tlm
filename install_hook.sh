#!/usr/bin/env bash


usage () {
    cat << EOF
Usage: install_hook.sh project [project ...]

Installs a pre-commit hook for the given projects to run

  git clang-format

before each commit.

Once installed, the behaviour of the hook can be customised with

  git config couchbase.clangformat <BEHAVIOUR>

Where the valid options are:

  "warn"   : Block the commit if there are style issues but do not make
             changes to files (default)
  "fix"    : Block the commit, Fix style issues but do not stage the
             resulting changes. Changes can be reviewed with \`git diff\`.
  "stage"  : Block, fix issues and immediately stage the changes
             ready to commit.
  "commit" : Transparently fix style issues and allow the commit.

In all cases except "warn", if clang-format refuses to run
(e.g., if it would modify files with unstaged changes) files
will not be changed and the commit will be refused. Stash any
unstaged changes you do not wish to commit in this case.

EOF
}

install_gcf_hook () {
    proj=$1
    base_dir=$2
    if [ -e $base_dir/.git/hooks/pre-commit ] ; then
        echo "Project $proj already has a pre-commit hook, not overwriting it!"
        return 1
    else
        echo "Installing pre-commit hook in $base_dir/.git/hooks/pre-commit"
        cp $(repo list -fpr tlm)/clang-format-pre-commit-hook $base_dir/.git/hooks/pre-commit
    fi
}


# Show usage if "-h" or no projects given
if [[ ! "${@#-h}" = "$@" ]] || [[ $# = 0 ]] ; then
    usage
    exit
fi

# Very basic check whether prereqs are present
for tool in clang-format git-clang-format ; do
    if [ -z $(which $tool) ] ; then
        echo "$tool not found, please install it, e.g. \`brew install $tool\` and try again."
    fi
done

any_failed=0

for project in $@ ; do
    # Attempt to find the project dir from repo
    project_dir=`repo list -fpr $project`
    if [ -z $project_dir ] ; then
        echo "Project '$project' not found"
        continue
    else
        install_gcf_hook $project $project_dir
        if [ ! $? = 0 ] ; then
            any_failed=1
        fi
    fi
done

exit $any_failed
