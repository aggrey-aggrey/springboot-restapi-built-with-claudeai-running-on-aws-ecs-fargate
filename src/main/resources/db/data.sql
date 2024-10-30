INSERT IGNORE INTO authors (first_name, last_name, birth_date, nationality) VALUES
('Jane', 'Austen', '1775-12-16', 'British'),
('George', 'Orwell', '1903-06-25', 'British'),
('Gabriel', 'García Márquez', '1927-03-06', 'Colombian'),
('Chimamanda', 'Ngozi Adichie', '1977-09-15', 'Nigerian');

INSERT IGNORE INTO books (title, isbn, publication_year, genre, description, price) VALUES
('Pride and Prejudice', '9780141439518', 1813, 'Classic', 'A romantic novel of manners', 12.99),
('1984', '9780451524935', 1949, 'Dystopian Fiction', 'A dystopian social science fiction novel', 10.99),
('One Hundred Years of Solitude', '9780060883287', 1967, 'Magical Realism', 'A landmark of magical realism', 14.99),
('Americanah', '9780307455925', 2013, 'Contemporary Fiction', 'A powerful story of love and identity', 15.99),
('Animal Farm', '9780451526342', 1945, 'Political Satire', 'An allegorical novella', 9.99);

INSERT IGNORE INTO book_authors (book_id, author_id) VALUES
(1, 1),  -- Pride and Prejudice by Jane Austen
(2, 2),  -- 1984 by George Orwell
(3, 3),  -- One Hundred Years of Solitude by Gabriel García Márquez
(4, 4),  -- Americanah by Chimamanda Ngozi Adichie
(5, 2);  -- Animal Farm by George Orwell