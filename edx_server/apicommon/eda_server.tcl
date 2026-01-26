#!/usr/bin/env tclsh

# eda_server.tcl - TCL TCP Server for EDA Command Execution
#
# This script creates a TCP server that receives TCL commands/scripts from clients,
# executes them, and returns the results to the client.

package require Tcl 8.5

# Function to execute command and capture all output (stdout, stderr, errors)
proc eval_cmd_with_output_capture {cmd} {
    # Create a temporary buffer to capture all output
    variable output_buffer ""
    set output_buffer ""
    
    # Temporarily redefine puts to capture its output
    rename ::puts ::original_puts
    proc ::puts {args} {
        variable output_buffer
        set argc [llength $args]
        
        # Handle different forms of puts
        if {$argc == 1} {
            # puts string
            append output_buffer [lindex $args 0]
            append output_buffer "\n"
        } elseif {$argc == 2} {
            set arg1 [lindex $args 0]
            set arg2 [lindex $args 1]
            if {$arg1 eq "-nonewline"} {
                # puts -nonewline string
                append output_buffer $arg2
            } elseif {[string is integer $arg1]} {
                # puts channelId string - this goes to the original puts
                return [uplevel ::original_puts $args]
            } else {
                # puts channel string
                append output_buffer $arg2
                append output_buffer "\n"
            }
        } elseif {$argc == 3} {
            set arg1 [lindex $args 0]
            if {$arg1 eq "-nonewline"} {
                # puts -nonewline channelId string - this goes to the original puts
                return [uplevel ::original_puts $args]
            }
        } else {
            # For other cases, use original puts
            return [uplevel ::original_puts $args]
        }
    }
    
    # Execute the command and capture its return value along with all output
    if {[catch {uplevel #0 $cmd} result]} {
        # Capture error information completely
        set error_result "$result"
        
        # Include error stack trace if available
        if {[info exists ::errorInfo]} {
            append error_result "\n[::errorInfo]"
        }
        
        # Restore original puts
        rename ::puts ""
        rename ::original_puts ::puts
        
        return [list ERROR $error_result]
    } else {
        # Get the captured output
        variable output_buffer
        set captured_output $output_buffer
        
        # Restore original puts
        rename ::puts ""
        rename ::original_puts ::puts
        
        # Combine captured output with command result
        if {$captured_output eq ""} {
            return [list OK $result]
        } else {
            # If there's captured output, append command result if it's not empty
            if {$result eq ""} {
                return [list OK $captured_output]
            } else {
                return [list OK "$captured_output$result"]
            }
        }
    }
}

# Asynchronous client handler using fileevent
proc async_handle_client {channel client_address client_port} {
    puts "Client connected from $client_address:$client_port"
    
    # Set up error handling for the channel
    fconfigure $channel -buffering line -encoding utf-8
    
    # Send welcome message
    set welcome_msg "EDA Server Ready - Connected from $client_address:$client_port\n"
    catch {puts $channel $welcome_msg}
    
    # Configure fileevent to handle incoming data asynchronously
    fileevent $channel readable [list process_client_data $channel $client_address $client_port]
}

# Process client data asynchronously
proc process_client_data {channel client_address client_port} {
    if {[catch {gets $channel cmd} error] == 0} {
        if {[eof $channel]} {
            puts "Client $client_address:$client_port disconnected"
            close $channel
            return
        }
        
        if {$cmd eq "" || $cmd eq "exit" || $cmd eq "quit"} {
            puts "Client $client_address:$client_port requested disconnect"
            catch {puts $channel "Server closing connection"}
            catch {flush $channel}
            close $channel
            return
        }
        
        # Execute command and prepare response
        set temp_result [eval_cmd_with_output_capture $cmd]
        
        # Send response back to client
        if {[catch {puts $channel $temp_result} send_error]} {
            puts "Error sending response to client $client_address:$client_port: $send_error"
            close $channel
            return
        }
        
        # Flush the channel to ensure data is sent
        catch {flush $channel}
    } else {
        # Handle error in gets command
        if {$error ne ""} {
            puts "Error reading from client $client_address:$client_port: $error"
        }
        close $channel
    }
}

proc start_server {port} {
    set server_socket [socket -server accept_async_connection -myaddr localhost $port]
    puts "EDA TCP Server listening on localhost:$port"
    
    # Keep the server socket identifier as a global variable so it can be accessed later
    global server_socket_id
    set server_socket_id $server_socket
    
    # Keep the server running by ensuring the event loop continues
    # This is now truly non-blocking
    puts "Server started in non-blocking mode. TCL terminal remains available."
}

# Accept asynchronous connections
proc accept_async_connection {channel client_address client_port} {
    # Handle the new client connection asynchronously using fileevent
    async_handle_client $channel $client_address $client_port
}

# Graceful shutdown function
proc stop_server {} {
    global server_socket_id
    if {[info exists server_socket_id]} {
        close $server_socket_id
        unset server_socket_id
        puts "Server stopped."
    } else {
        puts "No server is currently running."
    }
}

# Check if script is run directly (not sourced)
# We'll use a different approach that doesn't evaluate the problematic code when sourced
if {[info exists argv0] && [info exists argc] && $argv0 eq [info script]} {
    # Parse command line arguments when run directly
    if {$argc < 1 || $argc > 2} {
        puts "Usage: $argv0 <port> \\[background\\]"
        puts "Example: $argv0 9999 - Run server in foreground"
        puts "         $argv0 9999 background - Run server in background"
        exit 1
    }

    set port [lindex $argv 0]
    set run_background [expr {$argc == 2 && [lindex $argv 1] eq "background"}]

    puts "Starting EDA Server on port $port..."

    if {$run_background} {
        # Run server in background using after idle
        puts "Running server in background mode..."
        after idle [list start_server $port]
        
        # Keep the Tcl event loop running
        vwait forever
    } else {
        # Start server in the event loop without blocking the terminal
        start_server $port
        puts "TCL terminal remains available for other commands."
        # The event loop will continue running in the background
        # allowing other TCL commands to be entered in the terminal
    }
} else {
    # When sourced in an interactive session, just define procedures
    # and show helpful message
    puts "EDA Server script loaded. Available commands: start_server, stop_server, eval_cmd_with_output_capture"
    puts "To start server: after idle [list start_server port_number]"
}