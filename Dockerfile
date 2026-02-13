FROM ruby:3.4

# Install system dependencies required by Rails + mysql2 + nokogiri
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  default-libmysqlclient-dev \
  libxml2-dev \
  libxslt1-dev \
  nodejs \
  curl \
  && rm -rf /var/lib/apt/lists/*

# Set bundler environment (prevents permission issues)
ENV BUNDLE_PATH=/gems \
    BUNDLE_BIN=/gems/bin \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

WORKDIR /app

# Install bundler explicitly (stable)
RUN gem install bundler

# Copy dependency files first (Docker cache-friendly)
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the app
COPY . .

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
