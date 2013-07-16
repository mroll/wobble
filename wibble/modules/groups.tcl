
namespace eval wibble {
    namespace eval groups {
		variable groups {}
		variable ugroup {}

	proc data { data } {
	    variable groups

	    foreach line [split [string trim $data] \n] {
		set line [split $line :]
		dict set groups [string trim [lindex $line 0]] [lrange $line 1]
	    }
	    dict with groups {}
	    foreach group [dict keys groups] {
		set list [set $group]

		while { [string index @ $list] >= 0 } {
		    set list [subst -nocommands [string map { # $ } $list]]
		}

		dict set groups $group $line

		foreach user $line {
		    dict lappend ugroup $user $group
		}
	    }
	}
	proc group  { name } { variable groups;  dict? get $groups $name }
	proc ugroup { name } { variable ugroup;  dict? get $ugroup $name }

		variable file   {}
		variable date    0

	proc K { x y } { set x }
	proc file { file } { variable file;    data [read $file] }
	proc read { file } {
	    variable date [file mtime $file]

	    K [::read -nonewline [set fp [open $file]]] [close $fp]
	}
	proc update   { type name args } {
		variable file

	    foreach line [K [::read [set fp [open $file]]] [close $fp; set fp [open $file w]]] {
		set data [split $line :]

		switch $type {
		 user {
		     if { $name in [lindex $data 1] } {
			 foreach user $args {
			     switch [string index $user 0] {
		 	      + {}
			      - {}
			     }
			 }
		     }
		 }
		 group {
		     if { $name eq [string trim [lindex $data 0]] } {
			 foreach user $args {
			     switch [string index $user 0] {
		 	      + {}
			      - {}
			     }
			 }
		     }
		 }
		}

		puts $line $fp
	    }
	    close $fp
	}
	namespace ensemble create -subcommands { data file read update group ugroup }
    }
}
