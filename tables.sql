CREATE TABLE IF NOT EXISTS account (
	account_id SERIAL UNIQUE,
	username varchar(40) UNIQUE PRIMARY KEY,
	account_number BIGINT UNIQUE NOT NULL,
	pass TEXT not NULL,
	first_name varchar(20) not NULL,
	last_name varchar(20) not NULL,
	national_id char(10) not NULL,
	date_of_birth date not NULL,
	account_type varchar(10) CHECK(account_type IN ('client', 'employee')),
	interest_rate float not NULL
);

CREATE SEQUENCE if not exists account_account_id
    start 1
    increment 1
    no maxvalue;
	
CREATE TABLE IF NOT EXISTS login_log (
	username varchar(20) references account(username),
	login_time timestamp
);

CREATE TABLE IF NOT EXISTS transactions (
	transaction_type varchar(10) CHECK(transaction_type IN('deposit', 'withdraw', 'transfer', 'interest')),
	transaction_time timestamp,
	from_account BIGINT references account(account_number),
	to_account BIGINT references account(account_number),
	amount numeric(16,2)
);

CREATE TABLE IF NOT EXISTS latest_balances (
	account_number BIGINT references account(account_number),
	amount numeric(20,2)
);

CREATE TABLE IF NOT EXISTS snapshot_log (
	snapshot_id SERIAL UNIQUE PRIMARY KEY,
	snapshot_timestamp timestamp
);

CREATE SEQUENCE if not exists snapshot_log_sequence
    start 1
    increment 1
    no maxvalue;
	
