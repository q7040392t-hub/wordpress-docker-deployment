FROM nginxinc/nginx-unprivileged:1.27-alpine
USER root
RUN rm -f /var/log/nginx/access.log /var/log/nginx/error.log \
    && touch /var/log/nginx/access.log /var/log/nginx/error.log \
    && chown -R 101:101 /var/log/nginx
USER 101:101
