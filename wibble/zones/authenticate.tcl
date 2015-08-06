proc wibble::authenticate { state } {
    if { ![session check [dict get $state request]] } {
        set user [dict? $state request post user {}]
        set pass [dict? $state request post pass {}]

        if { [passwd check $user $pass] } {
            nexthandler [session login $user $state]
        } else {
            redirect /login
        }
    }
    nexthandler $state
}
