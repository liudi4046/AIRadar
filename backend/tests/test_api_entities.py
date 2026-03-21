import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def _mock_supabase_entities():
    mock = MagicMock()
    mock.table.return_value.select.return_value.execute.return_value = MagicMock(
        data=[
            {"id": "karpathy", "name": "Andrej Karpathy", "category": "core_leaders", "type": "person"},
            {"id": "openai", "name": "OpenAI", "category": "top_brands", "type": "org"},
        ]
    )
    mock.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
        data=[{"id": "karpathy", "name": "Andrej Karpathy", "category": "core_leaders", "type": "person"}]
    )
    return mock


def test_list_entities(client):
    with patch("src.api.entities.get_supabase", return_value=_mock_supabase_entities()):
        resp = client.get("/api/entities")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 2


def test_list_entities_by_category(client):
    with patch("src.api.entities.get_supabase", return_value=_mock_supabase_entities()):
        resp = client.get("/api/entities?category=core_leaders")
        assert resp.status_code == 200


def test_get_entity_by_id(client):
    with patch("src.api.entities.get_supabase", return_value=_mock_supabase_entities()):
        resp = client.get("/api/entities/karpathy")
        assert resp.status_code == 200
        data = resp.json()
        assert data["id"] == "karpathy"
