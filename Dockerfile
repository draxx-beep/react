# Step 1: Use the official Node.js image to build the React app
FROM node:16 AS build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy all the files of your React app
COPY . .

# Build the React app
RUN npm run build

# Step 2: Use Nginx to serve the built React app
FROM nginx:stable-alpine

# Copy the built files from the previous stage to the Nginx html folder
COPY --from=build /app/dist /usr/share/nginx/html

# Copy a custom Nginx configuration file if needed
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
