def test_create_and_list_items(client) -> None:
    response = client.post("/items", json={"name": "widget", "description": "a widget"})
    assert response.status_code == 201
    created = response.json()
    assert created["name"] == "widget"
    assert created["id"] is not None

    response = client.get("/items")
    assert response.status_code == 200
    items = response.json()
    assert len(items) == 1
    assert items[0]["name"] == "widget"


def test_create_item_without_description(client) -> None:
    response = client.post("/items", json={"name": "gadget"})
    assert response.status_code == 201
    assert response.json()["description"] is None
