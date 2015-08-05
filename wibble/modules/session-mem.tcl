
namespace eval wibble {
    namespace eval session {
        variable sessons

        proc check { request } {
            variable sessions

            if { [info exists sessions([set cook [dict? $request header cookie $::cookie {}]])] } {
            dict set request session $sessions($cook)
            }
        }

        proc login { user request responce } {
            setcookie response $::cookie [set cook [hmac [entropy]]] -expires +1days
            dict set request session [write [list user $user]]
        }

        proc logout { responce } {
        }

        proc value { args } {
            variable sessions
            foreach { name value } { dict set sessions($cook) $name $value }
        }

        namespace ensemble create -subcommands { check login logout value }
    }
}
