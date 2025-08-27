FROM oven/bun:1.1.31-alpine AS base
WORKDIR /app
COPY app.mjs ./
EXPOSE 8080
ENV NODE_ENV=production
CMD ["bun", "run", "app.mjs"]
