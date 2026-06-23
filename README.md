# Teamable

Teamable is a small full-stack application for managing employee profiles.

## Requirements

This project is intended for Ubuntu systems. The setup script supports Ubuntu versions:

- Ubuntu 20.04 (Focal)
- Ubuntu 22.04 (Jammy)
- Ubuntu 24.04 (Noble)

In case you want to run the application on another system, you will have to download MongoDB manually.

You also need:

- Node.js
- npm
- MongoDB

## Installation

1. Clone the repository.
2. Install dependencies:

   ```bash
   npm install
   ```

3. Configure MongoDB:

   ```bash
   sudo ./setup-mongodb.sh
   ```

The setup script installs MongoDB, starts the service, and creates the required database and collection for the application.

## Running the application

### Development mode

This mode disables authentication and is intended for local testing or non-production environments:

```bash
DEV=true npm start
```

### Production mode

For production, provide database credentials and run the application with authentication enabled:

```bash
sudo DB_USER=my_user DB_PASS=my_password ./setup-mongodb.sh
DB_USER=my_user DB_PASS=my_password npm start
```

The application expects:

- MongoDB on `127.0.0.1:27017`
- database `company_db`
- collection `employees`

## Testing

Run the test suite with:

```bash
npm test
```

## Packaging

To create a package archive:

```bash
npm pack
```

The application listens on port `3000`.
