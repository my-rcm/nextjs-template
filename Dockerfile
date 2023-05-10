FROM node:18.16.0-alpine AS base
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED 1

FROM base AS deps
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Build the application
FROM base AS builder
COPY . .
COPY --from=deps /app/node_modules ./node_modules
RUN apk --no-cache add openssl && \
    yarn build

FROM base AS runner

ARG APP_ENV=production
ARG NODE_ENV=production
ARG PORT=3000

ENV APP_ENV=${APP_ENV} \
    NODE_ENV=${NODE_ENV} \
    PORT=${PORT}

RUN addgroup --gid 1001 --system nodejs && \
    adduser --system nextjs --uid 1001 --ingroup nodejs && \
    chown -R nextjs:nodejs /app

USER nextjs

COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

VOLUME /app/.next/cache/images

EXPOSE ${PORT}

CMD ["yarn", "start"]
