#!/bin/bash

DEV=${DEV:-true}

sudo apt-get install gnupg curl

curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    UBUNTU_CODENAME="noble"
fi

if [ "$UBUNTU_CODENAME" = "noble" ]; then
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
elif [ "$UBUNTU_CODENAME" = "jammy" ]; then
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
elif [ "$UBUNTU_CODENAME" = "focal" ]; then
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
else
    echo "Unsupported or unknown Ubuntu release: $UBUNTU_CODENAME"
    exit 1
fi

apt-get update

apt-get install -y mongodb-org

if ! systemctl start mongod; then
    systemctl daemon-reload
    systemctl start mongod
fi

if [ "${DEV:-true}" = "true" ]; then
    echo "Creating MongoDB database and collection for development mode..."
    mongosh --quiet --eval "const targetDb = db.getSiblingDB('company_db'); if (!targetDb.getCollectionNames().includes('employees')) { targetDb.createCollection('employees') }; targetDb.employees.createIndex({ id: 1 }, { unique: true, sparse: true })"
else
    echo "Creating MongoDB database and collection for production mode..."
    mongosh --quiet -u "${DB_USER}" -p "${DB_PASS}" --authenticationDatabase "company_db" --eval "const targetDb = db.getSiblingDB('company_db'); if (!targetDb.getCollectionNames().includes('employees')) { targetDb.createCollection('employees') }; targetDb.employees.createIndex({ id: 1 }, { unique: true, sparse: true })"
fi

systemctl enable mongod
