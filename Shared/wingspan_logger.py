import logging, logging.config
import sys

''' It sets the logging format'''

log_config = {
    'version': 1,
    'disable_existing_loggers': False,  # this fixes the problem
    'formatters': {
        'simple': {
            'format': '%(asctime)s -%(levelname)9s - %(name)20s - %(message)s'

        }
    },
    'handlers': {
        'default': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
    },
    'loggers': {
        '': {
            'handlers': ['default'],
            'level': 'INFO',
            'propagate': True
        }
    }
}

name = str(sys.modules['__main__'].__file__).split("/")[-1].split('.')[0]

level_dict = {
    "critical": logging.CRITICAL,
    "error": logging.ERROR,
    "warn": logging.WARNING,
    "info": logging.INFO,
    "debug": logging.DEBUG
}


def get_logger(level='info'):
    log_config['handlers']['default']['level'] = level_dict[level]
    log_config['loggers']['']['level'] = level_dict[level]
    logging.config.dictConfig(log_config)
    return logging.getLogger(name)
