ad_page_contract {
    Visualize the historic values collected over time.
} {
    {backward_interval:notnull "1 week"}
    {format normal}
}

auth::require_login

set context [list \
		 [_ opc.show_historic_title]]


set rows [list]
db_foreach get_historic {
    select timestamp, values
    from opc_historic_values
    where timestamp >= current_timestamp - cast(:backward_interval as interval)
    order by timestamp desc
} {
    foreach {url data} $values {
	foreach k [dict keys $data] {
	    set keys($k) 1
	}
	lappend rows [list timestamp $timestamp server $url {*}$data]
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

set column_names [lsort [array names keys]]

foreach n $column_names {
    append elements " " [list \
			     $n [list \
				     label $n \
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

set actions [list \
		 "#opc.download_csv#" [export_vars -base [ad_conn url] -entire_form -no_empty {{format csv}}] "#opc.download_csv_title#"]

template::list::create \
    -name history \
    -multirow history \
    -actions $actions \
    -elements $elements

if {$format eq "csv"} {
    template::list::write_csv -name history
    ad_script_abort
}
