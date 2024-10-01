CREATE EXTENSION if not exists pgcrypto;

CREATE OR REPLACE PROCEDURE register(pass TEXT, first_name varchar, last_name varchar,
											 national_id char, date_of_birth date, account_type varchar, interest_rate varchar)
	LANGUAGE PLPGSQL
	AS $$
	declare
	age int = date_part('year', age(date_of_birth));
	BEGIN
		if age < 13 then
			RAISE NOTICE 'Sorry, your age is under 13 so you can not make account.';
			return;
		end if;
		if CONCAT(first_name, last_name) in (select username from account) THEN
			RAISE NOTICE 'You already have an account.';
			return;
		else
			INSERT INTO account(account_number, pass, first_name, last_name, national_id, date_of_birth, account_type, interest_rate)
			VALUES ('0', pass, first_name, last_name, national_id, date_of_birth, account_type, CAST(interest_rate AS FLOAT));
			RAISE NOTICE 'DONE.';
		end if;
	END;
	$$
;


CREATE OR REPLACE FUNCTION insert_to_account()
	RETURNS TRIGGER 
	LANGUAGE plpgsql
	AS $$
	BEGIN
		NEW.username = CONCAT(NEW.first_name, NEW.last_name);
		New.pass = crypt(NEW.pass, gen_salt('bf'));
		NEW.account_number = NEW.account_id + 6037990000000000;
		IF NEW.account_type = 'employee' then
			New.interest_rate = '00.0';
		END IF;
		return new;
	END;
	$$
;


CREATE OR REPLACE FUNCTION set_initial_balance()
	RETURNS TRIGGER 
	LANGUAGE plpgsql
	AS $$
	BEGIN
		INSERT INTO latest_balances VALUES (NEW.account_number, '0');
		return new;
	END;
	$$
;
	
	
CREATE or replace TRIGGER insert_to_account_tg
	before INSERT
	ON account
	FOR EACH ROW
	EXECUTE FUNCTION insert_to_account();
	
	
CREATE or replace TRIGGER set_initial_balance_tg
	after INSERT
	ON account
	FOR EACH ROW
	EXECUTE FUNCTION set_initial_balance();
	
	
CREATE OR REPLACE PROCEDURE login(input_username varchar, input_pass TEXT)
	LANGUAGE PLPGSQL
	AS $$
	begin
		if exists(select account.username from account where account.username = input_username 
				  and account.pass = crypt(input_pass,account.pass)) THEN
			insert into login_log values(input_username, CURRENT_TIMESTAMP);
			RAISE NOTICE 'DONE.';
		else
			RAISE NOTICE 'Wrong username ro password.';
		end if;
	END;
	$$
;
	
	
CREATE OR REPLACE PROCEDURE deposit(amount numeric)
	LANGUAGE PLPGSQL
	AS $$
	declare
		account_number bigint := (select account.account_number from account natural join login_log order by login_time desc limit 1);
	BEGIN
		if account_number is null then
			RAISE NOTICE 'No account has logged in yet.';
		else
			INSERT INTO transactions(transaction_type, transaction_time, to_account, amount)
			VALUES('deposit', CURRENT_TIMESTAMP, account_number, amount);
			RAISE NOTICE 'DONE.';
		end if;
	END;
	$$
;
	
	
CREATE OR REPLACE PROCEDURE withdraw(amount numeric)
	LANGUAGE PLPGSQL
	AS $$
	declare
		account_number bigint := (select account.account_number from account natural join login_log order by login_time desc limit 1);
	BEGIN
		if account_number is null then
			RAISE NOTICE 'No account has logged in yet.';
		else
			INSERT INTO transactions(transaction_type, transaction_time, from_account, amount)
			VALUES('withdraw', CURRENT_TIMESTAMP, account_number, amount);
			RAISE NOTICE 'DONE.';
		end if;
	END;
	$$
;
	

CREATE OR REPLACE PROCEDURE transfer(amount numeric, to_account bigint)
	LANGUAGE PLPGSQL
	AS $$
	declare
		from_account bigint := (select account.account_number from account natural join login_log order by login_time desc limit 1);
	BEGIN
		if from_account is null then
			RAISE NOTICE 'No account has logged in yet.';
			
		elsif(EXISTS(select account.account_number from account where account.account_number = to_account)) then
			INSERT INTO transactions(transaction_type, transaction_time, from_account, to_account, amount)
			VALUES('transfer', CURRENT_TIMESTAMP, from_account, to_account, amount);
			RAISE NOTICE 'DONE.';
		ELSE
			RAISE NOTICE 'Invalid account number.';
		end if;
	END;
	$$
;


CREATE OR REPLACE PROCEDURE interest_payment()
	LANGUAGE PLPGSQL
	AS $$
	declare
		f record;
		user_type varchar := (select account.account_type from account natural join login_log order by login_time desc limit 1);
	BEGIN
		if user_type is null then
			RAISE NOTICE 'No account has logged in yet.';
			return;
		elsIF user_type = 'client' then
			RAISE NOTICE 'client can not do this operation';
			return;
		end if;
		FOR f in select account_number, amount, interest_rate  from latest_balances natural join account where account_type = 'client'
		loop
		INSERT INTO transactions(transaction_type, transaction_time, to_account, amount)
		VALUES('interest', CURRENT_TIMESTAMP, f.account_number, f.amount*f.interest_rate*0.01);
		end loop;
		RAISE NOTICE 'DONE.';
	END;
	$$
;


CREATE OR REPLACE PROCEDURE check_balance()
	LANGUAGE PLPGSQL
	AS $$
	declare
		balance numeric := (select amount from latest_balances as l where l.account_number = 
					(select account.account_number from account natural join login_log order by login_time desc limit 1));
	BEGIN
		if balance is null then
			RAISE NOTICE 'No account has logged in yet.';
		else
			RAISE NOTICE 'your balance in latest blances: %', balance;
		end if;
	END;
	$$
;
	

CREATE OR REPLACE PROCEDURE update_balances()
	LANGUAGE PLPGSQL
	AS $$
	DECLARE
		e record;
		time_of_last_snapshot timestamp := (SELECT snapshot_timestamp from snapshot_log order by snapshot_timestamp desc limit 1);
		from_account_balance numeric;
		user_type varchar := (select account.account_type from account natural join login_log order by login_time desc limit 1);
	BEGIN
		IF user_type = 'client' then
			RAISE NOTICE 'client can not do this operation';
			return;
		end if;
		
		for e in select * from transactions where time_of_last_snapshot is null or transaction_time > time_of_last_snapshot
		loop
		from_account_balance := (select amount from latest_balances where latest_balances.account_number = e.from_account);
		
		if e.transaction_type = 'deposit' then
			update latest_balances
			set amount = amount + e.amount
			where e.to_account = latest_balances.account_number;

		elsif e.transaction_type = 'interest' then
			update latest_balances
			set amount = amount + e.amount
			where e.to_account = account_number;

		elsif from_account_balance < e.amount then
			RAISE NOTICE 'Invalid transaction.';

		elsif e.transaction_type = 'withdraw' then
			update latest_balances
			set amount = amount - e.amount
			where e.from_account = account_number;

		elsif e.transaction_type = 'transfer' then
			update latest_balances
			set amount = amount - e.amount
			where e.from_account = account_number;

			update latest_balances
			set amount = amount + e.amount
			where e.to_account = account_number;
		end if;
		end loop;
		
		insert into snapshot_log(snapshot_timestamp) values(CURRENT_TIMESTAMP);
		EXECUTE format('CREATE TABLE %I AS TABLE latest_balances', 'snapshot_' || (select max(snapshot_id) from snapshot_log));
		RAISE NOTICE 'DONE.';
	END;
	$$
;