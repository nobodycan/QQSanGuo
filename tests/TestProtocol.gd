extends Reference

var failures = []

func expect(condition, message):
	if not condition:
		failures.append(message)

func finish(tree, test_id):
	var result = {
		"ok": failures.empty(),
		"test_id": test_id,
		"failures": failures
	}
	print("TEST_RESULT " + to_json(result))
	tree.quit(0 if failures.empty() else 1)
