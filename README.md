# NAME

Data::ULID - Universally Unique Lexicographically Sortable Identifier

# SYNOPSIS

    use Data::ULID qw/ulid binary_ulid ulid_date/;

    my $id = ulid();  # e.g. 01ARZ3NDEKTSV4RRFFQ69G5FAV
    my $binary_id = binary_ulid($id);
    my $datetime_obj = ulid_date($id);  # e.g. 2016-06-13T13:25:20

# DESCRIPTION

## Background

This is an implementation in Perl of the ULID identifier type introduced by
Alizain Feerasta. The original implementation (in Javascript) can be found at
[https://github.com/alizain/ulid](https://github.com/alizain/ulid).

ULIDs have several advantages over UUIDs in many contexts. The advantages
include:

- Lexicographically sortable
- The canonical representation is shorter than UUID (26 vs 36 characters)
- Case insensitve and safely chunkable.
- URL-safe
- Timestamp can always be easily extracted if so desired.

## Canonical representation

The canonical representation of a ULID is a 26-byte, base32-encoded string
consisting of (1) a 10-byte timestamp with millisecond-resolution; and (2) a
16-byte random part.

Without paramters, the `ulid()` function returns a new ULID in the canonical
representation, with the current time (up to the nearest millisecond) in the
timestamp part.

    $ulid = ulid();

Given a DateTime object as parameter, the function will set the timestamp part
based on that:

    $ulid = ulid($datetime_obj);

Given a binary ULID as parameter, it returns the same ULID in canonical
format:

    $ulid = ulid($binary_ulid);

## Binary representation

The binary representation of a ULID is 16 octets long, with each component in
network byte order (most significant byte first). The components are (1) a
48-bit (6-byte) timestamp in a 32-bit and a 16-bit chunk; (2) an 80-bit
(10-byte) random part in a 16-bit and two 32-bit chunks.

The `binary_ulid()` function returns a ULID in binary representation. Like
`ulid()`, it can take no parameters or a DateTime, but it can also take a
ULID in the canonical representation and convert it to binary:

    $binary_ulid = binary_ulid($canonical_ulid);

## Datetime extraction

The `ulid_date()` function takes a ULID (canonical or binary) and returns
a DateTime object corresponding to the timestamp it encodes.

    $datetime = ulid_date($ulid);

# DEPENDENCIES

[Math::Random::Secure](https://metacpan.org/pod/Math::Random::Secure), [Encode::Base32::GMP](https://metacpan.org/pod/Encode::Base32::GMP).

# AUTHOR

Baldur Kristinsson, December 2016

# TODO

Add functions for converting to/from UUID (Version 1), since both identifier
types are 128-bit and incorporate a timestamp.

# VERSION

    0.1 - Initial version.
    0.2 - Bugfixes: (a) fix errors on Perl 5.18 and older, (b) address an issue
          with GMPz wrt Math::BigInt objects.
    0.3 - Bugfix: Try to prevent 'Inappropriate argument' error from pre-0.43
          versions of Math::GMPz.
    0.4 - Bugfix: 'Invalid argument supplied to Math::GMPz::overload_mod' for
          older versions of Math::GMPz on Windows and FreeBSD. Podfix.
