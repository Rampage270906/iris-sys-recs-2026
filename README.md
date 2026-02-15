In this task, the Ruby on Rails application was containerized using Docker to create a consistent and reliable runtime environment, regardless of the host system it runs on.

To achieve this, a Dockerfile was added to the project repository. This file defines how the Docker image should be built. It specifies the Ruby version, installs the necessary system dependencies, copies the application’s source code into the container, installs the required gems using Bundler, and finally starts the Rails server so the application can run inside the container.

While setting up Docker, some dependency conflicts were discovered in the Gemfile. Certain explicitly listed Rails component dependencies were incompatible with the Rails version used in the project. These were removed, allowing Bundler to correctly resolve and install all required gems during the Docker build process. Fixing these conflicts was essential for successfully building and running the application inside the container.

As a result, the Rails application was successfully built and can run as a standalone Docker image. There is no longer a need to install Ruby or Rails on the host machine, making the setup process simpler and more portable.
