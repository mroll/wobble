proc ::wibble::register { state } {
    set name [dict? $state request post user {}]
    set pass [dict? $state request post pass {}]

    user new $name $pass 

    redirect /profile [session login $name $state]
}
