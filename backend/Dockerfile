FROM node:22-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
COPY public ./public
RUN npm run build
ENV NODE_ENV=production
EXPOSE 4000
CMD ["node", "dist/server.js"]
