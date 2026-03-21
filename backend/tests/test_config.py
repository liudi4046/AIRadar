import os
import pytest

from src.config import get_settings


@pytest.fixture(autouse=True)
def clear_settings_cache():
    yield
    get_settings.cache_clear()


def test_settings_loads_from_env(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "test-key")
    monkeypatch.setenv("SUPABASE_SERVICE_KEY", "test-service-key")
    monkeypatch.setenv("QWEN_API_KEY", "test-qwen-key")

    settings = get_settings()
    assert settings.supabase_url == "https://test.supabase.co"
    assert settings.supabase_key == "test-key"
    assert settings.qwen_api_key == "test-qwen-key"


def test_settings_has_defaults(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "test-key")
    monkeypatch.setenv("SUPABASE_SERVICE_KEY", "test-service-key")
    monkeypatch.setenv("QWEN_API_KEY", "test-qwen-key")

    settings = get_settings()
    assert settings.rsshub_base_url == "http://localhost:1200"
    assert settings.qwen_base_url == "https://dashscope.aliyuncs.com/compatible-mode/v1"
    assert settings.qwen_moderation_model == "qwen3.5-flash"
    assert settings.qwen_generation_model == "qwen3.5-plus"
