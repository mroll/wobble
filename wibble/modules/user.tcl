namespace eval user {
    variable dir

    proc dir { dirname } { variable dir $dirname }

    proc new { name pass } {
        variable dir

        if {![file exists $dir/$name]} {
            file mkdir $dir/$name
            file mkdir $dir/$name/msgs

            passwd update $name pass [passwd::hash $pass]
        }
    }

    namespace ensemble create -subcommands { new dir }
}
