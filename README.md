# bash
A collection of bash scripts

## Git

### rewriting author history
Author names can be rewritten with the following code

from <https://help.github.com/articles/changing-author-info/>

````bash
./change.sh
git push --force --tags origin 'refs/heads/*'
````
