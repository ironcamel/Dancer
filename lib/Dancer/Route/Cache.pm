package Dancer::Route::Cache;

use strict;
use warnings;
use vars '$VERSION';

use Dancer::Config 'setting';
use Dancer::Error;

$VERSION = '0.01';

sub new {
    my ( $class, @args ) = @_;

    my $self = bless {}, $class;

    if (@args) {
        scalar @args % 2 == 0 or die "Illegal number of options\n";

        foreach my $idx ( 0, 2 ) {
            $args[$idx] || last;
            my $arg = $args[$idx];
            my $val = $args[ $idx + 1 ];

            if ( $arg eq 'size_limit' ) {
                $self->size_limit($val);
            } elsif ( $arg eq 'path_limit' ) {
                $self->path_limit($val);
            } else {
                die "Incorrect key: $arg\n";
            }
        }
    }

    return $self;
}

sub path_limit {
    my ( $self, $limit ) = @_;
    if ($limit) {
        $self->{'path_limit'} = $limit;
    }

    return $self->{'path_limit'};
}

sub size_limit {
    my ( $self, $limit ) = @_;
    if ($limit) {
        $self->{'size_limit'} = $self->parse_size($limit);
    }

    return $self->{'size_limit'};
}

sub parse_size {
    my ( $self, $size ) = @_;

    if ( $size =~ /^(\d+)(K|M|G)?$/ ) {
        my $base = $1;
        if ( my $ext = $2 ) {
            $ext eq 'K' and return $base * 1024 ** 1;
            $ext eq 'M' and return $base * 1024 ** 2;
            $ext eq 'G' and return $base * 1024 ** 3;
        }

        return $base;
    }
}

sub route_from_path {
    my ( $self, $method, $path ) = @_;

    $method && $path
        or die "Missing method or path";

    return $self->{'cache'}{$method}{$path} || undef;
}

sub store_route {
    my ( $self, $method, $path, $route ) = @_;

    $method && $path && $route
        or die "Missing method, path or route";

    $self->{'cache'}{$method}{$path} = $route;
}

1;

__END__

=head1 NAME

Dancer::Route::Cache - route caching mechanism for L<Dancer>

=head1 SYNOPSIS



=head1 DESCRIPTION

When L<Dancer> first starts, it has to compile a regexp list of all the routes.
Then, on each request it goes over the compiled routes list and tries to compare
the requested path to a route.

A major drawback is that L<Dancer> has to go over the matching on every request,
which (especially on CGI-based applications) can be very time consuming.

The caching mechanism allows to cache some requests to specific routes (but
B<NOT> specific results) and run those routes on a specific path. This allows us
to speed up L<Dancer> quite a lot.

=head1 METHODS/SUBROUTINES

=head2 new(@args)

Creates a new route cache object.

    my $cache = Dancer::Route::Cache->new(
        path_limit => 100,   # only 100 paths will be cached
        size_limit => '30M', # max size for cache is 30MB
    );

Please check the C<ATTRIBUTES> section below to learn about the arguments for
C<new()>.

=head2 route_from_path($path)

Fetches the route from the path in the cache.

=head2 store_route( $path => $store )

Stores the route in the cache according to the path.

For developers: the reason we're using an object for this and not directly using
the registry hash is because we need to enforce the limits.

=head2 parse_size($size)

Parses the size wanted to bytes. It can handle Kilobytes, Megabytes or
Gigabytes.

B<NOTICE:> handles bytes, not bits!

    my $bytes = $cache->parse_size('30M');

    # doesn't need an existing object
    $bytes = Dancer::Route::Cache->parse_size('300G'); # works this way too

=head1 ATTRIBUTES

=head2 size_limit($limit)

Allows to set a size limit of the cache.

Returns the limit (post-set).

    $cache->size_limit('10K');      # sets limit
    my $limit = $cache->size_limit; # gets limit

=head2 path_limit($limit)

A path limit. That is, the amount of paths that whose routes will be cached.

Returns the limit (post-set).

    $cache->path_limit('100');      # sets limit
    my $limit = $cache->path_limit; # gets limit

=head1 AUTHOR

Sawyer X

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
