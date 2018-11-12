FROM quay.io/fundingcircle/alpine-ruby:2.3 as builder

RUN apk --no-cache add \
  cmake \
  linux-headers \
  sqlite-dev \
  zlib-dev \
 && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.8/main \
  libgit2-dev \
  libssh2-dev \
 && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.3/main \
  postgresql-dev==9.4.15-r0

WORKDIR /tmp
COPY Gemfile* ./
RUN bundle config build.rugged --use-system-libraries \
 && bundle install --deployment --without deployment dockerignore

FROM quay.io/fundingcircle/alpine-ruby:2.3
LABEL maintainer="Funding Circle Engineering <engineering@fundingcircle.com>"

RUN apk --no-cache add \
  nodejs \
  sqlite-dev \
  tzdata \
  zlib \
 && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.8/main \
  libgit2 \
  libssh2 \
 && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.3/main \
  libpq==9.4.15-r0 \
  postgresql-client==9.4.15-r0 \
  postgresql==9.4.15-r0 \
 && addgroup -g 1101 -S shipment_tracker && \
  adduser -S -u 1101 -h /app -G shipment_tracker shipment_tracker

USER shipment_tracker

WORKDIR /app

RUN touch .env.development

COPY --from=builder --chown=shipment_tracker:shipment_tracker /tmp .
COPY --chown=shipment_tracker:shipment_tracker config/database.yml.erb config/database.yml
COPY --chown=shipment_tracker:shipment_tracker . .
