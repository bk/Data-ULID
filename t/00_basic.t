#!/usr/bin/env perl

use DateTime;
use Test::More tests => 11;

use_ok('Data::ULID', qw/ulid binary_ulid ulid_date/);

my $b32_re = qr/^[0123456789ABCDEFGHJKMNPQRSTVWXYZ]*$/;
my $old_ulid = '01B3Z3A7GQ6627FZPDQHQP87PM';
my $old_ulid_bin = "\x01\x58\xfe\x35\x1e\x17\x31\x84\x77\xfe\xcd\xbc\x6f\x64\x1e\xd4";
my $fixed_t = 1481797018.267;
my $fixed_dt = DateTime->from_epoch(epoch=>$fixed_t);

my $ulid = ulid();
my $b_ulid = binary_ulid($ulid);
my $ulid2 = ulid($b_ulid);
my $dt = ulid_date($ulid);
my $b_dt = ulid_date($b_ulid);
my $o_dt = ulid_date($old_ulid);
my $ob_ulid = binary_ulid($old_ulid);
my $f_ulid = ulid($fixed_dt);

ok(length($ulid) == 26,
   "Length of canonical ULID is 26");

ok($ulid =~ $b32_re,
   "ULID is valid base32 (Crockford variant)");

ok(length($b_ulid) == 16,
   "Length of binary ULID is 16");

ok($ulid eq $ulid2,
   "Converting back from binary yields same string");

ok($dt->isa("DateTime"),
   "ulid_date() yields DateTime");

ok("$dt" eq "$b_dt",
   "Canonical and binary ULID yield same DateTime");

ok($o_dt->hires_epoch == 1481733643.799,
   "Old ULID timestamp has correct hires_epoch");

ok($ob_ulid eq $old_ulid_bin,
   "Binary old ULID is correct");

ok(substr($f_ulid, 0, 10) eq '01B40ZR8MV',
   "ULID from fixed DateTime works as expected");

ok(ulid_date($f_ulid)->hires_epoch == $fixed_t,
   "ULID from fixed DateTime has correct hires_epoch");

