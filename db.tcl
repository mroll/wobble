
class create db-list {
    variable types

    method attach { dbstr } {
	foreach type $types {
	    try { set db [$type create $dbstr]
	    } on error message { continue }

	    return $db
	}

	error "no db opened from : $dbstr"
    }

    method type { type } { lappend types $type }
}

db-list create db-registery

db-registery register db-flatfile
db-registery register db-sqlite
db-registery register db-tdbc

set db [db-registery attach "db-attach-string"]


class create db-flatfile {
    variable directory

    constructor { Directory } {
	if { ![file isdirectory $Directory] } {
	    error "db-flatfile : not a directory : $Directory"
	}
	set directory $Directory
    }

    method table { name columns } { db-flatfile-table create $directory/$name $columns }
}

class create db-flatfile-table {
    variable table columns

    constructor { name file columns } {
	set table []
    }
    method set { key args } {
    	switch [llength $args] {
	 1 { return [lindex [dict table get $key] [lsearch $columns [lindex $args 0]]]  }
	 2 { 
	    set  entry [dict $table get $key]
	    lset entry [lsearch $columns [lindex $args 0]] $[lindex $args 1]
	    dict $table set $key $entry

	    write
	 }
	}
    }
}

db create DB /data/xxx/db/

set passwd [DB table passwd { passwd email }]

set pass [$passwd set john passwd]

