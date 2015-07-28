proc wibble::dotaccess { path user } {
	set ugroups [groups $user]
        lappend ugroups $user

	while { $path ne "." } {

	    if { [file isfile $path/.access] } {
		set access [regsub -all {#.*$} [cat $path/.access] {}]
		foreach group 
		return $mode
	    }
	    set path [file directory $path]
	}

	return denied
}

namespace eval wibble {
    namespace eval access {
		variable access {}
		variable file   {}
		variable date    0

        proc data { data } {
            variable passwd

            foreach line [split $data \n] {
                lassign $line name pass email
                dict set passwd $name passwd $pass
                dict set passwd $name email  $email
            }
        }

        proc file { file } { variable file;    data [read $file] }

        proc read { file } {
            variable date [file mtime $file]

            K [::read -nonewline [set fp [open $file]]] [close $fp]
        }

        proc write { passwd file } {
            set fp [open $file w]
            dict for { name values } $passwd {
                dict with values {}

                puts $fp "[format %10.10s $name] $passwd $email"
            }
            close $fp
        }

        proc update   { name option value } {
                variable passwd
            variable file

            dict set passwd $name $option $value
            write $passwd $file
        }

        proc check { user pass } {
            puts here
            variable passwd
            variable file
            variable date

            if { $date && $date < [file mtime $file] } { read $file }

            if { $user != {} && $pass != {} } {
                set pass [wibble::hmac $pass]
                return [expr $pass eq [dict? $passwd $user passwd]]
            }
        }

        namespace ensemble create -subcommands { data file read write update check }
    }
}
