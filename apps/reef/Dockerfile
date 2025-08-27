FROM oven/bun:1.1.31-alpine
WORKDIR /app
COPY server.mjs ./server.mjs
COPY public ./public
EXPOSE 8080
CMD ["bun", "run", "server.mjs"]
