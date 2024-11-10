#!/bin/bash
# scripts/init-database.sh

set -e

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if environment is provided
ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Navigate to terraform directory
cd "$PROJECT_ROOT/terraform"

# Function to safely get Terraform output
get_terraform_output() {
    local output_name=$1
    local default_value=${2:-""}

    value=$(terraform output -raw "$output_name" 2>/dev/null || echo "$default_value")
    echo "$value"
}

# Get database endpoint and credentials
echo "Getting database information..."
DB_ENDPOINT=$(get_terraform_output "rds_endpoint")
DB_HOST=$(echo $DB_ENDPOINT | cut -d: -f1)
DB_PORT=$(echo $DB_ENDPOINT | cut -d: -f2 || echo "3306")
DB_NAME=$(get_terraform_output "db_name" "authors_books_${ENV}")
DB_USERNAME=$(get_terraform_output "db_username" "admin")
DB_PASSWORD=$(get_terraform_output "db_password")

# If we don't have credentials from Terraform, try environment variables
if [ -z "$DB_PASSWORD" ]; then
    echo "Database credentials not found in Terraform outputs, checking environment variables..."
    DB_USERNAME=${DB_USERNAME:-$DB_USER}  # Try environment variable
    DB_PASSWORD=${DB_PASSWORD:-$DB_PASS}  # Try environment variable

    # If still no credentials, ask user
    if [ -z "$DB_PASSWORD" ]; then
        echo "No database password found. Please enter database credentials:"
        read -p "Username (default: $DB_USERNAME): " input_username
        DB_USERNAME=${input_username:-$DB_USERNAME}
        read -s -p "Password: " DB_PASSWORD
        echo
    fi
fi

echo "Database connection details:"
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "Username: $DB_USERNAME"

# Wait for database to be available
echo "Waiting for database to be available..."
for i in {1..30}; do
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        echo "Database is available!"
        break
    fi
    echo "Waiting for database... ($i/30)"
    sleep 10

    if [ $i -eq 30 ]; then
        echo "Database did not become available in time"
        exit 1
    fi
done

# Create the schema
echo "Creating database schema..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" << "EOF"
-- Create authors table
CREATE TABLE IF NOT EXISTS authors (
    author_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create books table
CREATE TABLE IF NOT EXISTS books (
    book_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    publication_year INT,
    genre VARCHAR(100),
    description TEXT,
    price DECIMAL(10,2)
);

-- Create book_authors join table
CREATE TABLE IF NOT EXISTS book_authors (
    book_id BIGINT,
    author_id BIGINT,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);
EOF

# Insert sample data only in dev environment
if [ "$ENV" = "dev" ]; then
    echo "Inserting sample data..."
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" << "EOF"
-- Insert authors
INSERT INTO authors (first_name, last_name, birth_date, nationality) VALUES
('George', 'Orwell', '1903-06-25', 'British'),
('Virginia', 'Woolf', '1882-01-25', 'British'),
('Gabriel', 'García Márquez', '1927-03-06', 'Colombian'),
('Jane', 'Austen', '1775-12-16', 'British'),
('Ernest', 'Hemingway', '1899-07-21', 'American');

-- Insert books
INSERT INTO books (title, isbn, publication_year, genre, description, price) VALUES
('1984', '978-0451524935', 1949, 'Dystopian', 'A dystopian social science fiction novel', 19.84),
('Mrs. Dalloway', '978-0156628709', 1925, 'Modernist', 'A day in the life of Clarissa Dalloway', 21.00),
('One Hundred Years of Solitude', '978-0060883287', 1967, 'Magical Realism', 'The multi-generational story of the Buendía family', 22.99),
('Pride and Prejudice', '978-0141439518', 1813, 'Romance', 'The story of Elizabeth Bennet', 15.99),
('The Old Man and the Sea', '978-0684801223', 1952, 'Literary Fiction', 'The story of an aging Cuban fisherman', 18.99);

-- Insert book-author relationships
INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1), -- 1984 by George Orwell
(2, 2), -- Mrs. Dalloway by Virginia Woolf
(3, 3), -- One Hundred Years of Solitude by Gabriel García Márquez
(4, 4), -- Pride and Prejudice by Jane Austen
(5, 5); -- The Old Man and the Sea by Ernest Hemingway
EOF
fi

echo "Database initialization completed successfully!"

# Verify the data
echo -e "\nVerifying database setup..."
echo "Authors count:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM authors" "$DB_NAME"

echo "Books count:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM books" "$DB_NAME"

echo "Book-Author relationships:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM book_authors" "$DB_NAME"