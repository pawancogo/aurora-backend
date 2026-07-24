# Development image for the Rails API.
# Production image will be added in Sprint 17 (multi-stage, non-root, precompiled).
FROM ruby:3.4.2-slim

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    LANG=C.UTF-8

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
       build-essential libpq-dev git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3001
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3001"]
