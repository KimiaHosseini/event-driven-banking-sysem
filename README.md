# event-driven-banking-sysem

This is a basic banking system application that implements core functionalities like user registration, login, deposits, withdrawals, and transfers. It is built using Python with PostgreSQL as the database. The project uses an event-driven approach, meaning that specific events (e.g., a transaction) trigger stored procedures in the database, ensuring that account balances and transactions are up-to-date.

## Features
User Registration: Allows new users to register with necessary details.
Login: Users can log in to their accounts securely.
Deposit: Add money to the user's account balance.
Withdraw: Remove money from the user's account.
Transfer: Transfer money between accounts.
Interest Payment: Handles interest payments based on the user's account type and interest rate.
Balance Update: Updates account balances after each transaction.
Check Balance: Displays the current balance for a user's account.

## Project Structure
main.py: The main Python script that handles user inputs, interacts with the database, and calls the appropriate stored procedures.
tables.sql: Contains SQL queries to create the necessary tables for the banking system.
procedures.sql: Contains SQL stored procedures for handling events like deposits, withdrawals, transfers, etc.
