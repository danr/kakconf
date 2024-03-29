def name -params 2 %{
    def -override %arg{2} -docstring "exec %arg{1}" "exec -no-hooks %arg{1}"
}
# from normal.cc
name h          move-left
name j          move-down
name k          move-up
name l          move-right
name <left>     move-left
name <down>     move-down
name <up>       move-up
name <right>    move-right
name H          extend-left
name J          extend-down
name K          extend-up
name L          extend-right
name t          select-to-next-character
name f          select-to-next-character-included
name T          extend-to-next-character
name F          extend-to-next-character-included
name <a-t>      select-to-previous-character
name <a-f>      select-to-previous-character-included
name <a-T>      extend-to-previous-character
name <a-F>      extend-to-previous-character-included
name d          erase-selected-text
name <a-d>      erase-selected-text-without-yanking
name c          change-selected-text
name <a-c>      change-selected-text-without-yanking
name i          insert-before-selected-text
name I          insert-at-line-begin
name a          insert-after-selected-text
name A          insert-at-line-end
name o          insert-on-new-line-below
name O          insert-on-new-line-above
name r          replace-with-character
name <a-o>      add-a-new-empty-line-below
name <a-O>      add-a-new-empty-line-above
name g          go-to-location
name G          extend-to-location
name v          move-view
name V          move-view-locked
name y          yank-selected-text
name p          paste-after-selected-text
name P          paste-before-selected-text
name <a-p>      paste-every-yanked-selection-after-selected-text
name <a-P>      paste-every-yanked-selection-before-selected-text
name R          replace-selected-text-with-yanked-text
name <a-R>      replace-selected-text-with-every-yanked-text
name s          select-regex-matches-in-selected-text
name S          split-selected-text-on-regex-matches
name <a-s>      split-selected-text-on-line-ends
name <a-S>      select-selection-boundaries
name .          repeat-last-insert-command
name <a-.>      repeat-last-object-select/character-find
name '%'        select-whole-buffer
name :          enter-command-prompt
name |          pipe-each-selection-through-filter-and-replace-with-output
name <a-|>      pipe-each-selection-through-command-and-ignore-output
name !          insert-command-output
name <a-!>      append-command-output
name <space>    remove-all-selections-except-main
name <a-space>  remove-main-selection
name ';'        reduce-selections-to-their-cursor
name '<a-;>'    swap-selections-cursor-and-anchor
name <a-:>      ensure-selection-cursor-is-after-anchor
name <a-m>      merge-consecutive-selections
name w          select-to-next-word-start
name e          select-to-next-word-end
name b          select-to-previous-word-start
name W          extend-to-next-word-start
name E          extend-to-next-word-end
name B          extend-to-previous-word-start
name <a-w>      select-to-next-WORD-start
name <a-e>      select-to-next-WORD-end
name <a-b>      select-to-previous-WORD-start
name <a-W>      extend-to-next-WORD-start
name <a-E>      extend-to-next-WORD-end
name <a-B>      extend-to-previous-WORD-start
name <a-l>      select-to-line-end
name <a-L>      extend-to-line-end
name <a-h>      select-to-line-begin
name <a-H>      extend-to-line-begin
name x          select-line
name X          extend-line
name <a-x>      extend-selections-to-whole-lines
name <a-X>      crop-selections-to-whole-lines
name m          select-to-matching-character
name M          extend-to-matching-character
name /          select-next-given-regex-match
name ?          extend-with-next-given-regex-match
name <a-/>      select-previous-given-regex-match
name <a-?>      extend-with-previous-given-regex-match
name n          select-next-current-search-pattern-match
name N          extend-with-next-current-search-pattern-match
name <a-n>      select-previous-current-search-pattern-match
name <a-N>      extend-with-previous-current-search-pattern-match
name *          set-search-pattern-to-main-selection-content
name <a-*>      set-search-pattern-to-main-selection-content-do-not-detect-words
name u          undo
name U          redo
name <a-u>      move-backward-in-history
name <a-U>      move-forward-in-history
name <a-i>      select-inner-object
name <a-a>      select-whole-object
name [          select-to-object-start
name ]          select-to-object-end
name {          extend-to-object-start
name }          extend-to-object-end
name <a-[>      select-to-inner-object-start
name <a-]>      select-to-inner-object-end
name <a-{>      extend-to-inner-object-start
name <a-}>      extend-to-inner-object-end
name <a-j>      join-lines
name <a-J>      join-lines-and-select-spaces
name <a-k>      keep-selections-matching-given-regex
name <a-K>      keep-selections-not-matching-given-regex
name $          pipe-each-selection-through-shell-command-and-keep-the-ones-whose-command-succeed
name <          deindent
name >          indent
name <a-gt>     indent-including-empty-lines
name <a-lt>     deindent-not-including-incomplete-indent
name <tab>      jump-forward-in-jump-list
name <c-o>      jump-backward-in-jump-list
name <c-s>      push-current-selections-in-jump-list
name %(')       rotate-main-selection-forward
name %(<a-'>)   rotate-main-selection-backward
name %(<a-">)   rotate-selections-content
name q          replay-recorded-macro
name Q          start-or-end-macro-recording
name <esc>      end-macro-recording
name `          convert-to-lower-case-in-selections
name ~          convert-to-upper-case-in-selections
name <a-`>      swap-case-in-selections
name &          align-selection-cursors
name <a-&>      copy-indentation
name @          convert-tabs-to-spaces-in-selections
name <a-@>      convert-spaces-to-tabs-in-selections
name C          copy-selection-on-next-lines
name <a-C>      copy-selection-on-previous-lines
name ,          user-mappings
name <pageup>   scroll-one-page-up
name <pagedown> scroll-one-page-down
name <c-b>      scroll-one-page-up
name <c-f>      scroll-one-page-down
name <c-u>      scroll-half-a-page-up
name <c-d>      scroll-half-a-page-down
name z          restore-selections-from-register
name <a-z>      combine-selections-from-register
name Z          save-selections-to-register
name <a-Z>      combine-selections-to-register
name <c-l>      force-redraw
