ARG TOMASZ_VERSION=0.35
FROM ghcr.io/rutkowski-tomasz/cod2-server-1.3:${TOMASZ_VERSION}
ARG TOMASZ_VERSION

USER root

RUN git init -q /tmp/tomasz \
    && git -C /tmp/tomasz fetch -q --depth 1 https://github.com/rutkowski-tomasz/cod2-server.git "refs/tags/v$TOMASZ_VERSION:refs/tags/v$TOMASZ_VERSION" \
    && git -C /tmp/tomasz checkout -q "v$TOMASZ_VERSION" \
    && git init -q /libcod \
    && git -C /libcod fetch -q --depth 1 https://github.com/ibuddieat/zk_libcod.git "$(cat /tmp/tomasz/server/UPSTREAM)" \
    && git -C /libcod checkout -q FETCH_HEAD \
    && git -C /libcod apply /tmp/tomasz/server/hooks.patch \
    && cp -r /tmp/tomasz/server/extra/. /libcod/code/extra/ \
    && rm -rf /tmp/tomasz

# Our module and the registration of its GSC methods in the cod2-server method table
# (nl_functions.cpp, prototypes in nl.hpp).
COPY extra /libcod/code/extra
COPY back2uo_methods.patch /tmp/
RUN git -C /libcod apply /tmp/back2uo_methods.patch \
    && rm /tmp/back2uo_methods.patch

WORKDIR /libcod/code
RUN ./doit.sh mysql1 nospeex unsafe http \
    && cp bin/libcod2.so /cod2/libcod.so \
    && chown cod2:cod2 /cod2/libcod.so \
    && cd / && rm -rf /libcod

WORKDIR /cod2
USER 1001:1002
