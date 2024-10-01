import psycopg2


def print_menu():
    print("[1] REGISTER\n[2] LOGIN\n[3] DEPOSIT\n[4] WITHDRAW\n[5] TRANSFER\n[6] INTEREST_PAYMENT\n[7] "
          "UPDATE_BALANCES\n[8] CHECK_BALANCE\n[0] CLOSE")


def register(cu, co):
    password = input("password: ")
    first_name = input("first name: ")
    last_name = input("last name: ")
    national_id = input("national id: ")
    date_of_birth = input("date of birth(yyyy-mm-dd): ")
    account_type = input("account type(client or employee): ")
    interest_rate = input("interest rate: ")
    cu.execute("CALL register( %s,%s,%s,%s,%s,%s,%s)",
               (password, first_name, last_name, national_id, date_of_birth, account_type, interest_rate))
    co.commit()


def login(cu, co):
    username = input("username: ")
    password = input("password: ")
    cu.execute("CALL login( %s,%s);", (username, password))
    co.commit()


def deposit(cu, co):
    amount = input("amount(numeric(16,2)): ")
    cu.execute("CALL deposit( %s);", (amount,))
    co.commit()


def withdraw(cu, co):
    amount = input("amount(numeric(16,2)): ")
    cu.execute("CALL withdraw( %s);", (amount,))
    co.commit()


def transfer(cu, co):
    amount = input("amount(numeric(16,2)): ")
    to_account = input("Destination account number: ")
    cu.execute("CALL transfer( %s,%s);", (amount, to_account))
    co.commit()


def interest_payment(cu, co):
    cu.execute("CALL interest_payment();")
    co.commit()


def update_balances(cu, co):
    cu.execute("CALL update_balances();")
    co.commit()


def check_balance(cu, co):
    cu.execute("CALL check_balance();")
    co.commit()


if __name__ == '__main__':
    conn = psycopg2.connect(database="Bank",
                            host="Localhost",
                            user="postgres",
                            password="26561343")

    cursor = conn.cursor()

    while True:
        print_menu()
        choice = input()
        match choice:
            case "0":
                break
            case "1":
                register(cursor, conn)
            case "2":
                login(cursor, conn)
            case "3":
                deposit(cursor, conn)
            case "4":
                withdraw(cursor, conn)
            case "5":
                transfer(cursor, conn)
            case "6":
                interest_payment(cursor, conn)
            case "7":
                update_balances(cursor, conn)
            case "8":
                check_balance(cursor, conn)
        tmp = conn.notices
        print(tmp[-1])
    cursor.close()
    conn.close()
