# Deploy and Host tabsh on Railway

tabsh puts your shells and coding agents in a browser tab, with a kanban board that tracks every card: what is running, what needs you, and what is done. This template runs it on Railway as a persistent cloud dev box you can open from any browser, behind a password.

## About Hosting tabsh

tabsh is a small Rust daemon that runs real PTY shells and serves its own web app. Upstream it listens on 127.0.0.1 only, so this template puts Caddy in front of it in the same container. Caddy adds a password login, answers Railway's healthcheck, and forwards everything else to tabsh. Your home directory lives on a volume at `/data/home`, so shells, scrollback, cloned repos, installed CLIs and agent logins all survive redeploys.

## Common Use Cases

- Run Claude Code, Codex, Gemini CLI or OpenCode in the cloud and check on them from a laptop, tablet or phone
- Keep long-running shells and dev servers alive while your laptop sleeps
- Track several agents across projects on one board, with cards that move to Needs input when an agent stops

## Dependencies for tabsh Hosting

- One service built from `ghcr.io/hmseeb/tabsh-railway` (tabsh v1.5.1 plus Caddy, Node 22, git and sudo)
- One volume mounted at `/data`

### Deployment Dependencies

- tabsh source and docs: https://github.com/Blaise1030/tabsh and https://tabsh.cc/docs/
- Image source: https://github.com/hmseeb/tabsh-railway

### Implementation Details

**Logging in.** Open the service's public URL. Your browser asks for a username and password: the username is `admin` and the password is the `TABSH_PASSWORD` variable on the service's Variables tab (generated per deploy). After login the app pairs itself automatically.

**Installing an agent.** Open a shell card and install what you use, for example:

```
npm i -g @anthropic-ai/claude-code
claude
```

Global npm installs land in `/data/home/.npm-global`, which is on the volume. You run as the `node` user with passwordless `sudo`, so `sudo apt-get install ...` works too (system packages do not survive a redeploy; anything under `/data/home` does). Then run `tabsh setup` inside an agent to let it move its own card on the board.

**Security model.** Everything except the app's API is behind the password. The API (`/api/*`, `/ws`) is protected by tabsh's own 64-character pairing token, which the app receives only after the password login. Anyone with the password gets a shell on this container, so treat it like an SSH key: change `TABSH_PASSWORD` to rotate it. To revoke paired browsers too, delete `/data/home/.tabsh/token` and redeploy.

**Variables.**

- `TABSH_PASSWORD`: login password (generated)
- `TABSH_USER`: login username, default `admin`
- `PORT`: where Caddy listens, default `8080` (the domain targets it)

**Troubleshooting.**

- The browser keeps asking for the password: check the username is `admin`, and copy the password again from the Variables tab without trailing spaces.
- Safari asks for the password a second time on first load: that is Safari re-prompting for a subresource; enter it once more.
- A shell disappeared after a redeploy: running processes stop on redeploy, but tabsh restores the cards, folders and scrollback.

**Scaling.** Single instance by design: tabsh is single-user and its state is one SQLite file on the volume. Give the service more CPU and RAM if agents build large projects.

## Why Deploy tabsh on Railway?

Railway gives tabsh what a laptop cannot: it stays on. Agents keep working while you are offline, the volume keeps your workspace, and the HTTPS domain lets you check in from any device without setting up a VPN or tunnel.
