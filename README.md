This task involved scaling the Rails application to run multiple containers and configuring Nginx to load balance requests across them. I used Docker Compose scaling to run three Rails containers and updated the Nginx configuration to forward traffic to a cluster of Rails services.

One major issue I faced was that scaling failed because I had defined a fixed container name for the Rails service. Docker cannot create multiple containers with the same name. Removing the fixed container name resolved the scaling issue. 

Three Rails containers successfully ran behind a single Nginx reverse proxy. Requests were distributed across them, demonstrating effective load balancing.
