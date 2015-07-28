# Rewrite directory requests to search for an indexfile.
#

proc ::wibble::indexfile {state} {
    set indexfile index.html
    dict with state request {}; dict with state options {}
    if {[file isdirectory [dict? $state options fspath]]} {
        if {[string index $path end] ne "/"} {
            append path /
        }
        set newstate $state
        dict set newstate request path $path$indexfile
        nexthandler $newstate $state
    }
}
