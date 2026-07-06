from functools import lru_cache

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    supabase_url: str = Field(default="", alias="SUPABASE_URL")
    supabase_key: SecretStr | None = Field(default=None, alias="SUPABASE_KEY")
    openai_api_key: SecretStr | None = Field(default=None, alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4o", alias="OPENAI_MODEL")
    stripe_secret_key: SecretStr | None = Field(default=None, alias="STRIPE_SECRET_KEY")

    @property
    def has_supabase(self) -> bool:
        return bool(self.supabase_url and self.supabase_key)

    @property
    def has_openai(self) -> bool:
        return self.openai_api_key is not None

    @property
    def has_stripe(self) -> bool:
        return self.stripe_secret_key is not None


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
