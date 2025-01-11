FROM node:16.15.1-alpine  AS build
# set working directory
RUN mkdir /app
WORKDIR /app
# add `/usr/src/app/node_modules/.bin` to $PATH
#ENV PATH /usr/src/app/node_modules/.bin:$PATH
# install and cache app dependencies
COPY package.json /app/package.json
#COPY .envdocker /app/.env
# You only need to copy next.config.js if you are NOT using the default configuration
# COPY --from=builder /app/next.config.js ./
# COPY --from=builder next.config.js /app/next.config.js 
# To handle 'not get uid/gid'
RUN npm config set unsafe-perm true
#RUN npm install -g yarn
#RUN yarn install --force 
RUN rm -rf node_modules && rm -rf .next && rm -rf yarn.lock && rm -rf package-lock.json && yarn install 
COPY . .

RUN sed --in-place '/"type": "module",/d' node_modules/@react-google-maps/api/package.json

COPY .env.sample .env
# start app
RUN yarn build

FROM node:alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# You only need to copy next.config.js if you are NOT using the default configuration
# COPY --from=builder /app/next.config.js ./
COPY --from=build /app/public ./public
COPY --from=build --chown=nextjs:nodejs /app/.next ./.next
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/next.config.js ./next.config.js
COPY --from=build /app/next-i18next.config.js ./next-i18next.config.js

USER nextjs

EXPOSE 3000

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry.
ENV NEXT_TELEMETRY_DISABLED 1

# CMD ["yarn", "start"]
CMD ["yarn","start"]



### STAGE 2: Run ###
# FROM nginx:1.17.1-alpine
# COPY nginx.conf /etc/nginx/nginx.conf
# COPY --from=build /app/.next /usr/share/nginx/html
# COPY --from=build /app/.env.sample /usr/share/nginx/html/.env
# RUN apk add --update nodejs && apk add --update npm && npm i -g runtime-env-cra@0.2.0
# WORKDIR /usr/share/nginx/html
# EXPOSE 80
# CMD ["/bin/sh", "-c", "runtime-env-cra && nginx -g \"daemon off;\""]
