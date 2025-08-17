from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
from dotenv import load_dotenv
import os

# Load environment variables from .env file FIRST
load_dotenv()


class Settings(BaseSettings):
    API_PREFIX: str = "/api"
    DEBUG: bool = False

    # DATABASE_URL: str
    ALLOWED_ORIGINS: str = ""
    WEBSITE_URL: str

    @field_validator("ALLOWED_ORIGINS")
    def validate_allowed_origins(cls, v: str) -> list[str]:
        return [origin.strip() for origin in v.split(",")] if v else []

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
