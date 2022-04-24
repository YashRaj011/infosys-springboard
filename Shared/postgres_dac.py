import sys
import traceback
from typing import Generator

import psycopg2 as pg
import psycopg2.extras

from wingspan.common import wingspan_logger
from wingspan.common.config import Config


config = Config.get_config()
logger = wingspan_logger.get_logger()


postgres_dac_dict = {}


def get_postgres_dac(dac_name):
    if postgres_dac_dict.get(dac_name) is None:
        postgres_dac_dict[dac_name] = PostgreDAC(dac_name)
    return postgres_dac_dict[dac_name]


class PostgreDAC:
    postgres_dbname = {
        'postgres_general': 'wingspan',
        'postgres_critical': 'wingspan',
        'postgres_pid': 'pid',
        'postgres_schedulo': 'lmsdb'
    }

    def __init__(self, dac_name):
        self.connection = None
        self.dac_name = dac_name
        self.host = config.get(dac_name + '_host', None)
        self.port = config.get(dac_name + '_port', None)
        self.user = config.get(dac_name + '_user', None)
        self.password = config.get(dac_name + '_password', None)

    def set_client(self):
        self.connection = pg.connect(
            "host=%s port=%s dbname=%s"
            " user=%s password=%s"
            % (
                self.host,
                self.port,
                self.postgres_dbname[self.dac_name],
                self.user,
                self.password,
            )
        )
        logger.info("Connection established with {0}".format(self.dac_name.upper()))

    def get_client(self):
        if self.connection is None:
            self.set_client()
        return self.connection


    def execute_select_fetchone_query(self, query, params):
        pg_client = self.get_client()
        pg_cursor = pg_client.cursor()
        pg_cursor.execute(query, (params))

        fetch_result = pg_cursor.fetchone()

        pg_cursor.close()
        # pg_client.close()

        return fetch_result


    def execute_select_fetchall_query(self, query, params):
        pg_client = self.get_client()
        pg_cursor = pg_client.cursor()
        pg_cursor.execute(query, (params))

        fetch_result = pg_cursor.fetchall()

        pg_cursor.close()
        # pg_client.close()

        return fetch_result


    def execute_select_fetchall_query_as_dict(self, query, params):
        pg_client = self.get_client()
        pg_cursor = pg_client.cursor()
        pg_cursor.execute(query, (params))

        description = pg_cursor.description

        column_names = [col[0] for col in description]
        fetch_result = [dict(zip(column_names, row))
                        for row in pg_cursor.fetchall()]

        pg_cursor.close()
        # pg_client.close()

        return fetch_result


    def execute_insert_update_query(self, query, params):
        try:
            pg_client = self.get_client()
            pg_cursor = pg_client.cursor()

            pg_cursor.execute(query, (params))

            pg_client.commit()
            pg_cursor.close()
            # pg_client.close()

        except Exception:
            print(traceback.print_exc(file=sys.stdout))


    def ret_map_select_fetchall_query(self, query, params):
        pg_client = self.get_client()
        pg_cursor = pg_client.cursor()
        pg_cursor.execute(query, params)
        desc = pg_cursor.description

        column_names = [col[0] for col in desc]
        data = [dict(zip(column_names, row)) for row in pg_cursor.fetchall()]

        pg_cursor.close()
        # pg_client.close()

        return data


    def count_items_selected(self, query, params):
        pg_client = self.get_client()
        pg_cursor = pg_client.cursor()
        pg_cursor.executemany(query, (params))

        pg_cursor.close()
        # pg_client.close()

        return pg_cursor.rowcount


    def execute_many_insert_update_query(self, query, params):
        pg_client = self.get_client()
        pg_cursor = pg_client.cursor()
        pg_cursor.executemany(query, (params))

        pg_client.commit()
        pg_cursor.close()
        return pg_cursor.statusmessage


    def execute_batch_insert_update_query(self, query: str, iterator: Generator, size=1000) -> None:
        client = self.get_client()
        cursor = client.cursor()

        psycopg2.extras.execute_batch(cursor, query, iterator, page_size=size)


    def execute_values_for_batch_query(self, query: str, iterator: Generator, size=1000) -> None:
        pg_client = self.get_client()
        pg_cursor = pg_client.cursor()
        psycopg2.extras.execute_values(pg_cursor, query, iterator, page_size=size)
        pg_client.commit()
        pg_cursor.close()


