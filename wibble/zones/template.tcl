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

proc ::wibble::zone::template.tml {state} {
    set options [dict merge { sources .tml extn .tml } [dict get $state options]]

    dict with state request {}; dict with options {}

    if {[file readable $fspath.tml]} {

	set dir [string range $fspath 0 [expr [string length $fspath] - [string length $suffix] -2]]

	foreach d [lrange [split ./$suffix /] 0 end-1] {
	    if { [set cache [tml-cached $dir/$sources if-changed]] ne {} } { eval $cache }
	    append dir / $d
	}

        dict set state response status 200
        dict set state response content [template [tml-cached $fspath$extn cache]]

        sendresponse [dict get $state response]
    }
}

