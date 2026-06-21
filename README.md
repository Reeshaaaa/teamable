# teamable
This is an application for managing employee profiles.

NPM, Node.js and MongoDB are required

### MongoDB setup

The back-end expects:

- MongoDB on `127.0.0.1:27017`
- database `company_db`
- collection `employees` (created automatically on first write)

Use `setup-mongodb.sh` to install and configure MongoDB.

    sudo ./setup-mongodb.sh

Development without authentication (uses the `DEV` variable in `server.js`):

    DEV=true npm start

Production mode with authentication:

    sudo ENABLE_AUTH=true DB_USER=my_user DB_PASS=my_password ./setup-mongodb.sh
    DB_USER=my_user DB_PASS=my_password npm start

### To run the tests execute

    npm run test

### To package the application execute

    npm pack

Application runs on port 3000
