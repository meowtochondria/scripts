# Using Fingerprint sensor only if laptop lid is open

Fingerprint auth in Linux works through [PAM](https://en.wikipedia.org/wiki/Linux_PAM), there is `pam_fprintd.so` module which talks to `fprintd` service. When `fprintd` service isn't working, `pam_fprintd` fails to communicate with it, and PAM auth skips to the next module in the config. But another PAM module could also skip over `pam_fprintd`.

So suppose you have `/etc/pam.d/system-auth` with the following contents:

```
auth            sufficient      pam_fprintd.so
auth            required        pam_unix.so
```
Your real config could be different or even in a different location, but what's crucial is `pam_fprintd` and `pam_unix`, which does password auth.

What you could do is add another entry into config, just before `pam_fprintd.so` which would skip that module if LID is closed. One way to achieve this is via [pam_exec.so](https://man7.org/linux/man-pages/man8/pam_exec.8.html) module.

Add the following line, just before `pam_fprintd`:

```
auth   [success=ignore default=1]   pam_exec.so quiet /usr/bin/grep --quiet --no-messages open /proc/acpi/button/lid/LID/state &>/dev/null
```

So your config would look like this:

```
auth   [success=ignore default=1]  pam_exec.so quiet /usr/bin/grep --quiet --no-messages open /proc/acpi/button/lid/LID/state &>/dev/null
auth   sufficient                  pam_fprintd.so
auth   required                    pam_unix.so
```

Now PAM auth would execute your script before attempting fingerprint auth, and if your script returns non-zero exit code (fails) it would do the default action, which skips 1 entry in a PAM config (so it skips `pam_fprintd` to the next auth which is `pam_unix`). When LID is open, it will return 0 exit code, and on success it wouldn't do anything, because of the `ignore` keyword in a config.

Alternatively, instead of `pam_exec.so` with a script, you can make your own PAM module with the same behavior as a script.

Few notes on debugging and actually implementing this. If you're having issues with `pam_exec`, you can add debugging options like `debug` and `log`. For details check `pam_exec` [documentation](https://man7.org/linux/man-pages/man8/pam_exec.8.html).

It is also good to test your changes on a new PAM config, instead of modifying an existing one, since a mistake in a config might lock you from your account. For example, you can just copy your `system-auth` as `system-auth-new` and work on `system-auth-new` and then replace it when it's tested. And for testing you could use [pamtester](https://pamtester.sourceforge.net/). For example:

```
cp /etc/pam.d/system-auth /etc/pam.d/system-auth-new
# UPDATE /etc/pam.d/system-auth-new
pamtester system-auth-new YOUR_USER_NAME authenticate
```

And when it works as intended, replace `system-auth with` your new config.

## Ubuntu
Ubuntu seems to be using `pam-auth-*` binaries to manage pam configuration. In this scenario, drop following content into `/usr/share/pam-configs/laptop-lid`

```
Name: Disable fingerprint when laptop lid is closed.
Default: no
Priority: 261
Conflicts: fprint
Auth-Type: Primary
Auth:
        [success=ignore default=1]      pam_exec.so quiet /usr/bin/grep --quiet --no-messages open /proc/acpi/button/lid/LID/state &>/dev/null
```

Ensure that file mentioned above:

* Has `Priority` number greater than that mentioned in `/usr/share/pam-configs/fprintd`. You can use the following command to get the priority number.

    ```
    echo $(( $(grep --only-matching --perl-regexp --max-count=1 '\d+' /usr/share/pam-configs/fprintd ) + 1))
    ```
* `/proc/acpi/button/lid/LID/state` exists. That file depends on how hardware is wired up and may be available under some other path on the system.

Execute `sudo pam-auth-update` to update appropriate file under `/etc/pam.d`. Now the system is ready to use.

In case you also want to have same behavior when laptop lid is open, but connected to HDMI, you can do so by extending the script to also check for that. Connection state will include `connected` under appropriate display path, like `/sys/devices/pci0000:00/0000:00:08.1/0000:33:00.0/drm/card1/card1-DP-9/status`.
