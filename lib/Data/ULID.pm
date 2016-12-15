package Data::ULID;

use strict;
use warnings;

our $VERSION = '0.1';

use base qw(Exporter);
our @EXPORT_OK = qw/ulid binary_ulid ulid_date/;
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

use Time::HiRes qw/time/;
use Math::BigInt lib => 'GMP', upgrade => 'Math::BigFloat';
use Math::BigFloat;
use Math::Random::Secure qw/irand/;
use Encode::Base32::GMP qw/encode_base32 decode_base32/;
use DateTime;

# The first two of these should only be necessary on 32-bit systems.
use constant BI_2_32 => Math::BigInt->new('4294967296');
use constant BI_2_48 => Math::BigInt->new('281474976710656');
use constant BI_2_64 => Math::BigInt->new('18446744073709551616');

sub ulid {
    my ($ts, $rand) = _ulid(shift);
    return sprintf('%010s%016s', encode_base32($ts) , encode_base32($rand));
}

sub binary_ulid {
    my ($ts, $rand) = _ulid(shift);
    return _pack($ts, $rand);
}

sub ulid_date {
    my $ulid = shift;
    die "ulid_date() needs a normal or binary ULID as parameter" unless $ulid;
    my ($ts, $rand) = _ulid($ulid);
    $ts = _bint($ts);
    return DateTime->from_epoch(epoch=>$ts / 1000);
}

sub _ulid {
    my $arg = shift;
    my $ts;
    if ($arg && $arg->isa('DateTime')) {
        $ts = int($arg->hires_epoch * 1000);
    }
    elsif ($arg && length($arg) == 16) {
        return _unpack($arg);
    }
    elsif ($arg) {
        $arg = _normalize($arg);
        die "Invalid ULID supplied: wrong length" unless length($arg) == 26;
        my ($ts_part, $rand_part) = ($arg =~ /^(.{10})(.{16})$/);
        return (decode_base32($ts_part), decode_base32($rand_part));
    }
    $ts ||= int(time() * 1000);
    my $rand = _bigrand();
    return ($ts, $rand);
}

sub _normalize {
    my $s = shift;
    $s = uc($s);
    $s =~ s/[^0123456789ABCDEFGHJKMNPQRSTVWXYZ]//g;
    return $s;
}

sub _pack {
    my ($ts, $rand) = @_;
    my $t1 = int($ts / 2**16);
    my $t2 = $ts % 2**16;
    my $r1 = $rand >> 64;
    my $r2 = ($rand % BI_2_64) >> 32;
    my $r3 = $rand % BI_2_32;
    return pack('NnnNN', $t1, $t2, $r1, $r2, $r3);
}

sub _unpack {
    my ($t1, $t2, $r1, $r2, $r3) = unpack('NnnNN', shift);
    my $ts = _bint($t1) * 2**16 + $t2;
    my $rand = _bint($r1) * BI_2_64 + _bint($r2) * BI_2_32 + _bint($r3);
    return ($ts, $rand);
}

sub _bint { Math::BigInt->new(shift) }

sub _bigrand {
    # 80-bit random bigint.
    # Note that irand() is not reliable for bounds above 2**32.
    my $r1 = _bint(irand(2**32));
    my $r2 = _bint(irand(2**32));
    my $r3 = _bint(irand(2**16));
    return ($r1 * BI_2_48) + ($r2 * 2**16) + $r3;
}

1;

__END__

=pod

=head1 NAME

Data::ULID - Universally Unique Lexicographically Sortable Identifier

=head1 SYNOPSIS

 use Data::ULID qw/ulid binary_ulid ulid_date/;

 my $id = ulid();  # e.g. 01ARZ3NDEKTSV4RRFFQ69G5FAV
 my $binary_id = binary_ulid($id);
 my $datetime_obj = ulid_date($id);  # e.g. 2016-06-13T13:25:20

=head1 DESCRIPTION

=head2 Background

This is an implementation in Perl of the ULID identifier type introducted by
Alizain Feerasta. The original implementation (in Javascript) can be found at
L<https://github.com/alizain/ulid>.

ULIDs have several advantages over UUIDs in many contexts. The advantages
include:

=over

=item *

Lexicographically sortable

=item *

The canonical representation is shorter than UUID (26 vs 36 characters)

=item *

Case insensitve and safely chunkable.

=item *

URL-safe

=item *

Timestamp can always be easily extracted if so desired.

=back

=head2 Canonical representation

The canonical representation of a ULID is a 26-byte, base32-encoded string
consisting of (1) a 10-byte timestamp with millisecond-resolution; and (2) a
16-byte random part.

Without paramters, the C<ulid()> function returns a new ULID in the canonical
representation, with the current time (up to the nearest millisecond) in the
timestamp part.

 $ulid = ulid();

Given a DateTime object as parameter, the function will set the timestamp part
based on that:

 $ulid = ulid($datetime_obj);

Given a binary ULID as parameter, it returns the same ULID in canonical
format:

 $ulid = ulid($binary_ulid);

=head2 Binary representation

The binary representation of a ULID is 16 octets long, with each component in
network byte order (most significant byte first). The components are (1) a
48-bit (6-byte) timestamp in a 32-bit and a 16-bit chunk; (2) an 80-bit
(10-byte) random part in a 16-bit and two 32-bit chunks.

The C<binary_ulid()> function returns a ULID in binary representation. Like
C<ulid()>, it can take no parameters or a DateTime, but it can also take a
ULID in the canonical representation and convert it to binary:

 $binary_ulid = binary_ulid($canonical_ulid);

=head2 Datetime extraction

The C<ulid_date()> function takes a ULID (canonical or binary) and returns
a DateTime object corresponding to the timestamp it encodes.

 $datetime = ulid_date($ulid);

=head1 DEPENDENCIES

L<Math::Random::Secure>, L<Encode::Base32::GMP>.

=head1 AUTHOR

Baldur Kristinsson, December 2016

=head1 VERSION

 0.1 - initial version.

=cut
