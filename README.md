# IRIS NITK Systems Recruitment 2026 — Round 2
This is my Round 2 submission. Instead of creating a separate repo, I continued on a new branch called round-2-infrastructure in the same Round 1 fork. This keeps the full git history showing progression from Round 1 to Round 2 in one place.

## Overview
The stack runs a Rails application across 3 replicas, load balanced by NGINX, backed by MySQL, with shared file storage across replicas, a full monitoring stack with live dashboards, and an automated daily backup service. Everything is orchestrated with Docker Compose. All 12 containers come up cleanly with a single docker compose up -d.
<img width="1919" height="935" alt="image" src="https://github.com/user-attachments/assets/6b160341-fa32-450c-95a8-1a26afebcadd" />
<img width="1919" height="242" alt="image" src="https://github.com/user-attachments/assets/e41274d0-5c0c-43cf-ac29-627ba1f113a6" />
<img width="1919" height="364" alt="image" src="https://github.com/user-attachments/assets/9fe6d12b-e076-4fa3-8ffb-5a6c57382d53" />

## Network Design
Instead of putting everything on one flat network, the stack is split into 4 isolated Docker bridge networks — public, application, storage, and monitoring. Each service only connects to the networks it strictly needs to do its job. MySQL for example only sits on the application network, meaning the monitoring stack has absolutely no network path to the database. The NFS server only sits on storage, so it's unreachable from the public or monitoring tiers entirely. This follows the Principle of Least Privilege — a compromise in one part of the stack doesn't automatically give access to everything else. NGINX is the only service attached to multiple networks because it genuinely needs to reach the Rails replicas, the monitoring services, and accept public traffic.
<img width="1920" height="1080" alt="Screenshot (99)" src="https://github.com/user-attachments/assets/c15375dd-a455-432e-b61b-e1ffa35dc2b2" />
<img width="1920" height="1080" alt="Screenshot (104)" src="https://github.com/user-attachments/assets/1be797e0-6f7e-4b76-9d1a-32155326906d" />

## NGINX — Load Balancing, Rate Limiting and Access Control
NGINX is the single entry point for all traffic. Port 8081 is the only host-exposed port for public traffic. It routes requests based on subdomains — app.localhost goes to the Rails cluster, grafana.localhost goes to Grafana, and prometheus.localhost goes to Prometheus, all on the same port.
The 3 Rails replicas sit behind an upstream block. NGINX round-robins requests across them and automatically pulls a replica out of rotation if it fails 3 times within 10 seconds. Rate limiting is enforced at 2 requests per second per IP with a burst allowance of 5. Anything beyond that is rejected with a 503 immediately, before the request even reaches Rails. Graceful reloads are supported via nginx -s reload — the config can be updated without dropping live connections.
Grafana and Prometheus are protected with HTTP Basic Auth using a bcrypt-hashed .htpasswd file. Neither service has a direct host port — the only way to reach them is through NGINX with valid credentials. This was a deliberate decision to avoid exposing internal tooling directly, even locally.
<img width="1920" height="1080" alt="Screenshot (106)" src="https://github.com/user-attachments/assets/b3ba7463-ef02-4668-af1b-6feda6b7fe97" />
<img width="1920" height="1080" alt="Screenshot (107)" src="https://github.com/user-attachments/assets/0acc9479-a9c2-44be-9143-c143be6823ee" />
<img width="932" height="230" alt="Screenshot 2026-03-18 153617" src="https://github.com/user-attachments/assets/9f81cb86-d9ee-42e0-93c1-f418ce772904" />
<img width="1920" height="1080" alt="Screenshot (115)" src="https://github.com/user-attachments/assets/e5f023c2-2ae6-427d-96dd-bea724b296dd" />

## Shared Storage
An NFS server container exports a shared directory over the storage network. All 3 Rails replicas mount this at /shared so uploaded files are accessible regardless of which replica handles a given request. This is important because without shared storage, a file uploaded while rails_app1 handled the request would be invisible to rails_app2 or rails_app3 on subsequent requests. Data persists across individual container restarts via a named Docker volume.
On Windows, this ran into two separate issues. First, the initial compose file used Windows absolute paths (C:\Users\sidda\...) which worked in PowerShell but broke entirely when running from Git Bash, which translates paths differently and was prepending the Git installation directory to the path, causing "directory not found" errors. This was fixed by switching to relative paths (./shared). Second, even with correct paths, the Linux NFS kernel module isn't available inside the WSL2 VM that Docker Desktop uses on Windows, so the NFS server container couldn't actually export over the kernel-level NFS protocol. The shared storage falls back to a bind mount on the host ./shared directory, which gives identical cross-replica consistency — all 3 replicas read and write to the same host directory regardless. The architecture is correct and the cross-replica consistency guarantee holds. Full NFS kernel-level testing requires a Linux host.
<img width="1920" height="1080" alt="Screenshot (99)" src="https://github.com/user-attachments/assets/5b5e7162-a562-4bfa-ba51-9f457c0b1bbf" />
<img width="1920" height="1080" alt="Screenshot (103)" src="https://github.com/user-attachments/assets/cddbdfa3-b3b8-441c-9530-ba0941a3a530" />

## Monitoring
Prometheus scrapes 4 targets every 15 seconds. cAdvisor provides per-container CPU, memory, and network metrics by reading directly from the Docker runtime. Node Exporter provides host-level metrics from the WSL2 VM. The NGINX Prometheus Exporter scrapes the stub_status endpoint on port 8888 and translates connection stats into Prometheus format. The Rails app scrape job is configured but currently returns connection refused since the Rails app doesn't have a Prometheus client library installed — it's kept in the config as a placeholder for future instrumentation.
Prometheus and Grafana are not port-exposed. They're only reachable via NGINX at their respective subdomains, protected by basic auth.
<img width="1920" height="1080" alt="Screenshot (116)" src="https://github.com/user-attachments/assets/b5d21bac-5842-40d4-8dbc-5113f2d523f5" />
<img width="1920" height="1080" alt="Screenshot (117)" src="https://github.com/user-attachments/assets/a9efebfc-d6a8-4b49-a372-9f16ffd83c63" />
Grafana is provisioned automatically with a Prometheus datasource via a provisioning file at grafana/provisioning/datasources/prometheus.yml. This means the datasource survives container recreates without any manual setup in the UI. The dashboard covers all 4 required metrics — CPU usage per container, memory usage per container, container restarts in the last hour, and NGINX request and error rate, all showing live data.
<img width="1916" height="901" alt="Screenshot 2026-03-20 223600" src="https://github.com/user-attachments/assets/488dbdf3-c7b3-4ab1-8083-13c473810c2b" />
<img width="1919" height="925" alt="Screenshot 2026-03-20 223608" src="https://github.com/user-attachments/assets/9124a5ef-cd63-46d7-92fc-4e0957cb9ae9" />
<img width="1917" height="913" alt="Screenshot 2026-03-20 223618" src="https://github.com/user-attachments/assets/c1a7ff60-0da6-4cfc-a4c2-c132a394ba2b" />
<img width="1919" height="918" alt="Screenshot 2026-03-20 223632" src="https://github.com/user-attachments/assets/99cf7310-931a-4618-b978-19e184f91b45" />
<img width="1917" height="909" alt="Screenshot 2026-03-20 223644" src="https://github.com/user-attachments/assets/0542669d-887b-4b7d-bc9e-71c9d28e2e2a" />
<img width="1919" height="905" alt="Screenshot 2026-03-20 223741" src="https://github.com/user-attachments/assets/58773870-9932-40cb-9ab5-fd7ba5a9c9e2" />

## Automated Backups
The backup service is a custom Docker image built on mysql:8.0 so it uses the same MySQL client version as the database, avoiding authentication plugin compatibility issues that came up when using Alpine's MariaDB client. It runs on a 24 hour loop — each run dumps the MySQL database using mysqldump with --ssl-mode=DISABLED (traffic stays inside the Docker network so TLS isn't needed) and --no-tablespaces (appuser doesn't have PROCESS privilege). It then archives the NFS shared storage directory and bundles both into a single timestamped .tar.gz file. It keeps the last 5 backups and automatically deletes anything older using a simple ls -t | tail -n +6 | xargs rm -f pattern.
<img width="1919" height="1020" alt="Screenshot 2026-03-20 224940" src="https://github.com/user-attachments/assets/23a7d276-6f5c-49e4-8d9f-9972a31e2f77" />
<img width="1919" height="972" alt="Screenshot 2026-03-20 224950" src="https://github.com/user-attachments/assets/f208bdb8-0e96-42a9-8e45-5544ebea4f4c" />
<img width="1919" height="1011" alt="Screenshot 2026-03-20 224919" src="https://github.com/user-attachments/assets/5b8b77c7-d28b-405f-8dbd-2d6dbd77be6e" />

## Secrets Management
All passwords and credentials are stored in a .env file which is gitignored. Docker Compose picks them up automatically via ${VAR} syntax in the compose file. Nothing is hardcoded in docker-compose.yml, backup.sh, or any config file. This is a basic but important production practice — the same compose file can be deployed in different environments just by swapping the .env file.

