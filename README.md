# Messenger (Phoenix/Elixir)

A real-time web messaging application built with Elixir 1.18, Phoenix 1.7 and PostgreSQL.  
It demonstrates how you can leverage the BEAM (Erlang VM) for low-latency chat, presence tracking and fault-tolerant concurrency.

---

## 1  What the application does
* Allows users (registered or guests) to join chat rooms and exchange messages instantly.
* Tracks online users and typing indicators with Phoenix Presence.
* Persists chat history to PostgreSQL.
* Provides a responsive Tailwind-CSS UI that works on mobile and desktop.
* Exposes a WebSocket API that could be consumed by native or web clients.
* Full user-authentication (register, login, session, remember-me).
* SQLite (dev) or PostgreSQL (prod) persistence with Ecto migrations.
* Container-ready (Docker & docker-compose) and IaC (Terraform) samples.
* Comprehensive test-suite (`mix test`) for critical paths.

---

## 2  Development Setup

### Prerequisites
| Tool | Version | Notes |
|------|---------|-------|
| Elixir | ≥ 1.14 (tested on 1.18.3) | installs Mix |
| Erlang/OTP | ≥ 25 | required by Elixir |
| PostgreSQL | ≥ 13 | local or remote |
| Node.js | ≥ 18 | asset build pipeline |
| git | any | cloning |

### 1. Clone & move to the project folder

```bash
git clone <repo-url> ~/Documents/2025/factory-apps/beam-messenger
cd ~/Documents/2025/factory-apps/beam-messenger
```

### 2. Environment variables

```bash
cp .env.example .env        # edit with your DB credentials
export $(grep -v '^#' .env | xargs)   # or use direnv/dotenv
```

Phoenix will also read `DATABASE_URL` if provided.

### 3. Install dependencies & set up DB

```bash
mix deps.get
npm --prefix assets install     # installs JS deps
mix ecto.setup                  # creates DB, runs migrations & seeds
```

### 4. Run the application

```bash
mix phx.server        # or iex -S mix phx.server for IEx console
```

Visit http://localhost:4000 in your browser.

Hot-reload for backend & frontend changes is enabled in dev.

---

## 3  Docker Setup

```bash
# Build & start dev stack (app + Postgres)
docker compose up --build

# Tail the logs
docker compose logs -f app
```
The container mounts the source tree for live-reloading.  
Variables can be overridden in `docker-compose.yml`.

---

## 4  Running Tests

```bash
mix test        # unit / integration tests
mix coveralls   # coverage (ensure COVERALLS_TOKEN in CI)
```

---

## 5  Deployment with Terraform (💻→☁️)

Terraform manifests live in `terraform/`.

```bash
cd terraform
terraform init -backend-config="bucket=beam-messenger-tf"
terraform plan  -var="environment=prod"
terraform apply -var="environment=prod"
```
The sample stack provisions:
* VPC with public/private subnets
* RDS Postgres
* ECS Fargate cluster + ALB

---

## 6  Project Structure (abridged)

```
beam-messenger/
├── assets/                 # JS/CSS (esbuild + Tailwind)
│   ├── js/
│   │   ├── app.js          # Phoenix LiveView boot
│   │   ├── chat.js         # client-side chat logic
│   │   └── user_socket.js  # raw socket helper
├── lib/
│   ├── messenger/
│   │   ├── accounts/       # user schemas & context
│   │   ├── chat/           # message schema & context
│   │   └── application.ex  # supervision tree
│   └── messenger_web/
│       ├── channels/       # ChatChannel, Presence
│       ├── controllers/    # ChatController
│       ├── components/     # HEEx UI components
│       ├── templates/      # page layouts
│       ├── endpoint.ex     # sockets & plugs
│       └── router.ex       # routes
├── priv/
│   ├── repo/               # migrations & seeds
│   └── static/             # compiled assets
└── README.md
```

---

## 7  Architecture Overview

BEAM Messenger follows a classic **Phoenix + Ecto** architecture:

```
┌───────────────┐   WebSocket   ┌──────────────┐
│   Browser     │◄────────────►│  Phoenix     │
│  LiveView UI  │               │  Channels    │
└───────────────┘               │    (BEAM)    │
        ▲ HTTP/HTML             └──────┬───────┘
        │                              ▼
        │                       ┌──────────────┐
        └──────────────────────►│   Ecto Repo  │
                                │  PostgreSQL  │
                                └──────────────┘
```

Assets are bundled with **esbuild** & **Tailwind**.  
Container images are published and run on **ECS Fargate** (sample IaC).

---

## 8  Key Technologies

| Area | Tech | Purpose |
|------|------|---------|
| Backend | Elixir / Phoenix | high-performance, fault tolerant real-time server |
| Realtime | Phoenix Channels & Presence | WebSocket communication, online users, typing |
| Data | Ecto + PostgreSQL | relational persistence |
| Frontend | HEEx, TailwindCSS, Vanilla JS | reactive UI, minimal JS bundle |
| Auth | Phoenix.Token | stateless signed tokens for sockets |
| Security | CSRF, Plug pipeline | default Phoenix protections |
| Dev-X | LiveReload, IEx | fast feedback loop |

---

## 9  API Reference (excerpt)

| Type | Endpoint / Topic | Payload | Notes |
|------|------------------|---------|-------|
| REST | `POST /login`    | `{username,email,password}` | returns session cookie |
| REST | `POST /register` | `{username,email,password}` | creates account |
| WS   | `chat:ROOM`      | `"new_message"` `{text}` | broadcast message |
| WS   | `chat:ROOM`      | `"typing"` `{typing}` | typing indicator |
| WS   | `chat:ROOM`      | `"status"` `{status}` | away / online |

More endpoints live in docs/api.md.

---

## 10  Contributing

1. Fork the repository and create a feature branch:
   ```bash
   git checkout -b feat/my-new-thing
   ```
2. Install dev dependencies (`mix setup`).
3. Write code **and** tests (`mix test`).
4. Run the linter & formatter:
   ```bash
   mix format
   mix credo --strict
   ```
5. Commit using conventional commits and open a pull-request describing _why_ and _what_.

All contributions—bug fixes, docs, tests, or features—are welcome!

---

## 11  Troubleshooting

| Symptom | Fix |
|---------|-----|
| Multiple guest users appear | Ensure only one browser tab is open or disable LiveView hot-reload in prod |
| `mix ecto.create` fails | Check `DATABASE_URL`, Postgres running, correct credentials |
| Port 4000 already in use | `lsof -i :4000` then `kill -9 <PID>` |
| Docker build fails on assets | Delete `assets/node_modules` and rebuild |

---

## 12  Future Improvements / Roadmap

- ✅ Basic chat rooms & presence  
- ✅ User registration/login UI  
- ✅ Unit tests for Accounts & Sessions  
- ✅ Docker & docker-compose dev stack  
- ✅ Terraform sample for AWS Fargate  
- [ ] File & image sharing (S3)  
- [ ] Push notifications (Web + mobile)  
- [ ] End-to-end encrypted rooms  
- [ ] Admin dashboard & moderation tools  
- [ ] CI/CD pipeline (GitHub Actions)  
- [ ] Horizontal scaling example with Redis & clustering  

Have an idea? Open an issue or start a discussion!

---

Built with ❤️ on the BEAM. Enjoy chatting!
