# Execute templates.
#
proc tml-cached { file what } {
    variable TML_CACHE

    set cache {}

    if { [file exists $file] } {
	set mtime [file mtime $file]

	if { ![info exists TML_CACHE($file)] || [lindex $TML_CACHE($file) 0] < $mtime } {
	    set cache [::wibble::cat $file]
	    set TML_CACHE($file) [list $mtime $cache]
	} else {
	    if { $what eq "cache" } {
		set cache [lindex $::TML_CACHE($file) 1]
	    }
	}
    }

    return $cache
}

proc ::wibble::template { state } {
    dict with state request {}; dict with state options {}
    if {[file readable $fspath.tmpl] && (![file readable $fspath.script] \
        || [file mtime $fspath.script] < [file mtime $fspath.tmpl])} {
            set chan [open $fspath.tmpl]
            set tmpl [read $chan]
            chan close $chan
            set chan [open $fspath.script w]
            chan puts -nonewline $chan\
            [compiletemplate "dict set state response content" $tmpl]
            chan close $chan
    }
}
