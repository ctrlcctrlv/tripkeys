# How to patch tripkeys into your imageboard

We can easily split the patch process in three. _Signing_, _verifying_ and _user interface_. Signing and user interface must be done client-side, so naturally JavaScript is what we use.

_Verifying_ must be done server-side. I offer a PHP implementation. A good future plan would be to port that to JavaScript, shouldn't be hard.

## Signing

When the user presses &laquo;Post&raquo;, we:

### Password-derived key

1. take the user's tripkey password (_trippass_) and derive a key from it:
      ```js
      var keypair = derive_keys(trippass);
      ```
1. get our input plaintext which we'll need to sign, and hash files if necessary:
      ```js
      var files = document.getElementById("upload").files;
      var plaintext = make_input_json(trippass, site, board, name, message, file_hashes(files) || []);
      ```
1. sign the message
      ```js
      var tripsig = sign(keypair, plaintext);
      // Don't allow admin to get our private key if we used tripPBKDF.
      document.getElementById("post_name").value = name;
      ```
1. let the server know
      ```js
      var form = document.getElementById("form");

      var tripsig_input = document.createElement("input");
      tripsig_input.name = "tripsig";
      tripsig_input.value = tripsig;
      tripsig_input.type = "hidden";

      var tripkey_input = document.createElement("input");
      tripkey_input.name = "tripkey";
      tripkey_input.value = keypair.public;
      tripkey_input.type = "hidden";

      form.appendChild(tripkey_input);
      form.appendChild(tripsig_input);
      ```
1. process post as normal.

### Provided tripkey and tripsig

Simply split them out, and do steps 2, 4, and 5.

## Verifying

When the server receives a post, it now needs to check for a tripsig and handle it appropriately.

1. Look for the inputs `tripkey` and `tripsig`;
      ```php
      $tripkey = $_POST["tripkey"];
      $tripsig = $_POST["tripsig"];
      if (($tripkey && $tripsig) && (!valid_tripkey($tripkey) || !valid_tripsig($tripsig))) {
          error("Invalid tripkey/tripsig");
      }
      ```
1. recreate the input JSON from the post body;
      ```php
      define("SITE", "org.420chan"); // name of your imageboard here
      $input = make_input_json(SITE, $board, $_POST["name"], $_POST["body"], $_FILES);
      ```
1. attempt verification.
      ```php
      $verified = verify($input, $tripkey, $tripsig); // boolean
      ```
1. pass `$verified`, `$input`, `$tripkey` and `$tripsig` to template and render if OK, otherwise reject the post.

## User interface

For each post on a page, add a hidden element inside the `<div>` with the tripsig. Display the tripkey right where you display tripcodes now.

Call `render_tripkey(el)` in your board JavaScript for each tripkey on the page, so that when the user hovers they'll see the friendlier emoji version of the key along with the `$input` and `$tripsig` should they wish to verify the post on their own computer.

![](https://raw.githubusercontent.com/ctrlcctrlv/tripkeys/master/doc/UI_hover_example.png)
