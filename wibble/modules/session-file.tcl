namespace eval wibble {
    namespace eval session {
        variable sessons
        variable lock

        proc check { request } {
            variable lock
            if { [file isfile lock/[set cook [dict? $request header cookie $::cookie {}]]] } {
                touch lock/$cook
                dict set request session [read $cook]
                return 1
            }

            return 0
        }

        proc login { user state } {
            setcookie state $::cookie [set cook [sha2::hmac [entropy] $user]] -expires +1days
            dict set state request session [write $cook]
        }

        proc logout { response } { }

        proc write { cook } {
            variable lock
            variable sessions

            touch lock/$cook

            return $cook
        }

        proc read { cook } { 
            variable lock
            variable sessions

            return $cook
        }

        namespace ensemble create -subcommands { file check login logout }
    }
}
