def insert_db_data(conn, data, table_name, add_ids=False):
    cursor = conn.cursor()

    try:
        cursor.execute(f"SHOW COLUMNS FROM {table_name}")
        columns = cursor.fetchall()
    except Exception as e:
        print(f"Failed to retrieve table columns: {e}")
        return

    column_names = []
    for col in columns:
        if 'auto_increment' not in col[5].lower():
            column_names.append(col[0])

    if len(column_names) != len(data[0]):
        print(f"Mismatch: Table requires {len(column_names)} columns, but data contains {len(data[0])} values.")
        return

    placeholders = ", ".join(["%s"] * len(column_names))
    column_list = ", ".join(column_names)
    insert_query = f"INSERT INTO {table_name} ({column_list}) VALUES ({placeholders})"
    print(insert_query)

    try:
        cursor.executemany(insert_query, data)
        conn.commit()
        print(f"{cursor.rowcount} rows inserted into {table_name}.")
    except Exception as e:
        conn.rollback()
        print(f"Failed to insert data into {table_name}: {e}")
    finally:
        cursor.close()
