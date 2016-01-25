use strict;
use warnings;

package Footprintless::Command;

use IPC::Open3::Callback::Command qw (
    batch_command
    command
    command_options
    cp_command
    mkdir_command
    pipe_command
    rm_command
    sed_command
    write_command
);

use Exporter qw(import);
our @EXPORT_OK = qw(
    batch_command
    command
    command_options
    cp_command
    mkdir_command
    pipe_command
    rm_command
    sed_command
    tail_command
    write_command
);

sub tail_command {
    IPC::Open3::Callback::Command::wrap(
        {},
        @_,
        sub {
            return "tail -f $_[0]";
        }
    );
}
