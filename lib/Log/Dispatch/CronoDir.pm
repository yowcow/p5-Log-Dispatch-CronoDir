package Log::Dispatch::CronoDir;
use 5.008001;
use strict;
use warnings;
use parent qw(Log::Dispatch::Output);

our $VERSION = "0.01";

use File::Path qw(make_path);
use Params::Validate qw(validate SCALAR BOOLEAN);
use Scalar::Util qw(openhandle);

sub new {
    my ($proto, %args) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    $self->_basic_init(%args);
    $self->_init(%args);
    $self;
}

sub _init {
    my $self = shift;
    my %args = validate(
        @_,
        {   dirname_pattern => { type => SCALAR },
            filename        => { type => SCALAR },
            mode            => {
                type    => SCALAR,
                default => '>>',
            },
            binmode => {
                type     => SCALAR,
                optional => 1,
            },
            autoflush => {
                type    => BOOLEAN,
                default => 1,
            },
        }
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::Dispatch::CronoDir - Log dispatcher for logging to time-based directories

=head1 SYNOPSIS

    use Log::Dispatch::CronoDir;

    my $log = Log::Dispatch::CronoDir->new(
        dirname_pattern => '/var/log/%Y/%m/%d',
        filename        => 'output.log',
        mode            => '>>:unix',
        binmode         => ':utf8',
        autoflush       => 1,
    );

    # Write log to file `/var/log/2000/01/01/output.log`
    $log->log(level => 'error', message => 'Something has happened');

=head1 DESCRIPTION

Log::Dispatch::CronoDir is a file log dispatcher with time-based directory management.

=head1 METHODS

=head2 new(Hash %args)

Creates an instance.  Accepted hash keys are:

=over 4

=item dirname_pattern => Str

Directory name pattern where log files to be written to.
POSIX strftime's conversion characters C<%Y>, C<%m>, and C<%d> are currently accepted.

=item filename => Str

Log file name to be written in the directory.

=item mode => Str

Mode to be used when opening a file handle.  Default: ">>"

=item binmode => Str

Binmode to specify with C<binmode>.  Default: None

=item autoflush => Bool

Enable or disable autoflush.  Default: 1

=back

=head2 log(Hash %args)

Writes log to file.

=over 4

=item level => Str

Log level.

=item message => Str

A message to write to log file.

=back

=head1 SEE ALSO

L<Log::Dispatch>

=head1 LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yowcow@cpan.orgE<gt>

=cut

