In this task, I configured Nginx as a reverse proxy in front of the Rails application. The objective was to prevent direct access to the Rails container and ensure that all incoming requests pass through Nginx. I added an Nginx service to Docker Compose and created a configuration file that forwards requests to the Rails container inside the Docker network. 

At first, I encountered issues where localhost displayed an Apache default page instead of my application. After investigation, I realized port 80 was already being used by another service on my system. Changing the exposed port for Nginx resolved the issue. 

The Rails application was no longer directly accessible. All traffic was routed through Nginx successfully, achieving proper reverse proxy behavior.
