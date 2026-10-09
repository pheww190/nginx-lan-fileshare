# LAN File Share (nginx in WSL / Linux)

A tiny file-sharing site that runs on your own machine. Your friend opens a
link in their browser (same Wi-Fi), logs in with a username/password you set,
and can **browse folders, download, upload, create, rename and delete** files
and folders. No install on their side, no accounts, no internet.

It is just nginx serving a folder, protected by HTTP Basic Auth. Everything
lives under one directory (`~/fileshare`), so nothing in `/etc/nginx` is
touched.

---

## What's in this kit

```
setup.sh                 one-shot installer (creates folders, writes the config)
nginx.conf.template      the nginx config (setup.sh fills in your paths)
www/index.html           the web page your friend sees
conf/htpasswd.example    template for your username/password file
```

---

## Setup (in your WSL terminal)

### 1. Install nginx
```bash
sudo apt update && sudo apt install -y nginx
```
The stock Ubuntu package already includes the WebDAV module (needed for
upload / delete / rename). You can confirm with:
```bash
nginx -V 2>&1 | grep -o -- --with-http_dav_module
```

### 2. Unzip this kit and run the installer
```bash
unzip nginx-lan-fileshare-wsl.zip -d nginx-lan-fileshare
cd nginx-lan-fileshare
bash setup.sh
```

This creates:

```
~/fileshare/
  data/        <-- YOUR SHARED FILES live here (shown as "files" in the UI)
  www/         the web page
  conf/        the password file (.htpasswd)
  temp/        upload staging
  logs/        nginx logs
  nginx.conf   generated config
```

### 3. Set your username & password
```bash
nano ~/fileshare/conf/.htpasswd
```
Edit the last line to `username:password`, e.g. `john:MySecret123`, then save
(Ctrl-O, Enter, Ctrl-X). That's the login you give your friend.

### 4. Start it
```bash
nginx -t -c ~/fileshare/nginx.conf      # check the config
nginx    -c ~/fileshare/nginx.conf      # start
```
(If `nginx` isn't found, use `/usr/sbin/nginx` — it's not always on a normal
user's PATH. No `sudo` is needed: it runs on port 8080 as you.)

### 5. Open it
- On your PC: <http://localhost:8080/>
- Your friend: see the next section.

---

## Letting your friend reach it (WSL2 networking)

This is the one WSL-specific catch. **WSL2 runs behind its own NAT**, so by
default your friend's device *cannot* reach a server running inside WSL — even
though `localhost` works on your own PC. You have two options.

### Option A — Mirrored networking (recommended, Windows 11 22H2+)

Mirrored mode makes WSL share your Windows network interfaces, so the server
becomes reachable on your LAN directly.

1. On Windows, create/edit `C:\Users\<you>\.wslconfig`:
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```
2. In PowerShell: `wsl --shutdown`, then reopen WSL.
3. Start nginx again (step 4).
4. Find your Windows IP: `ipconfig` (the IPv4 of your Wi-Fi adapter).
5. Your friend opens `http://<windows-ip>:8080/`.

### Option B — Port forwarding (works on any Windows)

In an **Administrator** PowerShell, run:

```powershell
# forward Windows port 8080 -> WSL, and open the firewall
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=127.0.0.1
New-NetFirewallRule -DisplayName "WSL LAN Share" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080
```

Then your friend opens `http://<your-windows-ip>:8080/`.

> Note: if you instead point `connectaddress` at the WSL IP, it changes on
> every reboot — using `127.0.0.1` avoids that.

---

## Using it

- **Browse folders** — click a folder name to open it; *Up* or the breadcrumb
  trail to go back.
- **New folder** — click *New folder*, type a name, *Create*. Folders nest.
- **Rename** — click *Rename* next to any file or folder (works via WebDAV
  `MOVE`), type the new name.
- **Delete** — *Delete* removes a file, or a folder *and everything inside it*
  (you'll be asked to confirm).
- **Upload** — *Upload files* or drag & drop onto the page.
- **Download** — click a file.

Anything you drop into `~/fileshare/data` from your terminal shows up in the UI
immediately, and vice-versa.

---

## Everyday commands

```bash
nginx -s reload -c ~/fileshare/nginx.conf   # apply config changes
nginx -s stop   -c ~/fileshare/nginx.conf   # stop
nginx    -c ~/fileshare/nginx.conf          # start
```

---

## Security notes (please read)

- Basic Auth over plain **http** sends the password base64-encoded, not
  encrypted. Fine on a trusted home/office Wi-Fi; **do not** expose this to the
  internet or forward the port from your router.
- Anyone on the Wi-Fi with the password has full read/write/delete access to
  `~/fileshare/data`. Only put files there you're OK sharing.
- To stop sharing entirely: `nginx -s stop -c ~/fileshare/nginx.conf`.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `nginx: command not found` | Use `/usr/sbin/nginx`, or add `/usr/sbin` to PATH |
| `localhost:8080` works but friend can't connect | Do the WSL networking step above (mirrored mode or portproxy + firewall) |
| Login keeps failing | Re-check `~/fileshare/conf/.htpasswd` (no spaces around `:`) and reload |
| Upload / delete / rename returns 405 | Your nginx lacks the WebDAV module — install `nginx-extras` |
| `nginx -t` complains about `client_body_temp_path` | Make sure `~/fileshare/temp` exists (re-run `setup.sh`) |
| Delete fails on a folder | Shouldn't happen — the UI empties folders first; check `~/fileshare/logs/error.log` |
| Port 8080 already in use | Edit `~/fileshare/nginx.conf`, change `listen 8080;`, reload |
