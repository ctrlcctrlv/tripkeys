![](https://raw.githubusercontent.com/ctrlcctrlv/tripkeys/master/doc/logo.svg)

This repository contains:

* a description of the tripkey system, a new type of identification for anonymous BBS's ([`doc/OVERVIEW.md`](https://github.com/ctrlcctrlv/tripkeys/blob/master/doc/OVERVIEW.md))
* an implementation in PHP (verifying) and JavaScript (signing/UI) of tripkeys (not yet uploaded)
* a patch for implementation of the same in Vichan; (`vichan_tripkeys.patch`) (TODO)
* a detailed explanation of the patch so you can implement it in your own imageboard software, free (meguca, fatchan, 314chan, etc.) or proprietary (420chan, etc.); ([`doc/PATCH_HOWTO.md`](https://github.com/ctrlcctrlv/tripkeys/blob/master/doc/PATCH_HOWTO.md))
* a historical overview of tripcodes (below).

This is simply a formalization and standardization of my video of 27 November 2019, [&ldquo;A tutorial for QAnon, or, how to use Bitcoin addresses to verify your messages on any website&rdquo;](https://www.youtube.com/watch?v=c8EjDKEeusM). To both further embarass QAnon, and advance the state of the art of imageboards, I dedicate this work to open source.

## Tripcodes

A _tripcode_ is, on an anonymous BBS, such as 4chan, a string of letters and numbers that appears next to a user's name when they post. There are different ways to generate this string of letters and numbers, and the generation method has subtle impacts on both users and administrators.

I will briefly talk about the main methods of tripcode generation, and then make the case for why we need a new one, which I call a _tripkey_.

My _tripkey_ method takes the power out of the hands of server owners and into the hands of users, allowing users to move their identity between imageboards freely.

### FOX's 2channel-style (!...)

The most widely used, even today, method of tripcode generation is based on the following script, first written by an early programmer for 2channel, 🟊FOX (Yoshihiro Nakao, 中尾嘉宏).

```perl
$tripkey = "#istrip";  # トリップキー文字列（# 付き）
$tripkey = substr $tripkey, 1;
$salt = substr $tripkey . "H.", 1, 2;
$salt =~ s/[^\.-z]/\./g;
$salt =~ tr/:;<=>?@[\\]^_`/A-Ga-f/;
$trip = crypt $tripkey, $salt;
$trip = substr $trip, -10;
$trip = "◆" . $trip;
print $trip, "\n";
```

The comment means, in English, "tripcode password (with #)".

A version of this script with many more comments and which accepts input from STDIN can be found in the file [`doc/2ch_tripcode_annotated.pl`](https://github.com/ctrlcctrlv/tripkeys/blob/master/doc/2ch_tripcode_annotated.pl).

Nakao's code is &approx;20 years old, and modern hardware can easily break its tripcodes. It suffers from further deficits: only the first eight characters of the tripcode matter, [because that's all `crypt` considered in Perl](https://perldoc.perl.org/functions/crypt).

```
Fred@DESKTOP-CBDJO68 MSYS ~/Workspace/tripkeys
$ ./doc/2ch_tripcode_annotated.pl
#istrip
Info: salt is st
Tripcode: ◆/WG5qp963c

Fred@DESKTOP-CBDJO68 MSYS ~/Workspace/tripkeys
$ ./doc/2ch_tripcode_annotated.pl
#:_`
Info: salt is ef
Tripcode: ◆rZgPfaS/mo

Fred@DESKTOP-CBDJO68 MSYS ~/Workspace/tripkeys
$ ./doc/2ch_tripcode_annotated.pl
#wakuwaku
Info: salt is ak
Tripcode: ◆tSdCM0v21w

Fred@DESKTOP-CBDJO68 MSYS ~/Workspace/tripkeys
$ ./doc/2ch_tripcode_annotated.pl
#wakuwaku``
Info: salt is ak
Warning: Dropped ``, these bytes did not count!
Tripcode: ◆tSdCM0v21w
```

On a modern GPU found in any regular consumer-grade PC, a 2channel-style tripcode can be broken in days. Even Ron Watkins of 8chan admits this.

### 8chan-style "secure tripcodes"

While not originated on 8chan, so-called "secure tripcodes" became most famous there due to their use by the LARPer QAnon. A "secure tripcode" is made "secure" (uncrackable) by making the following changes:

* instead of DES, use SHA1;
* use a secret server-side salt instead of deriving the salt from the key;
* rotate the salt occasionally to prevent leaks.

The function which generated these on 8kun can be seen in [`inc/functions.php:generate_tripcode`](https://github.com/ctrlcctrlv/infinity/blob/master/inc/functions.php#L2755).

However, this function still used DES. According to Watkins, [SHA1 is now in use](https://twitter.com/CodeMonkeyZ/status/1298630319759712256). Without Watkins telling us that, though, we'd have no way to know. This is because we do not know the salt, so we can not verify that the algorithm works how they say it works. Even if we know our password, we can't prove that it equals any particular tripcode on 8kun without either (a) hacking 8kun and getting the salt from the server or (b) using 8kun.

In that original 8chan source code we see the lines:

```php
// Lines 2776 to 2780:
if ($secure) {
    if (isset($config['custom_tripcode']["##{$trip}"]))
        $trip = $config['custom_tripcode']["##{$trip}"];
    else
        $trip = '!!' . substr(crypt($trip, str_replace('+', '.', '_..A.' . substr(base64_encode(sha1($trip . $config['secure_trip_salt'], true)), 0, 4))), -10);
} // ...
```

We can see that the server admin can put whatever tripcode they want in the `$config[custom_tripcode]` hashmap. So, so-called "secure tripcodes" are only "secure" if we trust the server admins. If they are dishonest, they can put any tripcode on any post, or make any password equal any tripcode.

This means, of course, that they can hijack any tripcode user's identity, including QAnon's.

## There is a better way

And you are looking at it.

See [`doc/OVERVIEW.md`](https://github.com/ctrlcctrlv/tripkeys/blob/master/doc/OVERVIEW.md) for an overview of my proposed system.

## Comparison to the state of the art

The only thing even remotely similar to this project is the PGP ability had by [Infinity Next](https://github.com/infinity-next/infinity-next) (infinity-next/infinity-next, AGPL3).

However, that ability is inferior in quite a few ways:

* it requires the server to remember keys, and it *uses the system keyring*. I think this is a possible DoS vector because users can fill up the keyring and it never gets pruned.
* it is not possible for users to post just with a password, there's no password-based key derivation.
