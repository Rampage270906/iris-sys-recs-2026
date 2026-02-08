FROM ruby:3.4.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    npm && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler

COPY Gemfile ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
