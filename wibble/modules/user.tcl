namespace eval user {
    variable dir

    proc dir { dirname } { variable dir $dirname }

    proc new { name pass } {
        variable dir

        if {![file exists $dir/$name]} {
            file mkdir $dir/$name
            file mkdir $dir/$name/msgs

            echo "$name:$pass" >> passwd::file
        }
    }

    namespace ensemble create -subcommands { new dir }
}
