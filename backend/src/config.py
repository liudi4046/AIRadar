from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    supabase_url: str
    supabase_key: str
    supabase_service_key: str
    qwen_api_key: str
    qwen_base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    qwen_moderation_model: str = "qwen3.5-flash"
    qwen_generation_model: str = "qwen3.5-plus"
    rsshub_base_url: str = "http://localhost:1200"
    scrape_interval_hours: int = 2

    model_config = {"env_file": ".env", "extra": "ignore"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
