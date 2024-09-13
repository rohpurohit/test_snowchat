from typing import Any, Dict
import streamlit as st
from snowflake.snowpark.session import Session


class SnowflakeConnection:
    """
    This class is used to establish a connection to Snowflake.

    Attributes
    ----------
    connection_parameters : Dict[str, Any]
        A dictionary containing the connection parameters for Snowflake.
    session : snowflake.snowpark.Session
        A Snowflake session object.

    Methods
    -------
    get_session()
        Establishes and returns the Snowflake connection session.
    read_oauth_token()
        Reads the OAuth token from the specified path.
    """

    def __init__(self):
        self.connection_parameters = self._get_connection_parameters_from_env()
        self.session = None

    @staticmethod
    def _get_connection_parameters_from_env() -> Dict[str, Any]:
        connection_parameters = {
            "host": st.secrets["HOST"],
            "account": st.secrets["ACCOUNT"],
            "user": st.secrets["USER_NAME"],
            "password": st.secrets["PASSWORD"],
            "database": st.secrets["DATABASE"],
            "warehouse": st.secrets["WAREHOUSE"],
            "role": st.secrets["ROLE"],
            "authenticator": st.secrets["AUTHENTICATOR"],
            "token": SnowflakeConnection.read_oauth_token(),  # Use the new method here
        }
        return connection_parameters

    @staticmethod
    def read_oauth_token() -> str:
        """
        Reads the OAuth token from the specified path.

        Returns:
            str: The OAuth token.
        """
        with open('/snowflake/session/token', 'r') as token_file:
            return token_file.read().strip()

    def get_session(self):
        """
        Establishes and returns the Snowflake connection session.
        Returns:
            session: Snowflake connection session.
        """
        if self.session is None:
            self.session = Session.builder.configs(self.connection_parameters).create()
            self.session.sql_simplifier_enabled = True
        return self.session
