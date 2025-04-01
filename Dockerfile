FROM node:latest
WORKDIR /app
EXPOSE 3000
COPY . .
RUN npm install
RUN npm run build
ENTRYPOINT npm run start