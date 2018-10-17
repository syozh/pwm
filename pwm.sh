#!/usr/bin/env bash

pwmdir=~/.pwm
pwmfile=~/.pwm/pwm.gpg
template=/dev/shm/pwm_XXXXXXXX.tmp
editor=vim

usage() {
    cat <<- EOF
	Usage: pwm COMMAND ARG(S)
	  Commands:
	    l REGEX - list entries
	    e       - edit
	EOF
    exit 1
}

die() {
    echo >&2 "$@"
    exit 1
}

if [ $# -eq 0 ]; then
    usage
fi

if ! [ -d "$pwmdir" ]; then
    mkdir "$pwmdir"
fi

read -p "Enter password: " -r -s pwm
echo

gpgopt="-q --passphrase $pwm"
gpgdec="gpg -d $gpgopt"
gpgenc="gpg -c $gpgopt --yes"

case $1 in
    l)
        if [ $# -lt 2 ]; then
            usage
        fi
        if ! [ -r "$pwmfile" ]; then
            die "Error: unable to access pwm-file: $pwmfile"
        fi
        $gpgdec "$pwmfile" | grep -i --color=always -G "$2"
        ;;
    e)
        tmpfile=$(mktemp -u "$template")
        remove_tmpfile() {
            shred -zu "$tmpfile"
        }
        trap remove_tmpfile INT TERM EXIT
        if [ -r "$pwmfile" ]; then
            cp -f "$pwmfile" "$pwmfile".bak
            $gpgdec -o "$tmpfile" "$pwmfile"
        else
            touch "$tmpfile"
        fi
        $editor "$tmpfile"
        $gpgenc -o "$pwmfile" "$tmpfile"
        ;;
    *)
        usage
        ;;
esac
