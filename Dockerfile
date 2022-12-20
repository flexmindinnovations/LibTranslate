FROM python:3.8.14-slim-bullseye as builder

WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y pkg-config gcc g++ \
  && apt-get clean \
  && rm -rf /var/lib/apt

RUN apt-get update && apt-get upgrade --assume-yes

RUN python -mvenv venv && ./venv/bin/pip install --upgrade pip

COPY . .

# Install package from source code
RUN ./venv/bin/pip install . \
  && ./venv/bin/pip cache purge


FROM python:3.8.14-slim-bullseye

ARG with_models=false
ARG models=

RUN addgroup --system --gid 1032 libretranslate && adduser --system --uid 1032 libretranslate && mkdir -p /home/libretranslate/.local && chown -R libretranslate:libretranslate /home/libretranslate/.local
USER libretranslate

COPY --from=builder --chown=1032:1032 /app /app
WORKDIR /app

RUN if [ "$with_models" = "true" ]; then  \
  # initialize the language models
  if [ ! -z "$models" ]; then \
  ./venv/bin/python install_models.py --load_only_lang_codes "$models";   \
  else \
  ./venv/bin/python install_models.py;  \
  fi \
  fi

EXPOSE 5000
ENTRYPOINT [ "./venv/bin/libretranslate", "--host", "0.0.0.0" ]
