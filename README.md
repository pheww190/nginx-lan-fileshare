# LAN File Share (nginx on Windows)

A tiny file-sharing site you run on your own Windows PC. Your friend opens a
link in their browser (same Wi-Fi), logs in with a username/password you set,
and can **download, upload and delete** files in a shared folder. No install on
their side, no accounts, no internet.

It is just nginx serving a folder, protected by HTTP Basic Auth.

---

## What's in this kit

```
nginx.conf              the nginx configuration (drop-in replacement)
www/index.html          the web page your friend sees
conf/htpasswd.example   template for your username/password file
```

---

## One-time setup

### 1. Get nginx for Windows
Download the **mainline** zip from <https://nginx.org/en/download.html>
(e.g. `nginx-1.27.4.zip`) and unzip it to `C:\nginx`.

> The official Windows build already includes the WebDAV module, so
> upload/delete works out of the box. Don't use a random old build.

### 2. Create your folders
Open Command Prompt and run:

```bat
mkdir C:\fileshare\data
mkdir C:\fileshare\www
mkdir C:\fileshare\conf
mkdir C:\fileshare\temp
```

- `C:\fileshare\data`  -> the files you share live here
- `C:\fileshare\www`   -> the web page
- `C:\fileshare\conf`  -> your password file
- `C:\fileshare\temp`  -> upload staging (keep on the same drive as `data`)

### 3. Copy the files into place
- Copy `www\index.html`      -> `C:\fileshare\www\index.html`
- Copy `nginx.conf`          -> `C:\nginx\conf\nginx.conf`  (replace the existing one)
- Copy `conf\htpasswd.example` -> `C:\fileshare\conf\.htpasswd`

### 4. Set your username & password
Open `C:\fileshare\conf\.htpasswd` in Notepad and edit the last line:

```
john:MySecret123
```

That means user **john**, password **MySecret123**. Change both to whatever you
like, then save. (This is the password you give your friend.)

### 5. Find your PC's address
Run:

```bat
ipconfig
```

Under your Wi-Fi adapter, note the **IPv4 Address**, e.g. `192.168.1.5`.

### 6. Start nginx

```bat
cd C:\nginx
start nginx
```

To check it's running: `tasklist /fi "imagename eq nginx.exe"` should show two
`nginx.exe` processes.

### 7. Allow it through the firewall
The first time you start nginx, Windows asks about firewall access — tick
**Private networks** and click **Allow access**. (If you missed it, allow
`nginx.exe` under Windows Defender Firewall > Allow an app.)

---

## Using it

- On your PC: open <http://localhost/>
- For your friend: send them **http://192.168.1.5/** (your IP from step 5)

They log in with the username/password from step 4, then can:

- **Download** — click any file
- **Upload** — click *Upload files* or drag & drop onto the page
- **New folder** — click *New folder*, type a name, click *Create* (folders nest;
  open one by clicking its name, and use *Up* or the breadcrumb to go back)
- **Delete** — click *Delete* next to a file, or *Delete folder* to remove a
  folder. Deleting a folder removes everything inside it (you'll be asked to
  confirm first).

Just drop files into `C:\fileshare\data` yourself and they appear instantly.

---

## Everyday commands

```bat
cd C:\nginx
nginx -s reload     REM apply changes after editing nginx.conf
nginx -s stop       REM stop the server
start nginx         REM start it again
```

If port 80 is already taken, edit `nginx.conf`, change `listen 80;` to
`listen 8080;`, reload, and share `http://192.168.1.5:8080/`.

---

## Adding more users

Add one line per person to `C:\fileshare\conf\.htpasswd`:

```
john:MySecret123
priya:AnotherPass
```

Then `nginx -s reload`. Everyone who has any of these logins can see the whole
share — there are no per-person permissions.

---

## Security notes (please read)

- Basic Auth over plain **http** sends the password base64-encoded, not
  encrypted. That is fine on a trusted home/office Wi-Fi, but **do not** expose
  this to the internet or forward the port from your router.
- Anyone on the same Wi-Fi who knows the password has full read/write/delete
  access to `C:\fileshare\data`. Only put files there you're OK sharing.
- To stop sharing entirely, just run `nginx -s stop`.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Browser can't reach the page | Check `ipconfig` IP, make sure both devices are on the same Wi-Fi, and allow nginx in the firewall |
| Page loads but login keeps failing | Re-check `.htpasswd` (no spaces around `:`, correct user/pass) and reload nginx |
| Upload fails / 403 or 500 | Confirm `C:\fileshare\temp` exists and nginx can write to `C:\fileshare\data`; keep temp on the same drive |
| 405 on upload | You're not on the official Windows nginx build (the WebDAV module is missing) |
| nginx won't start | Read `C:\nginx\logs\error.log` — usually a typo or a path with backslashes |
| Delete fails on a folder | The folder isn't empty — delete its contents first |
