# The error you're seeing:

```
Permission denied (publickey)
```

when running:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519 -o PubkeyAuthentication=no pi@192.168.1.2
```

...indicates that the server at `192.168.1.2` **does not allow password authentication**, and **requires public key authentication**, but since your key isn’t installed yet, you’re locked out.

---

### 🔍 Why your command fails:

* `ssh-copy-id` needs to connect **using password authentication** in order to install the public key.
* But you added `-o PubkeyAuthentication=no`, which disables key auth (normally fine), **but** the server doesn’t allow password login either.
* So: **SSH fails before it can even try to copy the key.**

---

### ✅ Fix Options

#### ✅ **Option 1: Enable PasswordAuthentication temporarily (Recommended)**

1. On the server `192.168.1.2`, log in **physically or through another method** (e.g., console access or keyboard+monitor).

2. Edit the SSH config:

   ```bash
   sudo nano /etc/ssh/sshd_config
   ```

3. Make sure these lines exist and are **set like this**:

   ```
   PasswordAuthentication yes
   PubkeyAuthentication yes
   ```

4. Restart SSH:

   ```bash
   sudo systemctl restart ssh
   ```

5. Now run on your local machine:

   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519 pi@192.168.1.2
   ```

6. After copying the key, **disable password authentication again** on the server if desired for better security:

   ```bash
   PasswordAuthentication no
   ```

   And restart SSH again.

---

#### ✅ **Option 2: Manually copy the key**

If you **can’t enable password login**, do this from the client:

1. Copy your public key to clipboard:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. On the server (`192.168.1.2`), log in physically or via console.
3. As the `tom` user (or switch to that user):

   ```bash
   mkdir -p ~/.ssh
   nano ~/.ssh/authorized_keys
   ```
4. Paste the public key into that file.
5. Set correct permissions:

   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

Now you should be able to SSH normally:

```bash
ssh pi@192.168.1.2
```


