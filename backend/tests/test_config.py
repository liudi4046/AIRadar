import pytest

from src.config import get_settings


@pytest.fixture(autouse=True)
def clear_settings_cache():
    yield
    get_settings.cache_clear()


def _set_required_env(monkeypatch, **overrides):
    """Set all required env vars with sensible defaults, then apply overrides."""
    defaults = {
        "SUPABASE_URL": "https://test.supabase.co",
        "SUPABASE_KEY": "test-key",
        "SUPABASE_SERVICE_KEY": "test-service-key",
        "QWEN_API_KEY": "test-qwen-key",
        "TWITTER_API_KEY": "test-twitter-key",
    }
    defaults.update(overrides)
    for k, v in defaults.items():
        monkeypatch.setenv(k, v)


def test_settings_loads_from_env(monkeypatch):
    _set_required_env(monkeypatch)

    settings = get_settings()
    assert settings.supabase_url == "https://test.supabase.co"
    assert settings.supabase_key == "test-key"
    assert settings.qwen_api_key == "test-qwen-key"
    assert settings.twitter_api_key == "test-twitter-key"


def test_settings_has_defaults(monkeypatch):
    _set_required_env(monkeypatch)

    settings = get_settings()
    assert settings.twitter_api_base_url == "https://api.twitterapi.io"
    assert settings.qwen_base_url == "https://dashscope.aliyuncs.com/compatible-mode/v1"
    assert settings.qwen_moderation_model == "qwen3.5-flash"
    assert settings.qwen_generation_model == "qwen3.5-plus"
