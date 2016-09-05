use strict;
use warnings;

package Footprintless::App::Action;

use Footprintless::App -ignore;

sub new {
    return bless({}, shift);
}

sub opt_spec {
    return ();
}

sub usage_desc {
    return '';
}

sub validate_args {}

1;

__END__

=for Pod::Coverage new execute opt_spec usage_desc validate_args
