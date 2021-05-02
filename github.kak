def gh-pydef -params 2 %{
    eval %sh{
        tmp=$(mktemp)
        echo "if True:
                $2" > "$tmp"
        vars=$(grep -o 'kak_\w*' $tmp | sort -u)
        echo "
            def -override $1 %{
                eval %sh{
                    # $vars
                    python $tmp \"\$@\"
                }
            }
            hook global KakEnd .* %{ nop %sh{ rm $tmp } }
        "
    }
}

def open-github-xclip %{ open-github %sh{xclip -o} }

gh-pydef 'open-github -params 1' %{
    import re, sys
    addr = sys.argv[1]
    if '//' in addr:
        addr = addr.split('//')[-1]
    try:
        domain, user, repo, blob, branch, *path = addr.split('/')
        print(f"clone ~/repos git@{domain}:{user}/{repo}.git {branch} {'/'.join(path)}")
    except:
        domain, user, repo, *_ = addr.split('/')
        print(f"clone ~/repos git@{domain}:{user}/{repo}.git")
    from pprint import pformat
    print(pformat(locals()), file=sys.stderr)
}

def clone -params 2..4 %{
    eval %sh{
        basedir=$1
        addr=$2
        repo=$(basename $2 .git)
        branch=$3
        path=$4
        tmp=$(mktemp)
        echo "
            #!/bin/sh
            rm $tmp
            mkdir -p $basedir
            cd $basedir
            git clone --recursive $addr
            cd $repo
            send \"cd \$PWD\"
            git checkout $branch
            edit $path
            bash
        " > $tmp
        chmod 755 $tmp
        echo "connect-terminal $tmp"
    }
}

# open-github https://github.com/mawww/kakoune/blob/master/src/main.cc

