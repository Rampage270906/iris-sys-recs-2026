For monitoring, I added Prometheus and Grafana to the setup and used cAdvisor to expose container metrics. Initially, I thought I could use only Prometheus and Grafana, but I understood that Prometheus doesn’t generate metrics on its own — it needs an exporter. cAdvisor provided container-level metrics, which Prometheus could scrape.

I ran into YAML indentation issues again while adding monitoring services — specifically, I accidentally nested Grafana under Prometheus, which caused validation errors. Fixing the indentation solved the issue.

Once everything was running, I verified metrics in Prometheus and visualized them in Grafana. I was able to see CPU, memory, and network usage for each container, including all three Rails instances. That confirmed the monitoring stack was functioning correctly.
