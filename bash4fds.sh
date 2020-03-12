test_exec() {
	exec 6<>/dev/null
	lsof -np $$
}

test_exec
lsof -np $$
