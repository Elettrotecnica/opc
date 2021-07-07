ad_page_contract {
    Visualize the historic values collected over time.
} {
    {years:naturalnum,notnull 0}
    {months:naturalnum,notnull 0}
    {weeks:naturalnum,notnull 1}
    {days:naturalnum,notnull 0}
    {format normal}
}

auth::require_login

set context [list \
		 [_ opc.show_historic_title]]

set column_names {}
foreach {url conf} [nsv_array get ::opc::conf] {
    foreach key [dict get $conf nodes] {
	set key [lindex [split $key .] end]
	regsub -all {[^\w]} $key {_} key
	lappend column_names $key
    }
}

set rows [list]
db_foreach get_historic {
    select timestamp, values
    from opc_historic_values
    where timestamp >= current_timestamp - cast(
      :years || ' years ' || :months || ' months ' || :weeks || ' weeks ' || :days || ' days'
      as interval
      )
    order by timestamp desc
} {
    foreach {url data} $values {
	set row [list timestamp $timestamp server $url {*}$data]
	foreach {key value} $data {
	    set key [lindex [split $key .] end]
	    regsub -all {[^\w]} $key {_} key
	    lappend row $key $value
	}
	lappend rows $row
    }
}

set elements {
    timestamp {
	label "Timestamp"
    }
    server {
	label "Server"
    }
}

foreach n $column_names {
    regsub -all {_} $n { } label
    append elements " " [list \
			     $n [list \
				     label $label \
				    ]]
}

template::multirow create history timestamp server {*}$column_names
foreach row $rows {
    set values {}
    foreach n $column_names {
	if {[dict exists $row $n]} {
	    lappend values [dict get $row $n]
	} else {
	    lappend values ""
	}
    }
    template::multirow append history [dict get $row timestamp] [dict get $row server] {*}$values
}

set csv_url [export_vars -base [ad_conn url] -entire_form -no_empty {{format csv}}]

template::list::create \
    -name history \
    -multirow history \
    -elements $elements

if {$format eq "csv"} {
    template::list::write_csv -name history
    ad_script_abort
}
