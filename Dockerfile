# Use a lightweight Node.js 20 image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy the rest of the source code
COPY . .

# Expose the port your app will run on
EXPOSE 8080

# Start the backend
CMD ["node", "app.js"]