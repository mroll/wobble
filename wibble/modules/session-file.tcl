namespace eval wibble {
    namespace eval session {
        variable lock
        variable sessions {}

        proc check { request } {
            variable lock
            if { [file isfile lock/[set cook [dict? $request header cookie $::cookie {}]]] } {
                touch lock/$cook
                dict set request session $cook
                return 1
            }

            return 0
        }

        proc login { user state } {
            setcookie state $::cookie [set cook [sha2::hmac [entropy] $user]] -expires +1days
            dict set state request header cookie $::cookie [list {} [write $user $cook]]
        }

        proc logout { state } { file delete lock/[getcookie $state] }

        proc write { user cook } {
            variable sessions

            echo $user >> lock/$cook
            dict set sessions $cook user $user

            return $cook
        }

        proc read { file } { K [::read -nonewline [set fp [open $file]]] [close $fp] }

        proc user { cook } { variable sessions; return [dict? $sessions $cook user] }

        proc getcookie { state } { return [dict? $state request header cookie $::cookie {}] }

        proc load { } {
            variable sessions
            foreach f [glob -nocomplain -directory lock *] {
                dict set sessions [last [split $f /]] user [read $f] 
            }
        }

        namespace ensemble create -subcommands { file check login logout user getcookie load }
    }
}
