FROM quay.io/fundingcircle/alpine-ruby:2.3 as builder

RUN apk --no-cache add \
  cmake \
  linux-headers \
  nodejs \
  postgresql-dev \
  sqlite-dev \
  tzdata \
  zlib-dev \
 && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.8/main \
  libgit2-dev \
  libssh2-dev

WORKDIR /tmp
COPY Gemfile* ./
RUN bundle config build.rugged --use-system-libraries \
 && bundle install --deployment --without deployment dockerignore

ARG RAILS_ENV=production

COPY Rakefile ./

COPY \
 config/application.rb \
 config/boot.rb \
 config/environment.rb \
 config/

COPY config/environments/production.rb config/environments/

COPY app/assets app/assets
COPY vendor/assets vendor/assets

RUN DATABASE_URL=postgresql:/// bundle exec rake assets:precompile

FROM quay.io/fundingcircle/alpine-ruby:2.3
LABEL maintainer="Funding Circle Engineering <engineering@fundingcircle.com>"

RUN apk --no-cache add \
  nodejs \
  postgresql \
  postgresql-client \
  sqlite-dev \
  tzdata \
  zlib \
 && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.8/main \
  libgit2 \
  libssh2

RUN addgroup -g 1101 -S shipment_tracker && \
  adduser -S -u 1101 -h /app -G shipment_tracker shipment_tracker

USER shipment_tracker

WORKDIR /app

COPY --from=builder --chown=shipment_tracker:shipment_tracker /tmp .
COPY --chown=shipment_tracker:shipment_tracker docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chown=shipment_tracker:shipment_tracker docker/dropzone.yaml /usr/local/deploy/dropzone.yaml
COPY --chown=shipment_tracker:shipment_tracker config/database.yml.erb config/database.yml
COPY --chown=shipment_tracker:shipment_tracker . .

ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint.sh"]
