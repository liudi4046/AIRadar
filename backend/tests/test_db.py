from unittest.mock import MagicMock, patch

import pytest


@pytest.fixture(autouse=True)
def clear_db_cache():
    yield
    try:
        from src.db import get_supabase

        get_supabase.cache_clear()
    except Exception:
        pass


def test_get_supabase_client():
    mock_settings = MagicMock()
    mock_settings.supabase_url = "https://test.supabase.co"
    mock_settings.supabase_service_key = "test-service-key"

    with (
        patch("src.db.get_settings", return_value=mock_settings),
        patch("src.db.create_client") as mock_create,
    ):
        mock_create.return_value = MagicMock()
        from src.db import get_supabase

        get_supabase.cache_clear()
        client = get_supabase()
        assert client is not None
        mock_create.assert_called_once_with(
            "https://test.supabase.co", "test-service-key"
        )
