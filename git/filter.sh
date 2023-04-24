git filter-branch --force --prune-empty --tree-filter 'test -d test/ && mv test/* . || echo nothing to do' -- --all
git filter-branch --force --prune-empty --tree-filter 'test -f test.c && mv test.c hello.c || echo nothing to do' -- --all
git filter-branch --force --prune-empty --tree-filter 'test -f test.f && mv test.f hello.f || echo nothing to do' -- --all
git filter-branch --force --prune-empty --tree-filter 'rm -f *.exe' -- --all
git filter-branch --force --prune-empty --tree-filter 'test -f readme && mv readme readme.md || echo nothing to do' -- --all