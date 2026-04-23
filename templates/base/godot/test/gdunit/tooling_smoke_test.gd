extends GdUnitTestSuite


func test_toolbox_smoke() -> void:
	assert_int(2 + 2).is_equal(4)
