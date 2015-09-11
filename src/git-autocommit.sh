if [ -d "${1}" ]
then
  cd "${1}"
  git add .
  git commit -m "Automatic commit."
  git push
fi
