#!/bin/bash

set -e

DB_NAME="company_db"
DB_USER="${DB_USER:-teamable_user}"
DB_PASS="${DB_PASS:-teamable_pass}"
ENABLE_AUTH="${ENABLE_AUTH:-false}"

echo "=== Teamable: MongoDB setup ==="

# Script must run as root (use sudo).
if [ "$EUID" -ne 0 ]; then
    echo "Run this script as root, e.g.: sudo ./setup-mongodb.sh"
    exit 1
fi

# Detect Ubuntu codename (Linux Mint exposes it as UBUNTU_CODENAME).
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

UBUNTU_CODENAME="${UBUNTU_CODENAME:-noble}"

case "$UBUNTU_CODENAME" in
    noble|jammy|focal)
        echo "Using Ubuntu repository for: $UBUNTU_CODENAME"
        ;;
    *)
        echo "Unsupported or unknown release ($UBUNTU_CODENAME)."
        echo "Supported releases: noble (24.04), jammy (22.04), focal (20.04)."
        exit 1
        ;;
esac

echo ""
echo "=== 1/4 Install MongoDB Community Edition (official mongodb-org packages) ==="

# Official docs recommend removing the conflicting Ubuntu mongodb package first.
if dpkg -l mongodb 2>/dev/null | grep -q "^ii"; then
    echo "Removing conflicting mongodb package..."
    apt-get remove -y mongodb
fi

# Official docs step: install gnupg and curl.
apt-get update
apt-get install -y gnupg curl

# Official docs step: import the MongoDB 8.0 public GPG key.
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor

# Official docs step: add the official APT repository.
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/8.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-8.0.list

# Official docs step: refresh package list and install mongodb-org.
apt-get update

if ! command -v mongod >/dev/null 2>&1; then
    apt-get install -y mongodb-org
else
    echo "MongoDB (mongod) is already installed, skipping package installation."
fi

echo ""
echo "=== 2/4 Start the mongod service ==="

# Official docs step: start mongod and enable it on boot.
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

echo "Waiting for MongoDB to listen on port 27017..."
for i in $(seq 1 30); do
    if mongosh --quiet --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q "1"; then
        echo "MongoDB is running."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "MongoDB did not start in time. Check: sudo systemctl status mongod"
        exit 1
    fi
    sleep 1
done

echo ""
echo "=== 3/4 Prepare the database for the back-end ==="

# Create company_db with a temporary write (MongoDB creates the database on first use).
mongosh --quiet <<EOF
use ${DB_NAME}
db.employees.updateOne(
    { id: 0 },
    { \$set: { id: 0, _setup: true } },
    { upsert: true }
)
db.employees.deleteOne({ id: 0 })
EOF

echo "Database '${DB_NAME}' is ready."

echo ""
echo "=== 4/4 Optional authentication for production ==="

if [ "$ENABLE_AUTH" = "true" ]; then
    echo "Enabling authentication for user: ${DB_USER}"

    # Create the user before enabling authorization in mongod.conf.
    mongosh --quiet <<EOF
use ${DB_NAME}
const existingUser = db.getUser("${DB_USER}")
if (existingUser === null) {
    db.createUser({
        user: "${DB_USER}",
        pwd: "${DB_PASS}",
        roles: [{ role: "readWrite", db: "${DB_NAME}" }]
    })
    print("User ${DB_USER} created.")
} else {
    print("User ${DB_USER} already exists, skipping creation.")
}
EOF

    # Enable authentication per official docs (security.authorization).
    if ! grep -q "authorization: enabled" /etc/mongod.conf; then
        if grep -q "^security:" /etc/mongod.conf; then
            sed -i '/^security:/a\  authorization: enabled' /etc/mongod.conf
        else
            printf '\nsecurity:\n  authorization: enabled\n' >> /etc/mongod.conf
        fi
    fi

    systemctl restart mongod

    for i in $(seq 1 30); do
        if mongosh --quiet -u "${DB_USER}" -p "${DB_PASS}" --authenticationDatabase "${DB_NAME}" \
            --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q "1"; then
            echo "Authentication is working."
            break
        fi
        if [ "$i" -eq 30 ]; then
            echo "Failed to verify login for user ${DB_USER}."
            exit 1
        fi
        sleep 1
    done

    echo ""
    echo "Start the application in production mode:"
    echo "  DB_USER=${DB_USER} DB_PASS=${DB_PASS} npm start"
else
    echo "Authentication is disabled (suitable for development)."
    echo ""
    echo "Start the application in development mode:"
    echo "  DEV=true npm start"
    echo ""
    echo "To enable authentication, run again with:"
    echo "  sudo ENABLE_AUTH=true DB_USER=my_user DB_PASS=my_password ./setup-mongodb.sh"
fi

echo ""
echo "=== Done ==="
echo "MongoDB is running on 127.0.0.1:27017"
echo "Database: ${DB_NAME}"
echo "Collection: employees"
