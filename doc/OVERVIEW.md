# The tripkey system

The tripkey system has three main elements exposed to the user:

* the _trippass_, the password the user actually enters; (example: `###IAmASecretAgentMan`)
* the _tripkey_, the equal to the hash in the traditional tripcode system; (example: `!!!r9c6ksuawj5fzjle5gx9rv0h40emk322uw6tjs`)
* the _tripsig_, a signature which is different in every post which more technical users can use outside any one anonymous BBS to verify a post.

And two hidden internal elements which advanced users can take advantage of:

* the _tripsecret_, created from the _trippass_ via key-derivation. If a user does not wish to use our key derivation, they can use any of the multiple ways of creating Bitcoin private keys and create a public/private key combo themselves and create tripsigs themselves.
* the _tripinput_, which is the actual input plaintext transformed to prevent replay attacks.

This is in every way a superior system as it gives the user these guarantees:

* if you choose a secure password, your tripkey will not be broken unless Bitcoin signatures (SHA256) are broken;
* your tripkey is for all intents and purposes equal to a tripcode. Normal Anons don't need to learn anything. If the tripkey matches on the screen, the post is by the same person.
* you can out the server admin if they try pass off a post as being signed with a certain tripkey when it was not;
* you can sign your posts on the client side, even outside of the browser!

Users can give as much or as little access to the private key as they choose. If they trust the server admin, they can sign their posts right in their browser completely transparently to them. 

Furthermore, we get to rely on Bitcoin's strong cryptography, without giving a rat's ass about the blockchain. Our code doesn't know that a blockchain even exists. We're using the addresses and the signatures, absolutely no Bitcoin needs to be owned to sign or verify a tripsig was created by a tripkey!

Here are the two example flows:

## Non-technical anonymous user flow

Anonymous enters their name followed by their tripkey, exactly as they would a regular tripcode. So, if they are currently posting by putting in the name field either `SecretSpy#IAmASecretAgentMan` or `SecretSpy##IAmASecretAgentMan`, they would now post as `SecretSpy###IAmASecretAgentMan`. (Note the number of `#`'s used.)

That's it. We do all of the following behind the scenes:

* The browser uses the `tripkeyPBKDF`, a very simple, standardized password-based key derivation function explained below, to go from `IAmASecretAgentMan` to a private key containing the right number of bytes to become a Bitcoin private key. For `IAmASecretAgentMan`, `tripkeyPBKDF` yields the bytes `31:e7:6c:bc:7d:3e:80:95:f0:8b:b9:77:18:77:ca:3d:75:95:21:e5:89:8e:a6:18:ed:50:15:48:06:65:f3:a4`; these are exactly enough bytes.&#x2a;
* We use the output of `tripkeyPBKDF` as our private key. We can convert even convert the hex to wallet input format: `KxtiajhLq5EUdSUHMpWjd5iUS3o5X3x7psC7uJyY897rfKUeaQZU`.&dagger;
* With our private key, we now can get the bech32 address (public key): `bc1qav0jadp87tr0thmkav4gfq2hudfqrdyt07dlk4`. We almost have the user's tripkey!&Dagger;
* Simply replace the beginning `bc1q`, which is constant, with `!!!`. Tripkey: `!!!av0jadp87tr0thmkav4gfq2hudfqrdyt07dlk4`.

When the user presses &laquo;Post&raquo;, all of this happens, and their post will show up under `SecretSpy !!!av0jadp87tr0thmkav4gfq2hudfqrdyt07dlk4`! And, furthermore, other users who may or may not trust your server can verify this key: they can copy the generated tripsig, e.g. `ICpkJ3fZRWp87zPZ7gOpw/4kvK4Ew+ihemsZxHMLZPM0sdZu/82GEHCzaNqs4Qmiu+idLG0ypKydVKEUQz6NQOg=`, and the input JSON (see &sect; tripinput) and use the command line tripsig verification tool to know that nothing was tampered with, that this tripkey really did produce this message!

----

<small>
Below I'll show simple ways you can verify every step right in your browser. Of course, my code does all of this for you. But just in case you want third party verification that what we're doing is secure and I haven't inserted any poison pill: this is pure Bitcoin/scrypt.

&#x2a; My `tripkeyPBKDF` function is so simple we can recreate its behavior with [the generic `scrypt-js` demo](https://ricmoo.github.io/scrypt-js/) (ricmoo/scrypt-js, MIT). For password, `IAmASecretAgentMan`. For salt, `naMtnegAterceSAmAI` (reversed password). For **Nlog2**, 12. **r**, 8. **p**, 1. dkLen, **32**. Output will include ``Generated: 31e76cbc7d3e8095f08bb9771877ca3d759521e5898ea618ed5015480665f3a4``. Make sure both password and salt are set to `UTF-8 (NFKC)`.

&dagger; The famous `bitaddress` (pointbiz/bitaddress.org, MIT) can do this. Press &laquo;Wallet Details&raquo;, then paste the hex: `31e76cbc7d3e8095f08bb9771877ca3d759521e5898ea618ed5015480665f3a4` in the &laquo;Enter Private Key&raquo; field. Press &laquo;View Details&raquo;, then scroll down and copy &laquo;Private Key WIF Compressed&raquo;.

&Dagger; We can use [`segwitaddress`](https://segwitaddress.org/bech32/) (coinables/segwitaddress, unknown), which internally uses `bitcoinjs-lib`'s bitcoin.ECLib for this purpose (bitcoinjs/bitcoinjs-lib, MIT). Scroll down to &sect; Details, and in the &laquo;WIF Private Key&raquo; field, paste `KxtiajhLq5EUdSUHMpWjd5iUS3o5X3x7psC7uJyY897rfKUeaQZU`. Press &laquo;Show Details&raquo;, and copy the &laquo;Address&raquo;.
</small>

### `tripkeyPBKDF`

`tripkeyPBKDF` is both a password-based key derivation function and a password-based salt derivation function. It uses scrypt internally, upon which Litecoin among other cryptographic coins relies. `tripkeyPBKDF` is _optional_, more advanced users may come up with their private keys any way they choose.

`tripkeyPBKDF` v0, as mentioned in the footnote in the above section, uses these scrypt parameters:

| Nlog2 | r | p | dkLen |
|-------|---|---|-------|
| 12    | 8 | 1 | 32    |

The only thing you might hesitate about is how we're getting our salt. We simply _reverse_ the password. So, given `IAmASecretAgentMan`, our salt will be `naMtnegAterceSAmAI`. I believe this is secure for many reasons. For one thing, in scrypt, this does not need to be a secret salt. It just needs to be different for every invocation to prevent rainbow table attacks. Clearly, just reversing the password is good enough unless someone can prove otherwise.

## Making the key unspendable

One "problem" that some might complain about is that we've inadvertantly made it so that users can "tip" tripcode users with Bitcoin. I personally do not see this as a problem and in my implementation have done nothing to "fix" it. However, if this really concerns you, there's a simple solution: XOR the public key with a [nothing-up-my-sleeve number](https://en.wikipedia.org/wiki/Nothing-up-my-sleeve_number). Yes, users can XOR them again, because for tripkeys to be verifiable you must disclose the XOR value, but they won't simply be able to replace `!!!` with `bc1q`.

If you are very paranoid about stopping technical users who will go through the trouble of XOR'ing from exchanging tips, perhaps this system is not for you. I am open to other ideas for making keys unspendable, but really, do not see this as very important.

Remember indeed that very popular users, for whom this may be a concern, but who do not want to collect any money, can use Bitcoin Script to make a valid address unspendable by making all inputs `OP_RETURN`; they can also simply send any coins they receive back.

In future, we may want to slightly modify the constants for tripkey generation so they're just different enough from Bitcoin address generation that addressess won't be spendable. For example, classic Litecoin addresses, which begin with `L`, cannot be used on the Bitcoin network just by changing `L` to `1`.

## Technical anonymous user flow

Let's say that a hypothetical nerdier user wants to take advantage of some of the benefits of being able to use any Bitcoin private key. Instead of posting as `SecretSpy###IAmASecretAgentMan`, they instead will post with their name fields like this:

```plain
SecretSpy!!!av0jadp87tr0thmkav4gfq2hudfqrdyt07dlk4!!!H169+GZtHROqos8hONufnLfE6TPOHZXxVgx/4j07zb2e4opThngxx6VkY4yX2bHHg/DgedIiGVAHERW2KH87bjs=
```

And your server will verify that the signature ``H169+GZtHROqos8hONufnLfE6TPOHZXxVgx/4j07zb2e4opThngxx6VkY4yX2bHHg/DgedIiGVAHERW2KH87bjs=`` works for their message, and allow the post through.

Now, of course, we need to prevent replay attacks! If this is all there is to it, users may impersonate tripkey users by posting their messages. They won't be able to post any message the tripkey user didn't write, but with a sufficiently large corpus could easily troll tripkey users by playing their posts back at them.

So let's do that by changing the plaintext. Introducing: tripkey input JSON, _tripinput_.

### Tripinput

For simplicity, **must** be UTF-8.

Note: Real implementations must remove all unnecessary whitespace, but ignore all whitespace in `<body>`! Otherwise valid signatures will not match. All keys and values must be strings!

Example:

```json
{
    "version": "0",
    "head": {
        "site": "org.420chan",
        "board": "a",
        "window": "1601543100",
        "name": "SecretSpy"
    },
    "files": [
        "29f5278bca09997ec2603675f45c4e5c90816a212ecdd67ffc4d2677a961c4e7"
    ],
    "body": "心が死ぬよ 自分のためらいが引き金になるよ
「助けて」君へと
「信じて」君から漏れた声に揺れる

泣きたくない これ以上会いたくない
燃える愛しさが交差した
会いにきて 泣きたくて追いかけて
誰にもとめられない

これは未来? それとも夢? 答えはどこだろう
これが今を試す扉 壊すの? 開けるの? どうしよう?

Everything will be decided by the rules"
}
```

This JSON will also be generated by the browser when users post using the simple password-based system, just without being imposed on users who don't care to find out how the system works.

The only thing that might be confusing is the _window_, everything else is self-explanatory. The _window_ is just this formula, where _t_ is the current seconds since 1970:

```c
t-(t%(60*5))
```

So, every five minutes, this gets invalidated. In the example, your server **must** check the following:

* user requested name SecretSpy;
* our constant site name is org.420chan;
* board being posted on is /a/;
* the current Unix epoch time is within five minutes of 1601543100;
* the SHA256 hashes of all uploaded files match.

If _any_ condition is not true, the post **must** be rejected.

Furthermore, you **must** store approved signatures in a separate table for at least five minutes, and not allow signatures to be double posted. You **must** check that the current signature is not already known to you.
