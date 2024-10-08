from typing import Any, Dict

import streamlit as st
from snowflake.snowpark.session import Session
from snowflake.snowpark.version import VERSION
import os


class SnowflakeConnection:
    """
    This class is used to establish a connection to Snowflake using OAuth.

    Attributes
    ----------
    connection_parameters : Dict[str, Any]
        A dictionary containing the connection parameters for Snowflake.
    session : snowflake.snowpark.Session
        A Snowflake session object.

    Methods
    -------
    get_session()
        Establishes and returns the Snowflake connection session using OAuth.

    """

    def __init__(self):
        self.connection_parameters = self._get_connection_parameters_from_env()
        self.session = None

    @staticmethod
    def _get_connection_parameters_from_env() -> Dict[str, Any]:
        connection_parameters = {
            "host": os.getenv("SNOWFLAKE_HOST"),
            "account": os.getenv("SNOWFLAKE_ACCOUNT"),
            "database": os.getenv("SNOWFLAKE_DATABASE"),
            "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
            "schema": os.getenv("SNOWFLAKE_SCHEMA"),
            "role": os.getenv("SNOWFLAKE_ROLE"),
            "authenticator": "oauth",
            "token": SnowflakeConnection._read_oauth_token(),
        }
        return connection_parameters

    @staticmethod
    def _read_oauth_token() -> str:
        """
        Reads the OAuth token from the specified file path.
        Returns:
            token: OAuth token as a string.
        """
        token_path = "/snowflake/session/token"
        with open(token_path, "r") as file:
            token = file.read().strip()
        return token

    def get_session(self):
        """
        Establishes and returns the Snowflake connection session using OAuth.
        Returns:
            session: Snowflake connection session.
        """
        if self.session is None:
            self.session = Session.builder.configs(self.connection_parameters).create()
            self.session.sql_simplifier_enabled = True
        return self.session
