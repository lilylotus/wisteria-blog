
set branch=standard_master

git fetch origin
git checkout -b %branch% --track origin/%branch%
git checkout  --force %branch%
git pull origin
