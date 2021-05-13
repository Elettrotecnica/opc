ad_library {
    OPC Procs
}

namespace eval opc {}

ad_proc -private opc::read_file {
    -binary:boolean
    path
} {
    Slurps a file and returns it as a string
} {
    set mode [expr {$binary_p ? "rb" : "r"}]
    set rfd [open $path $mode]
    set f [read $rfd]
    close $rfd

    return $f
}

ad_proc -private opc::read_conf {
    {-path "conf/monitoring.json"}
} {
    Reads the servers and nodes to be monitored from supplied
    configuration file

    @param path an absolute path, or a relative path that will be
                assumed to start at the package root.
} {
    if {[file pathtype $path] ne "absolute"} {
	set path [acs_root_dir]/packages/opc/$path
    }

    foreach s [::json::many-json2dict [opc::read_file $path]] {
	if {[dict exists $s url]} {
	    nsv_set ::opc::conf [dict get $s url] $s
	} else {
	    ns_log warning "Invalid configuration in file 'path'"
	}
    }
}

ad_proc -private opc::monitor_servers {} {
    Monitors all servers or a single server. Each server will be
    monitored in an own scheduled procedure.

    @param server_id server to monitor, all servers will be monitored
                     when not specified.
} {
    foreach {u s} [nsv_array get ::opc::conf] {
	ns_log notice "Schedule monitoring of server '$u'"
	ad_schedule_proc -thread t -once t 1 opc::monitor -conf $s
    }
}

ad_proc -private opc::check_connection {} {
    Checks the connection.
} {
    uplevel {
	if {[catch {opcua run C 0}]} {
	    # this most likely is the server shutting down
	    set disconnected 1
	    opcua destroy C
	}
	after 1000 opc::check_connection
    }
}

ad_proc -private opc::monitor {
    -conf:required
} {
    Monitors a server, meant to be scheduled.
} {
    set monitored_nodes [dict get $conf nodes]

    if {[llength $monitored_nodes] == 0} {
	ns_log warning "OPC Server '$url' - No nodes to monitor, exiting..."
	return
    }

    set url [dict get $conf url]
    set interval [dict get $conf interval]

    set use_encryption_p [expr {
				[dict exists $conf client_cert] ||
				[dict exists $conf client_key]
			    }]
    if {$use_encryption_p} {
	set client_cert [opc::read_file -binary [dict get $conf client_cert]]
	set client_key [opc::read_file -binary [dict get $conf client_key]]
    } else {
	set client_cert ""
	set client_key ""
    }

    ns_log warning "OPC Server '$url' - Start monitoring..."

    while {true} {
	# create client
	opcua new client C

	if {$use_encryption_p} {
	    # Add the encryption certificates to the clients, when
	    # provided
	    ns_log warning "OPC Server '$url' - We use encryption. Setting certificates."
	    opcua cert C $client_cert $client_key
	} else {
	    ns_log warning "OPC Server '$url' - We do not use encryption."
	}

	# connect to server
	opcua connect C $url

	ns_log warning "OPC Server '$url' - Creating subscription, interval='$interval'"
	set sub [opcua subscription C new 1 $interval]

	# Every time one of the monitored variable changes, we send
	# the updated value to a websocket subscription named after
	# the server URL and the node.
	# We also take note of the current value in an nsv.
	proc ws_send {url node data} {
	    if {[dict exists $data value]} {
		set value [dict get $data value]
	    } else {
		set value $data
	    }
	    nsv_dict set ::opc::status $url $node $value
	    set json [::json::write object \
			  url [::json::write string $url] \
			  node [::json::write string $node] \
			  value [::json::write string $value]]
	    # ns_log warning "Sending message on subscription 'opc-events':\n$json"
	    ::ws::multicast opc-events [ns_connchan wsencode -opcode text $json]
	}

	set i 0
	foreach node_id $monitored_nodes {
	    proc callback_${i} {data} [subst -nocommands {
		ws_send "${url}" "${node_id}" \$data
	    }]
	    set mon [opcua monitor C new $sub data callback_${i} $node_id]
	    ns_log warning "OPC Server '$url' - Monitoring node '$node_id', monitor=$mon"
	    incr i
	}

	opc::check_connection

	vwait disconnected

	ns_log warning "OPC Server '$url' - Reconnecting in 10s..."
	ns_sleep 10
    }
}
