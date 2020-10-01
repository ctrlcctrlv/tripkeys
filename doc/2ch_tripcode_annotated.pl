#!/usr/bin/perl

# 2ch_tripcode_annotated.pl
#
# (c) Fredrick R. Brennan, 2020. Based on public domain code by ◆FOX (Yoshihiro
# Nakao, 中尾嘉宏). This file is likewise in the public domain.

# Get tripcode password (with #) from stdin
$tripkey = <STDIN>;
chomp $tripkey;
if (substr($tripkey, 0, 1) ne "#") { print STDERR "Tripcode password must begin with #" && exit 1 };
# Remove #
$tripkey = substr $tripkey, 1;

#*#*# Generate salt #*#*#

# Based on the password, use the second two characters as a salt. Here, "st" will result.
$salt = substr $tripkey . "H.", 1, 2;
# Change all characters not in ASCII range 0x2E - 0x7A into 0x2E (period).
$salt =~ s/[^\.-z]/\./g;
# Change the characters in list :;<=>?@[\]^_` out for those in list ABCDEFGabcdef
#                                                                   :;<=>?@[\]^_`
# For our example, #istrip, the result of the salt will still be "st". However, imagining the input of #:_` , we would receive a salt of "ef".
$salt =~ tr/:;<=>?@[\\]^_`/A-Ga-f/;

print STDERR "Info: salt is $salt\n";

#*#*# Generate tripcode #*#*#

# Run crypt(), a DES-based one-way hash. Cf. http://man.he.net/man3/crypt
# This Perl version only considers the first 8 characters of the tripcode.
$trip = crypt $tripkey, $salt;

if (length($tripkey) > 8) {
    my $extra = substr $tripkey, 8;
    print STDERR "Warning: Dropped $extra, these bytes did not count!\n";
}

# Take last ten characters of hash
$trip = substr $trip, -10;

# Prepend ◆ (on 4chan ! would be used instead)
$trip = "◆" . $trip;

# Output to STDOUT
print STDOUT "Tripcode: ", $trip, "\n";

exit 0
