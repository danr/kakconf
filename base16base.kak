
try %{
    decl str base00
    decl str base01
    decl str base02
    decl str base03
    decl str base04
    decl str base05
    decl str base06
    decl str base07
    decl str base08
    decl str base09
    decl str base0A
    decl str base0B
    decl str base0C
    decl str base0D
    decl str base0E
    decl str base0F
}

set global base00 black
set global base01 bright-green
set global base02 bright-yellow
set global base03 bright-black
set global base04 bright-blue
set global base05 white
set global base06 bright-magenta
set global base07 bright-white
set global base08 red
set global base09 bright-red
set global base0A yellow
set global base0B green
set global base0C cyan
set global base0D blue
set global base0E magenta
set global base0F bright-cyan

## code
face global value              "%opt{base09},%opt{base00}"
face global variable           "%opt{base0B},%opt{base00}"
face global type               "%opt{base0A},%opt{base00}"
face global identifier         "%opt{base08},%opt{base00}"
face global string             "%opt{base0B},%opt{base00}"
face global keyword            "%opt{base0E},%opt{base00}"
face global operator           "%opt{base0F},%opt{base00}"
face global attribute          "%opt{base0C},%opt{base00}"
face global comment            "%opt{base0C},%opt{base00}"
face global meta               "%opt{base0D},%opt{base00}"
face global builtin            "%opt{base0D},%opt{base00}+b"
face global code               "%opt{base0C},%opt{base00}+b"

## markup
face global title              "%opt{base0D},%opt{base00}+b"
face global header             "%opt{base0A},%opt{base00}+b"
face global bold               "%opt{base0A},%opt{base00}+b"
face global italic             "%opt{base0E},%opt{base00}"
face global mono               "%opt{base0B},%opt{base00}"
face global block              "%opt{base0C},%opt{base00}"
face global link               "%opt{base09},%opt{base00}"
face global bullet             "%opt{base08},%opt{base00}"
face global list               "%opt{base08},%opt{base00}"

## builtin
face global Default            "%opt{base05},%opt{base00}"
face global PrimaryCursor      "%opt{base00},%opt{base0E}"
face global PrimaryCursorEol   "%opt{base00},%opt{base08}"
face global PrimarySelection   "%opt{base00},%opt{base0C}"
face global SecondaryCursor    "%opt{base00},%opt{base05}"
face global SecondaryCursorEol "%opt{base00},%opt{base07}"
face global SecondarySelection "%opt{base00},%opt{base04}"
face global LineNumbers        "%opt{base02},%opt{base00}"
face global LineNumberCursor   "%opt{base0A},%opt{base00}"
face global MenuForeground     "%opt{base00},%opt{base0C}"
face global MenuBackground     "%opt{base05},%opt{base01}"

face global MenuInfo           "%opt{base01}" # ??

face global Information        "%opt{base0C},%opt{base01}"
face global Error              "%opt{base00},%opt{base08}"
face global StatusLine         "%opt{base04},%opt{base01}"
face global StatusLineMode     "%opt{base0B},%opt{base01}"
face global StatusLineInfo     "%opt{base0D},%opt{base01}"
face global StatusLineValue    "%opt{base0C},%opt{base01}"
face global StatusCursor       "%opt{base00},%opt{base05}"
face global Prompt             "%opt{base0D},%opt{base01}"
face global MatchingChar       "%opt{base0E},%opt{base02}"
face global BufferPadding      "%opt{base03},%opt{base00}"

