from __future__ import annotations


def _coerce_string(value: object) -> object:
    if isinstance(value, dict) and value.get("_class") == "StringName":
        return value.get("_str")
    return value


def test_main_node_exists(game) -> None:
    assert game.node_exists("/root/Main") is True


def test_main_name_property(game) -> None:
    assert _coerce_string(game.get_property("/root/Main", "name")) == "Main"
