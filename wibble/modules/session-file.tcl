namespace eval wibble {
    namespace eval session {
        variable sessons
        variable lock

        proc check { request } {
            variable lock
            if { [file isfile lock/[set cook [dict? $request header cookie $::cookie {}]]] } {
                touch lock/$cook
                dict set request session [wibble::session read $cook]
                return 1
            }

            return 0
        }

        proc login { user request response } {
            setcookie response $::cookie [set cook [hmac [entropy]]] -expires +1days
            dict set request session [write [list user $user]]
            # return [dict? $request]
        }

        proc logout { responce } {
        }

        proc write {} {
            variable lock
            variable sessions

            return [set $sessions($cook) ...]
        }

        proc read {} { 
            variable lock
            variable sessions

            set sessions($cook) ...
        }

        namespace ensemble create -subcommands { file check login logout }
    }
}
