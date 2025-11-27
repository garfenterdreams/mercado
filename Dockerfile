# Start your image with a node base image
FROM node:18-alpine

# Install mysql-client for database initialization and nginx for serving frontend
RUN apk --update add imagemagick mysql-client nginx

# This directory is the main application directory
WORKDIR /spurtcommerce-api

COPY . /spurtcommerce-api

# ENV NODE_ENV='dev'
ENV PUPPETEER_SKIP_DOWNLOAD=true

#
# APPLICATION
#
ENV APP_NAME='spurtcommerce-multivendor-4.8.4'
ENV APP_SCHEMA='http'
ENV APP_HOST='localhost'
ENV APP_PORT=8000
ENV APP_ROUTE_PREFIX='/api'
ENV APP_BANNER=true

ENV LOG_LEVEL=debug
ENV LOG_OUTPUT=dev

ENV TYPEORM_CONNECTION=mysql
ENV TYPEORM_HOST=mysql-database
ENV TYPEORM_PORT=3306
ENV TYPEORM_USERNAME=root
ENV TYPEORM_PASSWORD=picco123$
ENV TYPEORM_DATABASE=spurtcommerce
ENV TYPEORM_SYNCHRONIZE=false
ENV TYPEORM_LOGGING=""
ENV TYPEORM_LOGGER=advanced-console

ENV TYPEORM_MIGRATIONS=src/database/migrations/**/*.ts
ENV TYPEORM_MIGRATIONS_DIR=src/database/migrations
ENV TYPEORM_ENTITIES=src/api/models/**/*.ts,src/plugin-manager/models/**/*.ts
ENV TYPEORM_ENTITIES_DIR=src/api/models
ENV TYPEORM_SEEDING_FACTORIES=src/database/factories/**/*.ts
ENV TYPEORM_SEEDING_SEEDS=src/database/seeds/**/*.ts
ENV CONTROLLERS=src/api/controllers/**/*Controller.ts
ENV MIDDLEWARES=src/api/middlewares/**/*Middleware.ts
ENV INTERCEPTORS=src/api/interceptors/**/*Interceptor.ts
ENV SUBSCRIBERS=src/api/subscribers/**/*Subscriber.ts
ENV RESOLVERS=src/api/resolvers/**/*Resolver.ts

ENV APIDOC_ENABLED=true
ENV APIDOC_ROUTE=/apidoc

ENV MONITOR_ENABLED=true
ENV MONITOR_ROUTE=/monitor
ENV MONITOR_USERNAME=admin
ENV MONITOR_PASSWORD=1234

ENV SWAGGER_ENABLED=true
ENV SWAGGER_ROUTE=/swagger
ENV SWAGGER_FILE=api/swagger.json
ENV SWAGGER_USERNAME=admin
ENV SWAGGER_PASSWORD=1234

ENV STORE_URL=http://localhost:8000/api
ENV CANCEL_URL=http://localhost:8000/api
ENV BASE_URL=http://localhost:8000/api
ENV STORE_REDIRECT_URL=http://localhost
ENV ADMIN_REDIRECT_URL=http://localhost/admin
ENV VENDOR_REDIRECT_URL=http://localhost/vendor
ENV IMAGE_URL=IMAGE_URL
ENV STORE_FORGET_PASSWORD_URL=STORE_FORGET_PASSWORD_URL
ENV FORGET_PASSWORD_URL=FORGET_PASSWORD_URL

ENV LOGIN_ATTEPMTS_COUNT=5
ENV LOGIN_ATTEPMTS_MINUTES=30

ENV JWT_SECRET=1333@#$%123$%^&*dajcskdn89?)()#$@&haSS
ENV JWT_EXPIRY_TIME=7d
ENV CRYPTO_SECRET=da$*908nkkd3@^(&*fgdnNNMMod3?)()#$@&SYU

ENV AVAILABLE_IMAGE_TYPES='PNG,png,jpg,jpeg,svg,webp'
ENV AVAILABLE_ALLOW_TYPES='PDF,pdf,xlx,xlsx,doc,docx'
ENV IMAGE_SERVER=local
ENV IMAGE_UPLOAD_SIZE=2

ENV ADMIN_FORGET_PASSWORD_URL=http://localhost/admin/#/set-password/
ENV PRODUCT_REDIRECT_URL=http://localhost/products/productdetails/
ENV CATEGORY_REDIRECT_URL=http://localhost/products/
ENV PLUGIN_HOME_REDIRECT_URL=http://localhost/home
ENV VENDOR_FORGET_PASSWORD_URL=http://localhost/seller/#/auth/set-password
ENV VENDOR_MAIL_VERIFY_URL=http://localhost/seller/#/auth/verification

ENV VERIFICATION_CODE_EXPIRATION_TIME='00:10:00'

ENV MFA_TEMP_TOKEN_EXPIRY='120m'
ENV MFA_TEMP_TOKEN_SECRET='rMcq9hCJ;6a8oH('

ENV USER_NAME=''
ENV SENDER_NAME=''
ENV API_KEY=''
ENV HOST_NAME=''
ENV SMS_TYPE=''
ENV PEID=''
ENV TEMPLATE_ID=''

ENV SOCKET_PORT=4001
ENV KYC_MANDATE=0

# Payment redirect URLs
ENV PAYMENT_SUCCESS_REDIRECT_URL=http://localhost/payment-success
ENV PAYMENT_FAIL_REDIRECT_URL=http://localhost/payment-failed
ENV PAYMENT_CANCEL_REDIRECT_URL=http://localhost/payment-cancelled

# SSL/Mail settings (can be overridden at runtime)
ENV MAIL_DRIVER=''
ENV MAIL_HOST=''
ENV MAIL_PORT=''
ENV MAIL_USERNAME=''
ENV MAIL_PASSWORD=''
ENV MAIL_SECURE=''
ENV MAIL_FROM=''

# AWS S3 settings (optional, for S3 storage)
ENV AWS_ACCESS_KEY_ID=''
ENV AWS_SECRET_ACCESS_KEY=''
ENV AWS_DEFAULT_REGION=''
ENV AWS_BUCKET=''

# Install node packages, install serve, build the app, and remove dependencies at the end
RUN npm install \
    && npm run build \
    && npx javascript-obfuscator ./dist --output ./dist-obf \
    && cp  -r ./dist/package.json ./dist-obf/package.json \
    && cp  -r ./dist/src/public/apidoc/css ./dist-obf/src/public/apidoc/css \
    && cp  -r ./dist/src/public/apidoc/fonts ./dist-obf/src/public/apidoc/fonts \
    && cp  -r ./dist/src/public/apidoc/img ./dist-obf/src/public/apidoc/img \
    && cp  -r ./dist/src/api/swagger.json ./dist-obf/src/api/swagger.json \
    && cp  -r ./dist/src/public/favicon.ico ./dist-obf/src/public/favicon.ico \
    && (test -d ./dist/add-ons/Payment/Paypal/template && cp -r ./dist/add-ons/Payment/Paypal/template ./dist-obf/add-ons/Payment/Paypal/ || true) \
    && (test -d ./dist/add-ons/Payment/Razorpay/template && cp -r ./dist/add-ons/Payment/Razorpay/template ./dist-obf/add-ons/Payment/Razorpay/ || true) \
    && (test -d ./dist/add-ons/Payment/Stripe/template && cp -r ./dist/add-ons/Payment/Stripe/template ./dist-obf/add-ons/Payment/Stripe/ || true) \
    && rm -rf src \
    && rm -rf add-ons \
    && rm -rf commands \
    && rm -rf package.json \
    && rm -rf package-lock.json \
    && rm -rf dist

# Copy SQL schema for database initialization (keep it for entrypoint)
COPY spurtcommerce_v5.2_community.sql /spurtcommerce-api/init.sql

# Setup frontend - Admin and Vendor panels
RUN mkdir -p /var/www/html
COPY frontend/admin /var/www/html/admin
COPY frontend/seller /var/www/html/seller

# Setup nginx configuration
COPY nginx.conf /etc/nginx/http.d/default.conf
RUN rm -f /etc/nginx/http.d/default.conf.bak 2>/dev/null || true

# Copy and set up entrypoint script
COPY entrypoint.sh /spurtcommerce-api/entrypoint.sh
RUN chmod +x /spurtcommerce-api/entrypoint.sh

# Expose ports: 80 for nginx (frontend + API proxy), 8000 for API direct, 4001 for socket
EXPOSE 80 8000 4001

# Use entrypoint for database initialization and starting services
ENTRYPOINT ["/spurtcommerce-api/entrypoint.sh"]
