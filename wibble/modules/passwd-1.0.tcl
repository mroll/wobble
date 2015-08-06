package provide passwd 1.0

package require sha1

namespace eval passwd {
    variable passwd {}
    variable file   {}
    variable date    0
    variable fields { passwd email }

    proc hash { value } { sha1::sha1 -hex $value }

    proc data { data } {
        variable passwd

        foreach line [split [string trim $data] \n] {
            lassign $line name pass
            dict set passwd $name pass $pass
        }
    }

    proc check { user pass } {
        variable passwd
        variable file
        variable date

        if { $date && $date < [::file mtime $file] } { read $file }

        expr { $user != {} && $pass != {} && [hash $pass] eq [dict? $passwd $user pass] }
    }

    proc file { filename } { 
        variable file $filename
        if {[::file exists $filename]} { data [read $file] }
    }

    proc read { file } {
        variable date [::file mtime $file]

        K [::read -nonewline [set fp [open $file]]] [close $fp]
    }

    proc write { passwd file } {
        set fp [open $file w]
        dict for { name values } $passwd {
            dict with values {}

            puts $fp "$name $pass"
        }
        close $fp
    }

    proc update   { name field value } {
        variable passwd
        variable file

        dict set passwd $name $field $value
        puts [dict? $passwd $name $field]
        write $passwd $file
    }

    namespace ensemble create -subcommands { data file read write update check }
}
