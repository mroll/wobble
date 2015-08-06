proc wibble::deauthenticate { state } {
    if {[session check [dict? $state request]]} {
        session logout $state
    }
    redirect /login
}
