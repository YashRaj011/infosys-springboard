import os
import json
import sys
# comment out pyfiglet if you do not have it
import pyfiglet
from wingspan.common import wingspan_logger

logger = wingspan_logger.get_logger()


class Config:
    config = None

    @classmethod
    def process_key(cls, key, config_dict, data_type):
        if data_type == 'str':
            if os.environ.get(key):
                return os.environ[key]

            return config_dict.get(key, '')
        elif data_type == 'int':
            if os.environ.get(key):
                return int(os.environ[key])

            if config_dict.get(key):
                return int(config_dict[key])

            return 0
        elif data_type == 'bool':
            if os.environ.get(key):
                return os.environ.get(key).lower() == "true"

            if config_dict.get(key):
                return config_dict.get(key)

    @classmethod
    def set_config(cls):
        if cls.config is None:
            # comment out below line if you don't have pyfiglet
            print(pyfiglet.figlet_format('W I N G S P A N'), flush=True)
            config_dict = {}
            # config file will not be passed in sys.argv.
            # Store it in root(or any location in your local system) and provide the path above.
            # Change your arg indices that was reading config.json accordingly.
            try:
                with open(r"config.json") as json_data:
                    config_dict = json.load(json_data)
            except Exception as e:
                logger.info("Config file not read. Error : " + str(e))

            config_dict['input_dir'] = cls.process_key('input_dir', config_dict, 'str')
            config_dict['output_dir'] = cls.process_key('output_dir', config_dict, 'str')
            config_dict['extract_dir'] = cls.process_key('extract_dir', config_dict, 'str')
            config_dict['download_dir'] = cls.process_key('download_dir', config_dict, 'str')
            config_dict['environment'] = cls.process_key('environment', config_dict, 'str')
            config_dict['encryption_secret'] = cls.process_key('encryption_secret', config_dict, 'str')
            
            config_dict['elasticsearch_url'] = cls.process_key('elasticsearch_url', config_dict, 'str')
            config_dict['elasticsearch_ssl_enabled'] = cls.process_key('elasticsearch_ssl_enabled', config_dict, 'bool')
            
            config_dict['cassandra_host'] = []
            config_dict['cassandra_host'].append(cls.process_key('cassandra_ip', config_dict, 'str'))
            config_dict['cassandra_port'] = cls.process_key('cassandra_port', config_dict, 'int')
            config_dict['cassandra_user'] = cls.process_key('cassandra_user', config_dict, 'str')
            config_dict['cassandra_password'] = cls.process_key('cassandra_password', config_dict, 'str')

            config_dict['postgres_general_host'] = cls.process_key('postgres_general_host', config_dict, 'str')
            config_dict['postgres_general_port'] = cls.process_key('postgres_general_port', config_dict, 'int')
            config_dict['postgres_general_user'] = cls.process_key('postgres_general_user', config_dict, 'str')
            config_dict['postgres_general_password'] = cls.process_key('postgres_general_password', config_dict, 'str')
            
            config_dict['postgres_schedulo_host'] = cls.process_key('postgres_schedulo_host', config_dict, 'str')
            config_dict['postgres_schedulo_port'] = cls.process_key('postgres_schedulo_port', config_dict, 'int')
            config_dict['postgres_schedulo_user'] = cls.process_key('postgres_schedulo_user', config_dict, 'str')
            config_dict['postgres_schedulo_password'] = cls.process_key('postgres_schedulo_password', config_dict,
                                                                        'str')
            config_dict['postgres_critical_host'] = cls.process_key('postgres_critical_host', config_dict, 'str')
            config_dict['postgres_critical_port'] = cls.process_key('postgres_critical_port', config_dict, 'int')
            config_dict['postgres_critical_user'] = cls.process_key('postgres_critical_user', config_dict, 'str')
            config_dict['postgres_critical_password'] = cls.process_key('postgres_critical_password', config_dict,
                                                                        'str')
            config_dict['postgres_pid_host'] = cls.process_key('postgres_pid_host', config_dict, 'str')
            config_dict['postgres_pid_port'] = cls.process_key('postgres_pid_port', config_dict, 'int')
            config_dict['postgres_pid_user'] = cls.process_key('postgres_pid_user', config_dict, 'str')
            config_dict['postgres_pid_password'] = cls.process_key('postgres_pid_password', config_dict, 'str')
            
            config_dict['neo4j_host'] = cls.process_key('neo4j_host', config_dict, 'str')
            config_dict['neo4j_user'] = cls.process_key('neo4j_user', config_dict, 'str')
            config_dict['neo4j_password'] = cls.process_key('neo4j_password', config_dict, 'str')
            
            config_dict['la_external_service'] = cls.process_key('la_external_service', config_dict, 'str')
            config_dict['la_client_id'] = cls.process_key('la_client_id', config_dict, 'str')
            config_dict['la_client_password'] = cls.process_key('la_client_password', config_dict, 'str')
            
            config_dict['s3_analytics'] = cls.process_key('s3_analytics', config_dict, 'str')
            
            config_dict['gateway_auth_url'] = cls.process_key('gateway_auth_url', config_dict, 'str')
            config_dict['gateway_url'] = cls.process_key('gateway_url', config_dict, 'str')
            
            config_dict['oracle_servers'] = cls.process_key('oracle_servers', config_dict, 'str')
            for oracle_server_name in config_dict['oracle_servers'].split(','):
                config_dict['oracle_' + oracle_server_name + '_user'] = cls.process_key(
                    'oracle_' + oracle_server_name + '_user', config_dict, 'str')
                config_dict['oracle_' + oracle_server_name + '_password'] = cls.process_key(
                    'oracle_' + oracle_server_name + '_password', config_dict, 'str')
                config_dict['oracle_' + oracle_server_name + '_host'] = cls.process_key(
                    'oracle_' + oracle_server_name + '_host', config_dict, 'str')

            cls.config = config_dict

    @classmethod
    def get_config(cls):
        cls.set_config()
        return cls.config
