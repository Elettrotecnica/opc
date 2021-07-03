ad_library {
    Start monitoring all configured servers at startup.
}

package require topcua
package require json
package require json::write

opc::read_conf

opc::monitor_servers

opc::save_values_reschedule -interval 60m
