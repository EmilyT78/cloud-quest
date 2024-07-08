# Declaring Node v13 base image with Linux alpine OS
FROM node:13-alpine

# Set env variable from the quest
ENV SECRET_WORD=TwelveFactor

# Set current working directory
WORKDIR /app

# Copy dependencies into the container
COPY package.json ./

# Copy bin/ and src/ dir + code content into the container
COPY /bin ./bin
COPY /src ./src

# Install dependencies
RUN npm install

# Expose the port for documentation purposes (as it is already defined in the app)
EXPOSE 3000

# Command to start the app within the container
CMD [ "npm", "start" ]